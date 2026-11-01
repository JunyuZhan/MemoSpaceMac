import Foundation
import Security

public enum KeychainError: Error, Equatable {
    case status(OSStatus)
}

public struct KeychainStore: SecretStore {
    private let service: String

    public init(service: String = "com.local.memospacemac") {
        self.service = service
    }

    private func baseQuery(account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }

    private func account(for id: UUID) -> String {
        "profile.\(id.uuidString)"
    }

    public func password(for profileID: UUID) throws -> String? {
        var query = baseQuery(account: account(for: profileID))
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = result as? Data else {
            throw KeychainError.status(status)
        }
        return String(data: data, encoding: .utf8)
    }

    public func setPassword(_ password: String?, for profileID: UUID) throws {
        let account = account(for: profileID)
        if let password {
            let data = Data(password.utf8)
            let updateStatus = SecItemUpdate(
                baseQuery(account: account) as CFDictionary,
                [kSecValueData as String: data] as CFDictionary
            )
            if updateStatus == errSecItemNotFound {
                var attributes = baseQuery(account: account)
                attributes[kSecValueData as String] = data
                attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
                let addStatus = SecItemAdd(attributes as CFDictionary, nil)
                guard addStatus == errSecSuccess else { throw KeychainError.status(addStatus) }
            } else if updateStatus != errSecSuccess {
                throw KeychainError.status(updateStatus)
            }
        } else {
            let deleteStatus = SecItemDelete(baseQuery(account: account) as CFDictionary)
            guard deleteStatus == errSecSuccess || deleteStatus == errSecItemNotFound else {
                throw KeychainError.status(deleteStatus)
            }
        }
    }
}
