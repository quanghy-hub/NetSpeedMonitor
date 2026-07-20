import Foundation
import Testing
@testable import NetSpeedMonitor

@Suite("MusicReplacement Tests")
struct MusicReplacementTests {
    
    @Test("Parse empty string returns nil")
    func parseEmpty() throws {
        let result = try MusicReplacement.parse("")
        #expect(result == nil)
    }
    
    @Test("Parse whitespace string returns nil")
    func parseWhitespace() throws {
        let result = try MusicReplacement.parse("   \n ")
        #expect(result == nil)
    }
    
    @Test("Parse valid HTTPS URL")
    func parseValidHTTPS() throws {
        let result = try MusicReplacement.parse("https://example.com")
        #expect(result?.kind == .website)
        #expect(result?.url.absoluteString == "https://example.com")
    }
    
    @Test("Parse valid HTTP URL")
    func parseValidHTTP() throws {
        let result = try MusicReplacement.parse("http://example.com")
        #expect(result?.kind == .website)
        #expect(result?.url.absoluteString == "http://example.com")
    }
    
    @Test("Parse valid App path")
    func parseValidApp() throws {
        let result = try MusicReplacement.parse("/System/Applications/Calculator.app")
        #expect(result?.kind == .application)
        #expect(result?.url.path == "/System/Applications/Calculator.app")
    }
    
    @Test("Parse non-existent App throws")
    func parseNonExistentApp() {
        #expect(throws: MusicReplacement.ValidationError.applicationDoesNotExist) {
            _ = try MusicReplacement.parse("/System/Applications/FakeAppThatDoesNotExist.app")
        }
    }
    
    @Test("Parse non-App path throws")
    func parseNonAppPath() {
        #expect(throws: MusicReplacement.ValidationError.applicationRequired) {
            _ = try MusicReplacement.parse("/usr/bin")
        }
    }
    
    @Test("Parse blocked App throws")
    func parseBlockedApp() {
        #expect(throws: MusicReplacement.ValidationError.blockedApplication) {
            _ = try MusicReplacement.parse("/System/Applications/Music.app")
        }
    }
    
    @Test("Parse invalid value throws")
    func parseInvalidValue() {
        #expect(throws: MusicReplacement.ValidationError.unsupportedValue) {
            _ = try MusicReplacement.parse("not a path")
        }
    }
    
    @Test("Stored value for website")
    func storedValueWebsite() throws {
        let replacement = try #require(MusicReplacement.parse("https://apple.com"))
        #expect(replacement.storedValue == "https://apple.com")
    }
    
    @Test("Stored value for application")
    func storedValueApp() throws {
        let replacement = try #require(MusicReplacement.parse("/System/Applications/Calculator.app"))
        #expect(replacement.storedValue == "/System/Applications/Calculator.app")
    }
    
    @Test("Equatable check")
    func equatable() throws {
        let app1 = try #require(MusicReplacement.parse("/System/Applications/Calculator.app"))
        let app2 = try #require(MusicReplacement.parse("/System/Applications/Calculator.app"))
        let web1 = try #require(MusicReplacement.parse("https://example.com"))
        
        #expect(app1 == app2)
        #expect(app1 != web1)
    }
}
