import Foundation
import Web3Core

struct PrivateKey: Codable {
    let data: Data
    
    static func from(raw: String) -> PrivateKey? {
        let formattedKey = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = Data.fromHex(formattedKey) else {
            return nil
        }
        
        guard SECP256K1.verifyPrivateKey(privateKey: data) else {
            return nil
        }
        
        return PrivateKey(data: data)
    }
    
    func toString() -> String {
        return data.toHexString()
    }
}
