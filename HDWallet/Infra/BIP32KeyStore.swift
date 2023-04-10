import Foundation
import Web3Core

struct BIP32KeyStore {
    private let serviceKey = "bip32-keystore"
    private let accountKey = "hd-wallet"

    static let shared = BIP32KeyStore()
    private init() {}

    func save(keystore: BIP32Keystore) throws {
        let data = try keystore.serialize()!
        let query = [
            kSecValueData: data,
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: serviceKey,
            kSecAttrAccount: accountKey,
        ] as [CFString: Any]

        switch SecItemCopyMatching(query as CFDictionary, nil) {
        case errSecItemNotFound:
            let status = SecItemAdd(query as CFDictionary, nil)
            if status != noErr {
                throw AppError.message("failed to save keychain")
            }
        case errSecSuccess:
            let status = SecItemUpdate(query as CFDictionary, [kSecValueData as String: data] as CFDictionary)
            if status != noErr {
                throw AppError.message("failed to save keychain")
            }
        default:
            throw AppError.defaultError()
        }
    }

    func read() throws -> BIP32Keystore? {
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
            guard let data = result as? Data else {
                throw AppError.message("failed to load keychain")
            }
            return BIP32Keystore(data)
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

        let status = SecItemDelete(query as CFDictionary)
        if status != noErr {
            throw AppError.message("failed to delete keychain")
        }
    }
}
