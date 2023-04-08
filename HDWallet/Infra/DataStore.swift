import Foundation

private enum UserDefaultsKey {
    static let suiteName = "group.app.akiho.hd-wallet"
    static let primaryAddressKey = "primaryAddress"
    static let primaryNetworkKey = "primaryNetwork"
}

struct DataStore {
    static let shared = DataStore()
    private init() {}

    func getPrimaryAddress() -> String? {
        let userDefaults = UserDefaults(suiteName: UserDefaultsKey.suiteName)!
        return userDefaults.string(forKey: UserDefaultsKey.primaryAddressKey)
    }

    func savePrimaryAddress(address: String) {
        let userDefaults = UserDefaults(suiteName: UserDefaultsKey.suiteName)!
        userDefaults.set(address, forKey: UserDefaultsKey.primaryAddressKey)
    }

    func getPrimaryNetwork() -> String? {
        let userDefaults = UserDefaults(suiteName: UserDefaultsKey.suiteName)!
        return userDefaults.string(forKey: UserDefaultsKey.primaryNetworkKey)
    }

    func savePrimaryNetwork(id: String) {
        let userDefaults = UserDefaults(suiteName: UserDefaultsKey.suiteName)!
        userDefaults.set(id, forKey: UserDefaultsKey.primaryNetworkKey)
    }
    
    func delete() {
        let userDefaults = UserDefaults(suiteName: UserDefaultsKey.suiteName)!
        userDefaults.removeObject(forKey: UserDefaultsKey.primaryAddressKey)
        userDefaults.removeObject(forKey: UserDefaultsKey.primaryNetworkKey)
    }
}
