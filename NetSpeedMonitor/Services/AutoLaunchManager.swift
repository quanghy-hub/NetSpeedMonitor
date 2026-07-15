import Foundation
import ServiceManagement
import os.log

final class AutoLaunchManager {
    
    init() {}
    
    var isEnabled: Bool {
        get {
            SMAppService.mainApp.status == .enabled
        }
        set {
            let service = SMAppService.mainApp
            do {
                if newValue {
                    if service.status == .notFound || service.status == .notRegistered {
                        try service.register()
                     }
                } else {
                    if service.status == .enabled {
                        try service.unregister()
                    }
                }
                logger.info("AutoLaunchManager update succeeded. Target state: \(newValue), Service status: \(service.status == .enabled)")
            } catch {
                logger.warning("AutoLaunchManager update failed: \(error.localizedDescription)")
            }
        }
    }
}
