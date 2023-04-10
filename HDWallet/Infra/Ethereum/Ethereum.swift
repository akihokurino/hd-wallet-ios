import BigInt
import Foundation
import Web3Core
import web3swift

final class Ethereum {
    private let password = "web3swift"
    private let gasLimit: BigUInt = 8500000
    private let gasPrice: BigUInt = 40000000000
    
    static let shared = Ethereum()

    private init() {}

    private func web3(keystore: AbstractKeystore) async throws -> Web3 {
        let network = primaryNetwork()
        let provider = try await Web3HttpProvider(
            url: network.networkUrl,
            network: Networks.Custom(networkID: BigUInt(network.chainId)))

        let web3 = Web3(provider: provider)
        web3.addKeystoreManager(try keystoreManager())

        return web3
    }

    private func primaryKeystore() throws -> (BIP32Keystore?, EthereumKeystoreV3?) {
        let account = try primaryAccount()
        if account.fromMnemonics {
            return (try BIP32KeyStore.shared.read(), nil)
        } else {
            return (nil, try EthereumKeyStore.shared.read(key: account.address))
        }
    }

    private func keystoreManager() throws -> KeystoreManager {
        switch try primaryKeystore() {
        case let (keystore?, _):
            return KeystoreManager([keystore])
        case let (_, keystore?):
            return KeystoreManager([keystore])
        default:
            throw AppError.defaultError()
        }
    }

    func primaryNetwork() -> Network {
        let primaryNetwork = Network.allCases.first(where: { $0.id == DataStore.shared.getPrimaryNetwork() })
        guard let primaryNetwork = primaryNetwork else {
            return Network.ethereum
        }
        return primaryNetwork
    }

    func primaryAccount() throws -> Account {
        let accounts = try PrivateKeyStore.shared.read()
        if accounts.isEmpty {
            throw AppError.defaultError()
        }

        let primaryAddress = DataStore.shared.getPrimaryAddress()
        guard let account = accounts.first(where: { $0.address.address == primaryAddress }) else {
            return accounts.first!
        }
        return account
    }

    func changeNetwork(network: Network) {
        DataStore.shared.savePrimaryNetwork(id: network.id)
    }

    func changeAccount(account: Account) throws {
        DataStore.shared.savePrimaryAddress(address: account.address.address)
    }
    
    func allAccounts() throws -> [Account] {
        return try PrivateKeyStore.shared.read()
    }

    func initWallet() throws -> Account {
        if try BIP32KeyStore.shared.read() != nil {
            return try primaryAccount()
        }
    
        let mnemonics = try BIP39.generateMnemonics(bitsOfEntropy: 128, language: .english)!
        return try restoreWalletFrom(mnemonics: mnemonics)
    }

    func mnemonics() throws -> String {
        return try MnemonicsStore.shared.read()!
    }

    func restoreWalletFrom(mnemonics: String) throws -> Account {
        delete()
        try MnemonicsStore.shared.save(mnemonics: mnemonics)
        let keystore = try BIP32Keystore(mnemonics: mnemonics, password: password)!
        let address = keystore.addresses!.first!
    
        let account = Account(
            name: "Account1",
            address: address,
            fromMnemonics: true,
            createdAt: Date())

        try BIP32KeyStore.shared.save(keystore: keystore)
        try PrivateKeyStore.shared.save(account: account)
        DataStore.shared.savePrimaryAddress(address: address.address)

        return account
    }

    func generateKey() throws -> Account {
        let keystore = try BIP32KeyStore.shared.read()!
        try keystore.createNewChildAccount(password: password)
        let address = keystore.addresses!.last!
        
        let accounts = try PrivateKeyStore.shared.read()
        let newAccount = Account(
            name: "Account\(accounts.count + 1)",
            address: address,
            fromMnemonics: true,
            createdAt: Date())

        try BIP32KeyStore.shared.save(keystore: keystore)
        try PrivateKeyStore.shared.save(account: newAccount)
        DataStore.shared.savePrimaryAddress(address: address.address)

        return newAccount
    }

    func importKey(rawPrivateKey: String) throws -> Account {
        let privateKey = PrivateKey.from(raw: rawPrivateKey)!
        let keystore = try EthereumKeystoreV3(privateKey: privateKey.data, password: password)!
        let address = keystore.addresses!.first!

        let accounts = try PrivateKeyStore.shared.read()
        let newAccount = Account(
            name: "Account\(accounts.count + 1)",
            address: address,
            fromMnemonics: false,
            createdAt: Date())

        try EthereumKeyStore.shared.save(keystore: keystore, key: address)
        try PrivateKeyStore.shared.save(account: newAccount)
        DataStore.shared.savePrimaryAddress(address: address.address)

        return newAccount
    }

    func export() throws -> String {
        let pkData = try keystoreManager().UNSAFE_getPrivateKeyData(password: password, account: try primaryAccount().address)
        return pkData.toHexString()
    }

    func balance() async throws -> String {
        let address = try primaryAccount().address
        let keystore = try keystoreManager().walletForAddress(address)!
        let balanceWei: BigUInt = try await web3(keystore: keystore).eth.getBalance(for: address)
        return EthereumUtil.toEtherString(wei: balanceWei)
    }

    func sendEth(to: EthereumAddress, amount: String) async throws -> String {
        let address = try primaryAccount().address
        let keystore = try keystoreManager().walletForAddress(address)!

        var transaction: CodableTransaction = .emptyTransaction
        transaction.from = address
        transaction.to = to
        transaction.value = Utilities.parseToBigUInt(amount, units: .ether)!
        transaction.gasLimit = gasLimit
        transaction.gasPrice = gasPrice
        transaction.chainID = BigUInt(primaryNetwork().chainId)

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
    
    func delete() {
        try? PrivateKeyStore.shared.delete()
        try? BIP32KeyStore.shared.delete()
        let accounts = try? PrivateKeyStore.shared.read()
        accounts?.forEach {
            try? EthereumKeyStore.shared.delete(key: $0.address)
        }
        try? MnemonicsStore.shared.delete()
        DataStore.shared.delete()
    }
}
