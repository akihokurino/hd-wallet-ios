import Foundation

struct PrivateKeyStore {
    private let serviceKey = "accounts"
    private let accountKey = "hd-wallet"

    static let shared = PrivateKeyStore()
    private init() {}

    func save(account: Account) throws {
        var next = try read()
        next.append(account)
        let data = try accountsToData(next)

        let query = [
            kSecValueData: data,
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: serviceKey,
            kSecAttrAccount: accountKey,
        ] as [CFString: Any]

        switch SecItemCopyMatching(query as CFDictionary, nil) {
        case errSecItemNotFound:
            if SecItemAdd(query as CFDictionary, nil) != noErr {
                throw AppError.message("failed to save keychain")
            }
        case errSecSuccess:
            if SecItemUpdate(query as CFDictionary, [kSecValueData as String: data] as CFDictionary) != noErr {
                throw AppError.message("failed to save keychain")
            }
        default:
            throw AppError.defaultError()
        }
    }

    func read() throws -> [Account] {
        let query = [
            kSecAttrService: serviceKey,
            kSecAttrAccount: accountKey,
            kSecClass: kSecClassGenericPassword,
            kSecReturnData: true,
        ] as [CFString: Any]

        var result: AnyObject?
        switch SecItemCopyMatching(query as CFDictionary, &result) {
        case errSecItemNotFound:
            return []
        case errSecSuccess:
            return try dataToAccounts(result as! Data)
        default:
            throw AppError.defaultError()
        }
    }

    private func accountsToData(_ accounts: [Account]) throws -> Data {
        return try JSONEncoder().encode(accounts)
    }

    private func dataToAccounts(_ data: Data) throws -> [Account] {
        return try JSONDecoder().decode([Account].self, from: data)
    }

    func delete() throws {
        let query = [
            kSecAttrService: serviceKey,
            kSecAttrAccount: accountKey,
            kSecClass: kSecClassGenericPassword,
        ] as [CFString: Any]

        if SecItemDelete(query as CFDictionary) != noErr {
            throw AppError.message("failed to delete keychain")
        }
    }
}
