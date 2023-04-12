import Combine
import ComposableArchitecture
import Foundation
import Web3Core

enum ManageKeyApp {
    static let reducer = AnyReducer<State, Action, Environment> { state, action, environment in
        switch action {
        case .startGenPrivateKey(let isImport):
            state.isPresentedHUD = true

            let inputPrivateKey = state.inputPrivateKey

            return Future<Account, AppError> { promise in
                Task.detached(priority: .high) {
                    do {
                        let account: Account!
                        if isImport {
                            account = try Ethereum.shared.importKey(rawPrivateKey: inputPrivateKey)
                        } else {
                            account = try Ethereum.shared.generateKey()
                        }

                        promise(.success(account))
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
            .map(ManageKeyApp.Action.endGenPrivateKey)
        case .endGenPrivateKey(.success(let account)):
            state.isPresentedHUD = false
            return .none
        case .endGenPrivateKey(.failure(let error)):
            state.isPresentedHUD = false
            state.isPresentedErrorAlert = true
            state.error = error
            return .none
        case .startRestorePrivateKey:
            guard !state.inputMnemonics.isEmpty else {
                return .none
            }
            
            state.isPresentedHUD = true

            let inputMnemonics = state.inputMnemonics
        
            return Future<Account, AppError> { promise in
                Task.detached(priority: .high) {
                    do {
                        promise(.success(try Ethereum.shared.restoreWalletFrom(mnemonics: inputMnemonics)))
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
            .map(ManageKeyApp.Action.endRestorePrivateKey)
        case .endRestorePrivateKey(.success(let account)):
            state.isPresentedHUD = false
            return .none
        case .endRestorePrivateKey(.failure(let error)):
            state.isPresentedHUD = false
            state.isPresentedErrorAlert = true
            state.error = error
            return .none
        case .inputPrivateKey(let val):
            state.inputPrivateKey = val
            return .none
        case .inputMnemonics(let val):
            state.inputMnemonics = val
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

extension ManageKeyApp {
    enum Action: Equatable {
        case startGenPrivateKey(Bool)
        case endGenPrivateKey(Result<Account, AppError>)
        case startRestorePrivateKey
        case endRestorePrivateKey(Result<Account, AppError>)
        case inputPrivateKey(String)
        case inputMnemonics(String)
        case isPresentedErrorAlert(Bool)
        case isPresentedHUD(Bool)
    }

    struct State: Equatable {
        var isInitialized = false
        var isPresentedErrorAlert = false
        var isPresentedHUD = false
        var error: AppError?
        var inputPrivateKey = ""
        var inputMnemonics = ""
    }

    struct Environment {
        let mainQueue: AnySchedulerOf<DispatchQueue>
        let backgroundQueue: AnySchedulerOf<DispatchQueue>
    }
}
