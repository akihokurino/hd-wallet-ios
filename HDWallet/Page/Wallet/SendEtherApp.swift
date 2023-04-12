import Combine
import ComposableArchitecture
import Foundation
import Web3Core

enum SendEtherApp {
    static let reducer = AnyReducer<State, Action, Environment> { state, action, environment in
        switch action {
        case .inputToAddress(let address):
            guard let address = EthereumAddress(address) else {
                return .none
            }
            state.inputToAddress = address
            return .none
        case .inputAmount(let amount):
            state.inputAmount = amount
            return .none
        case .startSend:
            guard let toAddress = state.inputToAddress, !state.inputAmount.isEmpty else {
                return .none
            }

            let amount = state.inputAmount

            state.isPresentedHUD = true

            return Future<String, AppError> { promise in
                Task.detached(priority: .high) {
                    do {
                        promise(.success(try await Ethereum.shared.sendEth(to: toAddress, amount: amount)))
                    } catch let error as AppError {
                        promise(.failure(error))
                    } catch {
                        promise(.failure(AppError.defaultError()))
                    }
                }
            }
            .subscribe(on: environment.backgroundQueue)
            .receive(on: environment.mainQueue)
            .catchToEffect()
            .map(SendEtherApp.Action.endSend)
        case .endSend(.success(let txId)):
            print("transaction id: \(txId)")
            state.isPresentedHUD = false
            state.inputAmount = ""
            return .none
        case .endSend(.failure(let error)):
            state.isPresentedHUD = false
            state.isPresentedErrorAlert = true
            state.error = error
            return .none
        case .isPresentedErrorAlert(let val):
            state.isPresentedErrorAlert = val
            if !val {
                state.error = nil
            }
            return .none
        case .isPresentedHUD(let val):
            state.isPresentedHUD = val
            return .none
        }
    }
}

extension SendEtherApp {
    enum Action: Equatable {
        case inputToAddress(String)
        case inputAmount(String)
        case startSend
        case endSend(Result<String, AppError>)
        case isPresentedErrorAlert(Bool)
        case isPresentedHUD(Bool)
    }

    struct State: Equatable {
        var isPresentedErrorAlert = false
        var isPresentedHUD = false
        var error: AppError?
        let account: Account
        let network: Network
        let balance: String
        var inputToAddress: EthereumAddress?
        var inputAmount: String = ""
    }

    struct Environment {
        let mainQueue: AnySchedulerOf<DispatchQueue>
        let backgroundQueue: AnySchedulerOf<DispatchQueue>
    }
}
