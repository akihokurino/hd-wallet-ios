import Foundation

enum Env {
    static let infuraKey = Bundle.main.object(forInfoDictionaryKey: "Infura key") as! String
}
