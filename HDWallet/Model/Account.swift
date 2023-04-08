import Foundation
import Web3Core

struct Account: Codable, Identifiable, Equatable {
    static func == (lhs: Account, rhs: Account) -> Bool {
        return lhs.id == rhs.id
    }
    
    var id: String {
        return address.address
    }
    
    let name: String
    let privateKey: PrivateKey
    let address: EthereumAddress
    let createdAt: Date
}
