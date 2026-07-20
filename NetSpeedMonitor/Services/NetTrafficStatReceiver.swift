import Foundation

/// Actor that reads network interface traffic statistics using POSIX getifaddrs() API.
/// Computes upload/download speed as bytes-per-second delta between successive polls.
/// Handles counter overflow (UInt32 wrap-around) gracefully.
/// Uses Swift value types (struct NetTrafficStat) for Sendable safety.
public actor NetTrafficStatReceiver {
    private var stats: [String: NetTrafficStat] = [:]
    
    public init() {}
    
    public func reset() {
        stats.removeAll()
    }
    
    /// Retrieves the upload and download speed for a specific interface.
    /// Performs interface name lookup and uses the delta computation from successive polls.
    public func getSpeed(for interfaceName: String) -> (upload: Double, download: Double)? {
        _ = updateStats()
        guard let stat = stats[interfaceName] else { return nil }
        return (upload: stat.outBytesPerSec, download: stat.inBytesPerSec)
    }
    
    private func updateStats() -> [String: NetTrafficStat]? {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else {
            return stats
        }
        defer { freeifaddrs(ifaddr) }
        
        let now = Date()
        var ptr = ifaddr
        
        while ptr != nil {
            defer { ptr = ptr?.pointee.ifa_next }
            guard let interface = ptr?.pointee else { continue }
            
            let name = String(cString: interface.ifa_name)
            let family = interface.ifa_addr.pointee.sa_family
            
            let flags = Int32(interface.ifa_flags)
            if (flags & IFF_LOOPBACK) != 0 {
                continue
            }
            
            if family == UInt8(AF_LINK) {
                if let data = interface.ifa_data {
                    let ifData = data.assumingMemoryBound(to: if_data.self).pointee
                    
                    var stat = stats[name] ?? NetTrafficStat()
                    
                    let current_ibytes = ifData.ifi_ibytes
                    let current_obytes = ifData.ifi_obytes
                    
                    if stat.hasPrevious, let lastTime = stat.lastTime, (flags & IFF_UP) != 0 {
                        let elapsed = now.timeIntervalSince(lastTime)
                        stat.deltaTimeSec = elapsed
                        
                        // Handles counter overflow (UInt32 wrap-around) gracefully
                        if current_ibytes < stat.lastInBytes {
                            stat.deltaInBytes = Int(Int64(current_ibytes) + Int64(UInt32.max) - Int64(stat.lastInBytes))
                        } else {
                            stat.deltaInBytes = Int(current_ibytes - stat.lastInBytes)
                        }
                        
                        // Handles counter overflow (UInt32 wrap-around) gracefully
                        if current_obytes < stat.lastOutBytes {
                            stat.deltaOutBytes = Int(Int64(current_obytes) + Int64(UInt32.max) - Int64(stat.lastOutBytes))
                        } else {
                            stat.deltaOutBytes = Int(current_obytes - stat.lastOutBytes)
                        }
                        
                        let speedIn = Double(stat.deltaInBytes) / (elapsed + 1e-3)
                        let speedOut = Double(stat.deltaOutBytes) / (elapsed + 1e-3)
                        
                        if elapsed > 60.0 {
                            stat.inBytesPerSec = 0.0
                            stat.outBytesPerSec = 0.0
                        } else {
                            stat.inBytesPerSec = speedIn
                            stat.outBytesPerSec = speedOut
                        }
                    } else {
                        stat.deltaTimeSec = 0.0
                        stat.deltaInBytes = 0
                        stat.deltaOutBytes = 0
                        stat.inBytesPerSec = 0.0
                        stat.outBytesPerSec = 0.0
                        stat.hasPrevious = true
                    }
                    
                    stat.lastInBytes = current_ibytes
                    stat.lastOutBytes = current_obytes
                    stat.lastTime = now
                    
                    stats[name] = stat
                }
            }
        }
        
        return stats
    }
}


/// Provides network interface traffic statistics.
protocol NetworkTrafficProviding: Sendable {
    func getSpeed(for interfaceName: String) async -> (upload: Double, download: Double)?
    func reset() async
}

extension NetTrafficStatReceiver: NetworkTrafficProviding {}
