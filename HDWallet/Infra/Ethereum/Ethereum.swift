import BigInt
import Foundation
import Web3Core
import web3swift

final class Ethereum {
    private var cli: Web3?
    private var keystore: AbstractKeystore?
    private let password = "web3swift"
    private let gasLimit: BigUInt = 8500000
    private let gasPrice: BigUInt = 40000000000
    private let prefixPath = "m/44'/60'/0'/0"

    static let shared = Ethereum()

    private init() {}

    private var keystoreManager: KeystoreManager? {
        guard let keystore = keystore else {
            return nil
        }

        if keystore is EthereumKeystoreV3 {
            return KeystoreManager([keystore as! EthereumKeystoreV3])
        } else if keystore is BIP32Keystore {
            return KeystoreManager([keystore as! BIP32Keystore])
        } else {
            return nil
        }
    }

    var address: EthereumAddress? {
        return keystore?.addresses?.first
    }

    var primaryNetwork: Network {
        let primaryNetwork = Network.allCases.first(where: { $0.id == DataStore.shared.getPrimaryNetwork() })
        guard let primaryNetwork = primaryNetwork else {
            return Network.ethereum
        }
        return primaryNetwork
    }

    func allAccounts() throws -> [Account] {
        var accounts = try ExternalPrivateKeyStore.shared.read()
        accounts.append(contentsOf: try InternalPrivateKeyStore.shared.read())
        if accounts.isEmpty {
            return []
        }

        accounts.sort { $0.createdAt.timeIntervalSince1970 < $1.createdAt.timeIntervalSince1970 }
        return accounts
    }

    func primaryAccount() throws -> Account? {
        let accounts = try allAccounts()
        if accounts.isEmpty {
            return nil
        }

        if let primaryAddress = DataStore.shared.getPrimaryAddress(), let account = accounts.first(where: { $0.address.address == primaryAddress }) {
            keystore = try EthereumKeystoreV3(privateKey: account.privateKey.data, password: password)
            return account
        } else {
            keystore = try EthereumKeystoreV3(privateKey: accounts.last!.privateKey.data, password: password)
            return accounts.last!
        }
    }

    func mnemonics() throws -> String {
        if let mnemonics = try MnemonicsStore.shared.read() {
            return mnemonics
        }

        let mnemonics = try BIP39.generateMnemonics(bitsOfEntropy: 256, language: .english)!

        try MnemonicsStore.shared.save(mnemonics: mnemonics)
        return mnemonics
    }

    func restoreFrom(mnemonics: String, accountNum: Int) throws -> Account {
        let accounts = try InternalPrivateKeyStore.shared.read()
        guard accounts.isEmpty else {
            throw AppError.message("accounts is already exists")
        }
        guard accountNum > 0 else {
            throw AppError.message("should set account num")
        }

        try MnemonicsStore.shared.delete()
        try MnemonicsStore.shared.save(mnemonics: mnemonics)

        var account: Account!

        for index in 0 ..< accountNum {
            keystore = try BIP32Keystore(mnemonics: mnemonics, password: password, prefixPath: prefixPath + "/\(index)")
            let address = keystore!.addresses!.first!
            let privateKey = try keystore!.UNSAFE_getPrivateKeyData(password: password, account: address)

            account = Account(
                name: "Account \(index + 1)",
                privateKey: PrivateKey(data: privateKey),
                address: address,
                createdAt: Date())

            try InternalPrivateKeyStore.shared.save(account: account)
            DataStore.shared.savePrimaryAddress(address: address.address)
        }

        return account
    }

    func generateKey() throws -> Account {
        let mnemonics = try mnemonics()
        let accounts = try InternalPrivateKeyStore.shared.read()
        let keystore = try BIP32Keystore(mnemonics: mnemonics, password: password, prefixPath: "\(prefixPath)/\(accounts.count)")
        let address = keystore!.addresses!.first!
        let privateKey = try keystore!.UNSAFE_getPrivateKeyData(password: password, account: address)

        let newAccount = Account(
            name: "Account \(accounts.count + 1)",
            privateKey: PrivateKey(data: privateKey),
            address: address,
            createdAt: Date())

        try InternalPrivateKeyStore.shared.save(account: newAccount)
        DataStore.shared.savePrimaryAddress(address: address.address)

        return newAccount
    }

    func importKey(rawPrivateKey: String) throws -> Account {
        guard let privateKey = PrivateKey.from(raw: rawPrivateKey) else {
            throw AppError.message("invalid private key")
        }
        let accounts = try ExternalPrivateKeyStore.shared.read()
        keystore = try EthereumKeystoreV3(privateKey: privateKey.data, password: password)
        let address = keystore!.addresses!.first!

        let newAccount = Account(
            name: "Imported Account \(accounts.count + 1)",
            privateKey: privateKey,
            address: address,
            createdAt: Date())

        try ExternalPrivateKeyStore.shared.save(account: newAccount)
        DataStore.shared.savePrimaryAddress(address: address.address)

        return newAccount
    }

    func changeNetwork(network: Network) {
        DataStore.shared.savePrimaryNetwork(id: network.id)
    }

    func changeAccount(account: Account) throws {
        keystore = try EthereumKeystoreV3(privateKey: account.privateKey.data, password: password)
        DataStore.shared.savePrimaryAddress(address: account.address.address)
    }

    private func web3(keystore: AbstractKeystore) async throws -> Web3 {
        let network = primaryNetwork
        let provider = try await Web3HttpProvider(
            url: network.networkUrl,
            network: Networks.Custom(networkID: BigUInt(network.chainId)))
        let web3 = Web3(provider: provider)
        web3.addKeystoreManager(keystoreManager)
        cli = web3
        return web3
    }

    func export() throws -> String? {
        guard let keystoreManager = self.keystoreManager, let address = self.address else {
            return nil
        }

        let pkData = try keystoreManager.UNSAFE_getPrivateKeyData(password: password, account: address)
        return pkData.toHexString()
    }

    func balance() async throws -> String? {
        guard let keystore = self.keystore, let address = self.address else {
            return nil
        }

        let balanceWei: BigUInt = try await web3(keystore: keystore).eth.getBalance(for: address)
        return EthereumUtil.toEtherString(wei: balanceWei)
    }

    func sendEth(to: EthereumAddress, amount: String) async throws -> String? {
        guard let keystore = self.keystore, let address = self.address else {
            return nil
        }

        var transaction: CodableTransaction = .emptyTransaction
        transaction.from = address
        transaction.to = to
        transaction.value = Utilities.parseToBigUInt(amount, units: .ether)!
        transaction.gasLimit = gasLimit
        transaction.gasPrice = gasPrice
        transaction.chainID = BigUInt(primaryNetwork.chainId)

        let web3 = try await web3(keystore: keystore)

        let resolver = PolicyResolver(provider: web3.provider)
        try await resolver.resolveAll(for: &transaction)
        try Web3Signer.signTX(transaction: &transaction,
                              keystore: keystore,
                              account: address,
                              password: password)

        guard let txEncoded = transaction.encode() else { return "" }
        let res = try await web3.eth.send(raw: txEncoded)
        let txhash = res.transaction.hash?.toHexString() ?? ""
        return txhash
    }
}
