import SwiftUI

struct AudioMixerSectionView: View {
    @EnvironmentObject var menuBarState: MenuBarState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center) {
                Text("VOLUME MIXER")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .tracking(1.5)
                
                Spacer()
                
                Button {
                    menuBarState.refreshAudioMixer()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11, weight: .semibold))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .disabled(menuBarState.isAudioMixerRefreshing)
            }
            
            if menuBarState.audioMixerItems.isEmpty {
                Text(menuBarState.audioMixerStatus)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 12) {
                    ForEach(menuBarState.audioMixerItems) { item in
                        AudioMixerRow(item: item)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(nsColor: .controlBackgroundColor).opacity(0.72))
                )
            }
        }
    }
}

private struct AudioMixerRow: View {
    @EnvironmentObject var menuBarState: MenuBarState
    let item: AudioMixerItem
    
    var body: some View {
        HStack(spacing: 8) {
            AudioMixerAppIcon(item: item)
            
            Text(item.displayTitle)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .frame(width: 80, alignment: .leading)
            
            VolumeTrack(
                value: Binding(
                    get: { item.volume },
                    set: { menuBarState.setAudioVolume($0, for: item.id) }
                ),
                range: 0...item.maxVolume
            )
            .frame(height: 18)
            .disabled(!item.canSetVolume)
            
            Text("\(Int(item.volume * 100))%")
                .font(.system(size: 13, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 42, alignment: .trailing)
            
            Button {
                menuBarState.setAudioVolume(1, for: item.id, commitImmediately: true)
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.secondary.opacity(item.isDefaultVolume ? 0.35 : 1))
                    .frame(width: 16, height: 18)
            }
            .buttonStyle(.plain)
            .disabled(item.isDefaultVolume || !item.canSetVolume)
            .help("Reset to 100%")
            
            Image(systemName: item.volume <= 0.001 ? "speaker.slash.fill" : "speaker.wave.2.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 16)
        }
        .frame(height: 28)
    }
}

private struct VolumeTrack: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    
    var body: some View {
        GeometryReader { proxy in
            let width = max(proxy.size.width, 1)
            let progress = normalizedProgress
            let knobSize = 18.0
            
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.secondary.opacity(0.18))
                    .frame(height: 5)
                
                Capsule()
                    .fill(Color.blue)
                    .frame(width: max(knobSize / 2, width * progress), height: 5)
                
                Circle()
                    .fill(Color(nsColor: .systemGray))
                    .frame(width: knobSize, height: knobSize)
                    .shadow(color: .black.opacity(0.18), radius: 1, x: 0, y: 1)
                    .offset(x: min(max(0, width * progress - knobSize / 2), width - knobSize))
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        setValue(locationX: gesture.location.x, width: width)
                    }
            )
        }
    }
    
    private var normalizedProgress: Double {
        let span = range.upperBound - range.lowerBound
        guard span > 0 else { return 0 }
        return min(max((value - range.lowerBound) / span, 0), 1)
    }
    
    private func setValue(locationX: CGFloat, width: CGFloat) {
        let progress = min(max(Double(locationX / width), 0), 1)
        value = range.lowerBound + (range.upperBound - range.lowerBound) * progress
    }
}

private struct AudioMixerAppIcon: View {
    let item: AudioMixerItem
    
    var body: some View {
        Group {
            if let image = icon {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "app.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 28, height: 28)
        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
    }
    
    private var icon: NSImage? {
        if let processID = item.processID,
           let appIcon = NSRunningApplication(processIdentifier: processID)?.icon {
            return appIcon
        }
        
        if let bundleIdentifier = item.bundleIdentifier,
           let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) {
            return NSWorkspace.shared.icon(forFile: appURL.path)
        }
        
        return nil
    }
}

private extension AudioMixerItem {
    var isDefaultVolume: Bool {
        abs(volume - 1) < 0.005
    }
    
    var displayTitle: String {
        if kind == .browserTab, let bundleIdentifier {
            return bundleIdentifier == "com.apple.Safari" ? "Safari" : "Chrome"
        }
        return title
    }
}
