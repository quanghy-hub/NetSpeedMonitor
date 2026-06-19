import Foundation

final class ProcessVolumeEngine {
    static let shared = ProcessVolumeEngine()
    static let maxVolume = 2.0
    
    private var engines: [String: ProcessGainRendering] = [:]
    private var buildTokens: [String: UUID] = [:]
    private var pendingRequests: [String: VolumeRequest] = [:]
    private let queue = DispatchQueue(label: "com.elegracer.NetSpeedMonitor.process-volume", qos: .userInitiated)
    
    private init() {}
    
    func apply(volume: Double, targetID: String, audioObjectIDs: [UInt32]) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.apply(volume: volume, targetID: targetID, audioObjectIDs: audioObjectIDs)
            }
            return
        }
        
        let clamped = Self.clamp(volume)
        if isPassthrough(clamped) || audioObjectIDs.isEmpty {
            pendingRequests.removeValue(forKey: targetID)
            stop(targetID: targetID)
            return
        }
        
        if let engine = engines[targetID], engine.audioObjectIDs == audioObjectIDs {
            engine.gain = Float(clamped)
            return
        }
        
        if buildTokens[targetID] != nil {
            pendingRequests[targetID] = VolumeRequest(volume: clamped, audioObjectIDs: audioObjectIDs)
            return
        }
        
        stop(targetID: targetID)
        startRendererBuild(volume: clamped, targetID: targetID, audioObjectIDs: audioObjectIDs)
    }
    
    private func startRendererBuild(volume: Double, targetID: String, audioObjectIDs: [UInt32]) {
        let token = UUID()
        buildTokens[targetID] = token
        queue.async { [weak self] in
            guard let renderer = ProcessGainRenderer(
                audioObjectIDs: audioObjectIDs,
                gain: Float(volume),
                maxGain: Float(Self.maxVolume)
            ) else {
                logger.warning("Process volume renderer could not start for \(targetID)")
                DispatchQueue.main.async {
                    if self?.buildTokens[targetID] == token {
                        self?.buildTokens.removeValue(forKey: targetID)
                    }
                }
                return
            }
            
            DispatchQueue.main.async {
                guard let self else {
                    renderer.stop()
                    return
                }
                
                guard self.buildTokens[targetID] == token else {
                    self.stopOffMain(renderer)
                    return
                }
                
                self.buildTokens.removeValue(forKey: targetID)
                let pending = self.pendingRequests.removeValue(forKey: targetID)
                if let pending {
                    guard pending.audioObjectIDs == renderer.audioObjectIDs,
                          !self.isPassthrough(pending.volume) else {
                        self.stopOffMain(renderer)
                        self.apply(volume: pending.volume, targetID: targetID, audioObjectIDs: pending.audioObjectIDs)
                        return
                    }
                    renderer.gain = Float(pending.volume)
                } else {
                    renderer.gain = Float(volume)
                }
                self.engines[targetID] = renderer
            }
        }
    }
    
    func reconcile(activeTargets: [String: [UInt32]]) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.reconcile(activeTargets: activeTargets)
            }
            return
        }
        
        for (targetID, engine) in Array(engines) where activeTargets[targetID] != engine.audioObjectIDs {
            engines.removeValue(forKey: targetID)
            buildTokens.removeValue(forKey: targetID)
            pendingRequests.removeValue(forKey: targetID)
            stopOffMain(engine)
        }
    }
    
    func stopAll() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.stopAll()
            }
            return
        }
        
        for engine in engines.values {
            stopOffMain(engine)
        }
        engines.removeAll()
    }
    
    private func stop(targetID: String) {
        buildTokens.removeValue(forKey: targetID)
        pendingRequests.removeValue(forKey: targetID)
        if let engine = engines.removeValue(forKey: targetID) {
            stopOffMain(engine)
        }
    }
    
    private func stopOffMain(_ engine: ProcessGainRendering) {
        queue.async {
            engine.stop()
        }
    }
    
    private func isPassthrough(_ volume: Double) -> Bool {
        abs(volume - 1) < 0.005
    }
    
    static func clamp(_ volume: Double) -> Double {
        guard volume.isFinite else { return 1 }
        return min(max(volume, 0), maxVolume)
    }
}

private struct VolumeRequest {
    let volume: Double
    let audioObjectIDs: [UInt32]
}
