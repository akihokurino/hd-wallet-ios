import Foundation

struct ErrorAlertEntity {
    let title: String
    let message: String
}

enum AppError: Error, Equatable {
    case message(String)

    static func defaultError() -> AppError {
        return .message("internal error")
    }
    
    var alert: ErrorAlertEntity {
        switch self {
        case .message(let message):
            return ErrorAlertEntity(title: "", message: message)
        }
    }
}
