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
