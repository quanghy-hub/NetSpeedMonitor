import Accelerate
import AudioToolbox
import CoreAudio
import Foundation

protocol ProcessGainRendering: AnyObject {
    var audioObjectIDs: [UInt32] { get }
    var gain: Float { get set }
    func stop()
}

@available(macOS 14.4, *)
final class ProcessGainRenderer: ProcessGainRendering {
    let audioObjectIDs: [UInt32]
    
    var gain: Float {
        get { gainState.value }
        set { gainState.value = min(max(newValue, 0), maxGain) }
    }
    
    private final class GainState {
        var value: Float
        init(value: Float) {
            self.value = value
        }
    }
    
    private let gainState: GainState
    private let maxGain: Float
    private var tapID = AudioObjectID(0)
    private var aggregateID = AudioObjectID(0)
    private var ioProc: AudioDeviceIOProcID?
    
    init?(audioObjectIDs: [UInt32], gain: Float, maxGain: Float) {
        self.audioObjectIDs = audioObjectIDs.sorted()
        self.maxGain = maxGain
        self.gainState = GainState(value: min(max(gain, 0), maxGain))
        
        guard let outputUID = Self.defaultOutputDeviceUID() else {
            logger.warning("Process volume renderer failed: missing default output device")
            return nil
        }
        
        let tapDescription = CATapDescription(stereoMixdownOfProcesses: self.audioObjectIDs)
        tapDescription.muteBehavior = .mutedWhenTapped
        tapDescription.isPrivate = true
        
        let tapStatus = AudioHardwareCreateProcessTap(tapDescription, &tapID)
        guard tapStatus == noErr, tapID != 0 else {
            logger.warning("Process volume renderer failed: create tap status \(tapStatus)")
            return nil
        }
        
        guard createAggregateDevice(outputUID: outputUID, tapUID: tapDescription.uuid.uuidString) else {
            logger.warning("Process volume renderer failed: create aggregate device")
            AudioHardwareDestroyProcessTap(tapID)
            return nil
        }
        
        guard startRendering() else {
            logger.warning("Process volume renderer failed: start rendering")
            stop()
            return nil
        }
    }
    
    func stop() {
        if let ioProc {
            AudioDeviceStop(aggregateID, ioProc)
            AudioDeviceDestroyIOProcID(aggregateID, ioProc)
            self.ioProc = nil
        }
        
        if aggregateID != 0 {
            AudioHardwareDestroyAggregateDevice(aggregateID)
            aggregateID = 0
        }
        
        if tapID != 0 {
            AudioHardwareDestroyProcessTap(tapID)
            tapID = 0
        }
    }
    
    deinit {
        stop()
    }
    
    private func createAggregateDevice(outputUID: String, tapUID: String) -> Bool {
        let description: [String: Any] = [
            kAudioAggregateDeviceNameKey: "NetSpeedMonitor Mixer",
            kAudioAggregateDeviceUIDKey: UUID().uuidString,
            kAudioAggregateDeviceIsPrivateKey: true,
            kAudioAggregateDeviceMainSubDeviceKey: outputUID,
            kAudioAggregateDeviceSubDeviceListKey: [[kAudioSubDeviceUIDKey: outputUID]],
            kAudioAggregateDeviceTapListKey: [[
                kAudioSubTapUIDKey: tapUID,
                kAudioSubTapDriftCompensationKey: true
            ]],
            kAudioAggregateDeviceTapAutoStartKey: true
        ]
        
        let status = AudioHardwareCreateAggregateDevice(description as CFDictionary, &aggregateID)
        guard status == noErr, aggregateID != 0 else {
            logger.warning("Process volume renderer failed: aggregate status \(status)")
            return false
        }
        return true
    }
    
    private func startRendering() -> Bool {
        let state = gainState
        let created = AudioDeviceCreateIOProcIDWithBlock(&ioProc, aggregateID, nil) { _, input, _, output, _ in
            let inputBuffers = UnsafeMutableAudioBufferListPointer(UnsafeMutablePointer(mutating: input))
            let outputBuffers = UnsafeMutableAudioBufferListPointer(output)
            var gain = state.value
            var low: Float = -1
            var high: Float = 1
            let shouldClip = gain > 1
            
            for index in 0..<min(inputBuffers.count, outputBuffers.count) {
                guard let source = inputBuffers[index].mData?.assumingMemoryBound(to: Float.self),
                      let destination = outputBuffers[index].mData?.assumingMemoryBound(to: Float.self) else {
                    continue
                }
                
                let bytes = min(inputBuffers[index].mDataByteSize, outputBuffers[index].mDataByteSize)
                let samples = Int(bytes) / MemoryLayout<Float>.size
                vDSP_vsmul(source, 1, &gain, destination, 1, vDSP_Length(samples))
                
                if shouldClip {
                    vDSP_vclip(destination, 1, &low, &high, destination, 1, vDSP_Length(samples))
                }
            }
        }
        
        guard created == noErr, let ioProc else {
            logger.warning("Process volume renderer failed: IOProc status \(created)")
            return false
        }
        
        let startStatus = AudioDeviceStart(aggregateID, ioProc)
        guard startStatus == noErr else {
            logger.warning("Process volume renderer failed: start status \(startStatus)")
            return false
        }
        return true
    }
    
    private static func defaultOutputDeviceUID() -> String? {
        var outputDevice = AudioObjectID(0)
        guard read(AudioObjectID(kAudioObjectSystemObject), kAudioHardwarePropertyDefaultOutputDevice, &outputDevice),
              outputDevice != 0 else { return nil }
        
        var uid: CFString = "" as CFString
        guard read(outputDevice, kAudioDevicePropertyDeviceUID, &uid) else { return nil }
        return uid as String
    }
    
    private static func read<T>(_ objectID: AudioObjectID, _ selector: AudioObjectPropertySelector, _ value: inout T) -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var size = UInt32(MemoryLayout<T>.size)
        return withUnsafeMutablePointer(to: &value) { pointer in
            AudioObjectGetPropertyData(objectID, &address, 0, nil, &size, pointer) == noErr
        }
    }
}
