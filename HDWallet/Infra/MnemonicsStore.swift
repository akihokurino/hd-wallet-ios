import Foundation

struct MnemonicsStore {
    private let serviceKey = "mnemonics"
    private let accountKey = "hd-wallet"

    static let shared = MnemonicsStore()
    private init() {}

    func save(mnemonics: String) throws {
        let data = mnemonics.data(using: .utf8)!

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
            throw AppError.message("failed to save keychain")
        default:
            throw AppError.defaultError()
        }
    }

    func read() throws -> String? {
        let query = [
            kSecAttrService: serviceKey,
            kSecAttrAccount: accountKey,
            kSecClass: kSecClassGenericPassword,
            kSecReturnData: true,
        ] as [CFString: Any]

        var result: AnyObject?
        switch SecItemCopyMatching(query as CFDictionary, &result) {
        case errSecItemNotFound:
            return nil
        case errSecSuccess:
            return String(data: result as! Data, encoding: .utf8)
        default:
            throw AppError.defaultError()
        }
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
