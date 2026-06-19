import AppKit
import Darwin

enum ResponsibleAudioProcessResolver {
    private static let resolveOwner: (@convention(c) (pid_t) -> pid_t)? = {
        guard let symbol = dlsym(
            UnsafeMutableRawPointer(bitPattern: -2),
            "responsibility_get_pid_responsible_for_pid"
        ) else { return nil }
        return unsafeBitCast(symbol, to: (@convention(c) (pid_t) -> pid_t).self)
    }()
    
    static func ownerPID(for pid: pid_t) -> pid_t {
        guard let resolveOwner else { return pid }
        let owner = resolveOwner(pid)
        return owner > 0 ? owner : pid
    }
    
    static func displayName(for pid: pid_t, fallback: String) -> String {
        if let app = NSRunningApplication(processIdentifier: pid),
           let name = app.localizedName,
           !name.isEmpty {
            return name
        }
        
        var buffer = [CChar](repeating: 0, count: 256)
        if proc_name(pid, &buffer, UInt32(buffer.count)) > 0 {
            let name = String(cString: buffer)
            if !name.isEmpty { return name }
        }
        
        return fallback
    }
}
