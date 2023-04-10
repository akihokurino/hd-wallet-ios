import Foundation
import Web3Core

struct EthereumKeyStore {
    private let accountKey = "hd-wallet"

    static let shared = EthereumKeyStore()
    private init() {}

    func save(keystore: EthereumKeystoreV3, key: EthereumAddress) throws {
        let data = try keystore.serialize()!
        let query = [
            kSecValueData: data,
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: key.address,
            kSecAttrAccount: accountKey,
        ] as [CFString: Any]

        switch SecItemCopyMatching(query as CFDictionary, nil) {
        case errSecItemNotFound:
            let status = SecItemAdd(query as CFDictionary, nil)
            if status != noErr {
                throw AppError.message("failed to save keychain")
            }
        case errSecSuccess:
            throw AppError.message("failed to save keychain")
        default:
            throw AppError.defaultError()
        }
    }

    func read(key: EthereumAddress) throws -> EthereumKeystoreV3? {
        let query = [
            kSecAttrService: key.address,
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
            return EthereumKeystoreV3(data)
        default:
            throw AppError.defaultError()
        }
    }

    func delete(key: EthereumAddress) throws {
        let query = [
            kSecAttrService: key.address,
            kSecAttrAccount: accountKey,
            kSecClass: kSecClassGenericPassword,
        ] as [CFString: Any]

        let status = SecItemDelete(query as CFDictionary)
        if status != noErr {
            throw AppError.message("failed to delete keychain")
        }
    }
}
