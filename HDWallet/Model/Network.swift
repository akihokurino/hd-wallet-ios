import BigInt
import Foundation

enum Network: CaseIterable, Identifiable {
    case ethereum
    case polygon
    case avalanch

    var id: String {
        return String(chainId)
    }

    var networkUrl: URL {
        switch self {
        case .ethereum:
            return URL(string: "https://goerli.infura.io/v3/\(Env.infuraKey)")!
        case .polygon:
            return URL(string: "https://polygon-mumbai.infura.io/v3/\(Env.infuraKey)")!
        case .avalanch:
            return URL(string: "https://avalanche-fuji.infura.io/v3/\(Env.infuraKey)")!
        }
    }

    var chainId: Int {
        switch self {
        case .ethereum:
            return 5
        case .polygon:
            return 80001
        case .avalanch:
            return 43113
        }
    }

    var displayName: String {
        switch self {
        case .ethereum:
            return "Goerli"
        case .polygon:
            return "Mumbai"
        case .avalanch:
            return "Fuji"
        }
    }
    
    var displayUnitName: String {
            switch self {
            case .ethereum:
                return "Ether"
            case .polygon:
                return "Matic"
            case .avalanch:
                return "Avax"
            }
        }
}
