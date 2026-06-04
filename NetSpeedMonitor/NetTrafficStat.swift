import Foundation

public class NetTrafficStat: NSObject {
    @objc public var delta_ts_sec: NSNumber = 0.0
    @objc public var delta_ibytes: Int = 0
    @objc public var delta_obytes: Int = 0
    @objc public var ibytes_per_sec: NSNumber = 0.0
    @objc public var obytes_per_sec: NSNumber = 0.0
    
    var last_ifi_ibytes: UInt32 = 0
    var last_ifi_obytes: UInt32 = 0
    var last_time: Date?
    var has_previous = false
}

public class NetTrafficStatReceiver: NSObject {
    @objc public var netTrafficStatMap = NSMutableDictionary()
    
    @objc public func reset() {
        netTrafficStatMap.removeAllObjects()
    }
    
    @objc public func getNetTrafficStatMap() -> NSMutableDictionary? {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else {
            return netTrafficStatMap
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
                    
                    let stat: NetTrafficStat
                    if let existing = netTrafficStatMap[name] as? NetTrafficStat {
                        stat = existing
                    } else {
                        stat = NetTrafficStat()
                        netTrafficStatMap[name] = stat
                    }
                    
                    let current_ibytes = ifData.ifi_ibytes
                    let current_obytes = ifData.ifi_obytes
                    
                    if stat.has_previous, let lastTime = stat.last_time, (flags & IFF_UP) != 0 {
                        let elapsed = now.timeIntervalSince(lastTime)
                        stat.delta_ts_sec = NSNumber(value: elapsed)
                        
                        if current_ibytes < stat.last_ifi_ibytes {
                            stat.delta_ibytes = Int(Int64(current_ibytes) + Int64(UInt32.max) - Int64(stat.last_ifi_ibytes))
                        } else {
                            stat.delta_ibytes = Int(current_ibytes - stat.last_ifi_ibytes)
                        }
                        
                        if current_obytes < stat.last_ifi_obytes {
                            stat.delta_obytes = Int(Int64(current_obytes) + Int64(UInt32.max) - Int64(stat.last_ifi_obytes))
                        } else {
                            stat.delta_obytes = Int(current_obytes - stat.last_ifi_obytes)
                        }
                        
                        let speedIn = Double(stat.delta_ibytes) / (elapsed + 1e-3)
                        let speedOut = Double(stat.delta_obytes) / (elapsed + 1e-3)
                        
                        if elapsed > 60.0 {
                            stat.ibytes_per_sec = 0.0
                            stat.obytes_per_sec = 0.0
                        } else {
                            stat.ibytes_per_sec = NSNumber(value: speedIn)
                            stat.obytes_per_sec = NSNumber(value: speedOut)
                        }
                    } else {
                        stat.delta_ts_sec = 0.0
                        stat.delta_ibytes = 0
                        stat.delta_obytes = 0
                        stat.ibytes_per_sec = 0.0
                        stat.obytes_per_sec = 0.0
                        stat.has_previous = true
                    }
                    
                    stat.last_ifi_ibytes = current_ibytes
                    stat.last_ifi_obytes = current_obytes
                    stat.last_time = now
                }
            }
        }
        
        return netTrafficStatMap
    }
}
