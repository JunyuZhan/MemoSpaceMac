import Foundation
import Testing
@testable import MemoSpaceKit

@Suite struct SMBErrorTests {
    @Test func mapsPOSIXCodes() {
        #expect(SMBError.map(POSIXError(.EACCES)) == .permissionDenied)
        #expect(SMBError.map(POSIXError(.ENOENT), path: "/a") == .notFound("/a"))
        #expect(SMBError.map(POSIXError(.EEXIST), path: "/b") == .nameConflict("/b"))
        #expect(SMBError.map(POSIXError(.ENOSPC)) == .noSpace)
        #expect(SMBError.map(POSIXError(.ETIMEDOUT)) == .timeout)
        #expect(SMBError.map(POSIXError(.ECONNRESET)) == .connectionLost)
        #expect(SMBError.map(POSIXError(.ECANCELED)) == .cancelled)
        #expect(SMBError.map(POSIXError(.ENAMETOOLONG), path: "x") == .invalidName("x"))
    }

    @Test func mapsNSErrorInPOSIXDomain() {
        let error = NSError(domain: NSPOSIXErrorDomain, code: Int(EACCES))
        #expect(SMBError.map(error) == .permissionDenied)
    }

    @Test func mapsPathErrors() {
        #expect(SMBError.map(RemotePathError.traversal("/a/../b")) == .invalidName("/a/../b"))
        #expect(SMBError.map(RemotePathError.invalidName("a/b"), path: "a/b") == .invalidName("a/b"))
    }

    @Test func passthrough() {
        #expect(SMBError.map(SMBError.timeout) == .timeout)
    }

    @Test func chineseDescriptionsArePresent() {
        let all: [SMBError] = [
            .authenticationFailed, .shareNotFound("家庭共享"), .permissionDenied,
            .notFound("/a"), .nameConflict("/b"), .noSpace, .timeout,
            .connectionLost, .invalidName("x"), .unsupported("x"), .cancelled, .other("x")
        ]
        for error in all {
            #expect(error.errorDescription?.isEmpty == false)
        }
    }
}
