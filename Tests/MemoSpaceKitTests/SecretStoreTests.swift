import Foundation
import Testing
@testable import MemoSpaceKit

@Suite struct SecretStoreTests {
    @Test func inMemoryStoreSetGetDelete() throws {
        let store = InMemorySecretStore()
        let id = UUID()
        #expect(try store.password(for: id) == nil)
        try store.setPassword("s3cret", for: id)
        #expect(try store.password(for: id) == "s3cret")
        try store.setPassword("updated", for: id)
        #expect(try store.password(for: id) == "updated")
        try store.setPassword(nil, for: id)
        #expect(try store.password(for: id) == nil)
    }
}
