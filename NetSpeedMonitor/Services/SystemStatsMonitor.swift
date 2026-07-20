import Foundation
import Darwin
import IOKit.ps

/// Actor providing CPU, RAM, and battery statistics using Darwin/Mach kernel APIs.
/// CPU usage is computed as a delta between successive polling calls.
/// Properly deallocates Mach kernel pointers (processor_info_array_t) to prevent memory leaks.
actor SystemStatsMonitor {
    
    // MARK: - CPU Tracking State
    
    private var previousCPUInfo: processor_info_array_t?
    private var previousCPUInfoCount: mach_msg_type_number_t = 0
    
    // MARK: - RAM
    
    private lazy var totalRAM: UInt64 = {
        var size: size_t = MemoryLayout<UInt64>.size
        var memsize: UInt64 = 0
        sysctlbyname("hw.memsize", &memsize, &size, nil, 0)
        return memsize
    }()
    
    // MARK: - CPU Usage (0.0 - 1.0)
    
    /// Computes CPU usage as a delta between successive polling calls.
    /// CPU ticks are compared between current state and previous state to calculate delta ticks.
    func getCPUUsage() -> Double {
        var numCPUs: natural_t = 0
        var cpuInfo: processor_info_array_t?
        var cpuInfoCount: mach_msg_type_number_t = 0
        
        let result = host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &numCPUs,
            &cpuInfo,
            &cpuInfoCount
        )
        
        guard result == KERN_SUCCESS, let cpuInfo = cpuInfo else {
            return 0.0
        }
        
        var totalUsage: Double = 0.0
        var totalTicks: Double = 0.0
        
        for i in 0..<Int(numCPUs) {
            let offset = Int(CPU_STATE_MAX) * i
            
            let userTicks   = Double(cpuInfo[offset + Int(CPU_STATE_USER)])
            let systemTicks = Double(cpuInfo[offset + Int(CPU_STATE_SYSTEM)])
            let idleTicks   = Double(cpuInfo[offset + Int(CPU_STATE_IDLE)])
            let niceTicks   = Double(cpuInfo[offset + Int(CPU_STATE_NICE)])
            
            if let previousCPUInfo = previousCPUInfo {
                let prevUser   = Double(previousCPUInfo[offset + Int(CPU_STATE_USER)])
                let prevSystem = Double(previousCPUInfo[offset + Int(CPU_STATE_SYSTEM)])
                let prevIdle   = Double(previousCPUInfo[offset + Int(CPU_STATE_IDLE)])
                let prevNice   = Double(previousCPUInfo[offset + Int(CPU_STATE_NICE)])
                
                let deltaUser   = userTicks - prevUser
                let deltaSystem = systemTicks - prevSystem
                let deltaIdle   = idleTicks - prevIdle
                let deltaNice   = niceTicks - prevNice
                
                let totalDelta = deltaUser + deltaSystem + deltaIdle + deltaNice
                if totalDelta > 0 {
                    totalUsage += (deltaUser + deltaSystem + deltaNice)
                    totalTicks += totalDelta
                }
            }
        }
        
        // Deallocate previous info
        if let previousCPUInfo = previousCPUInfo {
            let prevSize = vm_size_t(previousCPUInfoCount) * vm_size_t(MemoryLayout<integer_t>.stride)
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: previousCPUInfo), prevSize)
        }
        
        previousCPUInfo = cpuInfo
        previousCPUInfoCount = cpuInfoCount
        
        guard totalTicks > 0 else { return 0.0 }
        return min(max(totalUsage / totalTicks, 0.0), 1.0)
    }
    
    // MARK: - RAM Usage (0.0 - 1.0)
    
    /// Computes RAM usage by calculating active + wired + compressed memory
    /// and comparing it against the total physical memory.
    func getRAMUsage() -> Double {
        var count = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size
        )
        var vmStats = vm_statistics64_data_t()
        
        let result = withUnsafeMutablePointer(to: &vmStats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        
        guard result == KERN_SUCCESS else { return 0.0 }
        
        var pageSize: vm_size_t = 0
        host_page_size(mach_host_self(), &pageSize)
        let pageSizeUInt64 = UInt64(pageSize)
        
        let activeMemory   = UInt64(vmStats.active_count) * pageSizeUInt64
        let wiredMemory    = UInt64(vmStats.wire_count) * pageSizeUInt64
        let compressedMemory = UInt64(vmStats.compressor_page_count) * pageSizeUInt64
        
        let usedMemory = activeMemory + wiredMemory + compressedMemory
        
        guard totalRAM > 0 else { return 0.0 }
        return min(max(Double(usedMemory) / Double(totalRAM), 0.0), 1.0)
    }
    
    // MARK: - Battery Info
    
    /// Retrieves battery information using IOKit power source API.
    func getBatteryInfo() -> BatteryInfo {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef] else {
            return BatteryInfo(level: 1.0, isCharging: false, isPluggedIn: false)
        }
        
        for source in sources {
            if let description = IOPSGetPowerSourceDescription(snapshot, source).takeUnretainedValue() as? [String: Any] {
                let currentCapacity = description[kIOPSCurrentCapacityKey as String] as? Int ?? 0
                let maxCapacity = description[kIOPSMaxCapacityKey as String] as? Int ?? 100
                let isCharging = description[kIOPSIsChargingKey as String] as? Bool ?? false
                let powerSource = description[kIOPSPowerSourceStateKey as String] as? String ?? ""
                let isPluggedIn = (powerSource == kIOPSACPowerValue as String)
                
                let level = maxCapacity > 0 ? Double(currentCapacity) / Double(maxCapacity) : 0.0
                return BatteryInfo(
                    level: min(max(level, 0.0), 1.0),
                    isCharging: isCharging,
                    isPluggedIn: isPluggedIn
                )
            }
        }
        
        return BatteryInfo(level: 1.0, isCharging: false, isPluggedIn: false)
    }
    
    deinit {
        if let previousCPUInfo = previousCPUInfo {
            let prevSize = vm_size_t(previousCPUInfoCount) * vm_size_t(MemoryLayout<integer_t>.stride)
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: previousCPUInfo), prevSize)
        }
    }
}


/// Provides system resource statistics (CPU, RAM, battery).
protocol SystemStatsProviding: Sendable {
    func getCPUUsage() async -> Double
    func getRAMUsage() async -> Double
    func getBatteryInfo() async -> BatteryInfo
}

extension SystemStatsMonitor: SystemStatsProviding {}
