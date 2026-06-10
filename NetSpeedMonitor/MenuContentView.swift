import SwiftUI
import os.log

public var logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.elegracer.NetSpeedMonitor", category: "elegracer")

struct MenuContentView: View {
    @EnvironmentObject var menuBarState: MenuBarState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            // MARK: - System Monitor
            SectionHeader(title: "System Monitor")
            
            // CPU Row
            HStack(spacing: 8) {
                Toggle("CPU", isOn: $menuBarState.showCPUBar)
                    .toggleStyle(.checkbox)
                    .frame(width: 52, alignment: .leading)
                
                UsageBarPreview(
                    usage: menuBarState.cpuUsage,
                    color: Color(hex: menuBarState.cpuBarColorHex)
                )
                
                PresetColorPicker(selectedHex: $menuBarState.cpuBarColorHex)
            }
            
            // RAM Row
            HStack(spacing: 8) {
                Toggle("RAM", isOn: $menuBarState.showRAMBar)
                    .toggleStyle(.checkbox)
                    .frame(width: 52, alignment: .leading)
                
                UsageBarPreview(
                    usage: menuBarState.ramUsage,
                    color: Color(hex: menuBarState.ramBarColorHex)
                )
                
                PresetColorPicker(selectedHex: $menuBarState.ramBarColorHex)
            }
            
            // Battery Row
            HStack(spacing: 8) {
                Toggle("BAT", isOn: $menuBarState.showBatteryBar)
                    .toggleStyle(.checkbox)
                    .frame(width: 52, alignment: .leading)
                
                UsageBarPreview(
                    usage: menuBarState.batteryLevel,
                    color: Color(hex: menuBarState.batteryBarColorHex),
                    suffix: menuBarState.batteryIsCharging ? " ⚡" : ""
                )
                
                PresetColorPicker(selectedHex: $menuBarState.batteryBarColorHex)
            }
            
            Divider()
            
            // MARK: - Update Interval
            SectionHeader(title: "Update Interval")
            
            HStack(spacing: 4) {
                ForEach(NetSpeedUpdateInterval.allCases) { interval in
                    Toggle(
                        interval.displayName,
                        isOn: Binding(
                            get: { menuBarState.netSpeedUpdateInterval == interval },
                            set: { if $0 { menuBarState.netSpeedUpdateInterval = interval } }
                        )
                    )
                    .toggleStyle(.button)
                    .controlSize(.small)
                }
            }
            
            Divider()
            
            // MARK: - Speed Unit
            SectionHeader(title: "Speed Unit")
            
            HStack(spacing: 4) {
                ForEach(SpeedUnit.allCases) { unit in
                    Toggle(
                        unit.rawValue,
                        isOn: Binding(
                            get: { menuBarState.speedUnit == unit },
                            set: { if $0 { menuBarState.speedUnit = unit } }
                        )
                    )
                    .toggleStyle(.button)
                    .controlSize(.small)
                }
            }
            
            Divider()
            
            // MARK: - Actions
            HStack(spacing: 8) {
                Toggle("Start at Login", isOn: $menuBarState.autoLaunchEnabled)
                    .toggleStyle(.checkbox)
                    .onChange(of: menuBarState.autoLaunchEnabled, initial: false) { oldState, newState in
                        logger.info("Toggle::StartAtLogin: oldState：\(oldState), newState: \(newState)")
                    }
                
                Spacer()
                
                Button("Activity Monitor") {
                    onClickOpenActivityMonitor()
                }
                .controlSize(.small)
                
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .controlSize(.small)
            }
        }
        .padding(14)
        .frame(width: 320)
    }
    
    private func onClickOpenActivityMonitor() {
        let bundleID = "com.apple.ActivityMonitor"
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            let config = NSWorkspace.OpenConfiguration()
            config.activates = true
            
            NSWorkspace.shared.openApplication(at: appURL,
                                               configuration: config,
                                               completionHandler: { app, error in
                if let error = error {
                    logger.warning("Open Activity Monitor failed: \(error.localizedDescription)")
                } else {
                    logger.info("Open Activity Monitor succeeded.")
                }
            })
        } else {
            logger.warning("Cannot find Activity Monitor.")
        }
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
    }
}

// MARK: - Preset Color Picker

struct PresetColorPicker: View {
    @Binding var selectedHex: String
    
    private let presetColors: [(name: String, hex: String)] = [
        ("Green", "#34C759"),
        ("Blue", "#007AFF"),
        ("Cyan", "#5AC8FA"),
        ("Purple", "#AF52DE"),
        ("Pink", "#FF2D55"),
        ("Orange", "#FF9500"),
        ("Yellow", "#FFCC00"),
        ("White", "#FFFFFF"),
    ]
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(presetColors, id: \.hex) { preset in
                Button(action: {
                    selectedHex = preset.hex
                }) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(hex: preset.hex))
                        .frame(width: 12, height: 12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
                                .stroke(
                                    selectedHex == preset.hex ? Color.primary : Color.clear,
                                    lineWidth: 1.5
                                )
                        )
                }
                .buttonStyle(.plain)
                .help(preset.name)
            }
        }
    }
}

// MARK: - Usage Bar Preview

struct UsageBarPreview: View {
    let usage: Double
    let color: Color
    var suffix: String = ""
    
    var body: some View {
        HStack(spacing: 4) {
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.primary.opacity(0.1))
                    .frame(height: 10)
                
                GeometryReader { geometry in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            usage > 0.9 ? Color.red :
                            usage > 0.75 ? Color.orange :
                            color
                        )
                        .frame(
                            width: geometry.size.width * min(max(usage, 0), 1),
                            height: 10
                        )
                }
                .frame(height: 10)
            }
            .frame(minWidth: 60)
            
            Text("\(Int(usage * 100))%\(suffix)")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .frame(width: suffix.isEmpty ? 30 : 46, alignment: .trailing)
        }
    }
}
