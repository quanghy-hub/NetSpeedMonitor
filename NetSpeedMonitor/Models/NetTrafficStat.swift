import Foundation

struct NetTrafficStat: Sendable {
    var deltaTimeSec: Double = 0.0
    var deltaInBytes: Int = 0
    var deltaOutBytes: Int = 0
    var inBytesPerSec: Double = 0.0
    var outBytesPerSec: Double = 0.0
    var lastInBytes: UInt32 = 0
    var lastOutBytes: UInt32 = 0
    var lastTime: Date?
    var hasPrevious = false
}
