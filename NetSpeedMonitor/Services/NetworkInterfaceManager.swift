import Foundation
import SystemConfiguration

final class NetworkInterfaceManager {
    
    private var primaryInterface: String?
    private var lastCheckedAt = Date.distantPast
    
    init() {}
    
    func getPrimaryInterface() -> String? {
        let now = Date()
        if primaryInterface == nil || now.timeIntervalSince(lastCheckedAt) >= 10.0 {
            primaryInterface = findPrimaryInterface()
            lastCheckedAt = now
        }
        return primaryInterface
    }
    
    private func findPrimaryInterface() -> String? {
        let storeRef = SCDynamicStoreCreate(nil, "FindCurrentInterfaceIpMac" as CFString, nil, nil)
        let global = SCDynamicStoreCopyValue(storeRef, "State:/Network/Global/IPv4" as CFString)
        return global?.value(forKey: "PrimaryInterface") as? String
    }
}
