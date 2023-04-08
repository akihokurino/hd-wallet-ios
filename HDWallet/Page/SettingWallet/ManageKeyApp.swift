import Combine
import ComposableArchitecture
import Foundation
import Web3Core

enum ManageKeyApp {
    static let reducer = AnyReducer<State, Action, Environment> { state, action, environment in
        switch action {
        case .startInit:
            guard !state.isInitialized else {
                return .none
            }

            state.isPresentedHUD = true

            return Future<String, AppError> { promise in
                Task.detached(priority: .background) {
                    do {
                        promise(.success(try Ethereum.shared.mnemonics()))
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
            .map(ManageKeyApp.Action.endInit)
        case .endInit(.success(let mnemonics)):
            print("mnemonics: \(mnemonics)")
            state.isInitialized = true
            state.isPresentedHUD = false
            state.mnemonics = mnemonics
            return .none
        case .endInit(.failure(let error)):
            state.isInitialized = true
            state.isPresentedHUD = false
            state.isPresentedErrorAlert = true
            state.error = error
            return .none
        case .startGenPrivateKey(let isImport):
            state.isPresentedHUD = true

            let inputPrivateKey = state.inputPrivateKey

            return Future<Account, AppError> { promise in
                Task.detached(priority: .background) {
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
            guard !state.inputMnemonics.isEmpty && !state.inputRestoreAccountNum.isEmpty else {
                return .none
            }
            
            state.isPresentedHUD = true

            let inputMnemonics = state.inputMnemonics
            let inputRestoreAccountNum = Int(state.inputRestoreAccountNum)!

            return Future<Account, AppError> { promise in
                Task.detached(priority: .background) {
                    do {
                        promise(.success(try Ethereum.shared.restoreFrom(mnemonics: inputMnemonics, accountNum: inputRestoreAccountNum)))
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
        case .inputRestoreAccountNum(let val):
            state.inputRestoreAccountNum = val
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
        case startInit
        case endInit(Result<String, AppError>)
        case startGenPrivateKey(Bool)
        case endGenPrivateKey(Result<Account, AppError>)
        case startRestorePrivateKey
        case endRestorePrivateKey(Result<Account, AppError>)
        case inputPrivateKey(String)
        case inputMnemonics(String)
        case inputRestoreAccountNum(String)
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
        var inputRestoreAccountNum = ""
        var mnemonics = ""
    }

    struct Environment {
        let mainQueue: AnySchedulerOf<DispatchQueue>
        let backgroundQueue: AnySchedulerOf<DispatchQueue>
    }
}
