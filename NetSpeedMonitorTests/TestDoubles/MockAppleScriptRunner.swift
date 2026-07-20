import Foundation
@testable import NetSpeedMonitor

final class MockAppleScriptRunner: AppleScriptRunning {
    var stubbedResult: Result<String, Error> = .success("")
    private(set) var invokedScripts: [String] = []
    
    func run(script: String) throws -> String {
        invokedScripts.append(script)
        return try stubbedResult.get()
    }
}
