import Combine
import ComposableArchitecture
import Foundation

enum SelectAccountApp {
    static let reducer = AnyReducer<State, Action, Environment> { state, action, environment in
        switch action {
        case .startFetchAccounts:
            state.isPresentedHUD = true

            return Future<[Account], AppError> { promise in
                Task.detached(priority: .background) {
                    do {
                        let accounts = try Ethereum.shared.allAccounts()
                        promise(.success(accounts))
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
            .map(SelectAccountApp.Action.endFetchAccounts)
        case .endFetchAccounts(.success(let accounts)):
            state.accounts = accounts
            state.isPresentedHUD = false
            return .none
        case .endFetchAccounts(.failure(let error)):
            state.isPresentedHUD = false
            state.isPresentedErrorAlert = true
            state.error = error
            return .none
        case .startSelectAccount(let account):
            state.isPresentedHUD = true

            return Future<Account, AppError> { promise in
                Task.detached(priority: .background) {
                    do {
                        try Ethereum.shared.changeAccount(account: account)
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
            .map(SelectAccountApp.Action.endSelectAccount)
        case .endSelectAccount(.success(let account)):
            state.primaryAccount = account
            state.isPresentedHUD = false
            return .none
        case .endSelectAccount(.failure(let error)):
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

extension SelectAccountApp {
    enum Action: Equatable {
        case startFetchAccounts
        case endFetchAccounts(Result<[Account], AppError>)
        case startSelectAccount(Account)
        case endSelectAccount(Result<Account, AppError>)
        case isPresentedErrorAlert(Bool)
        case isPresentedHUD(Bool)
    }

    struct State: Equatable {
        var isPresentedErrorAlert = false
        var isPresentedHUD = false
        var error: AppError?
        var accounts: [Account] = []
        var primaryAccount: Account
    }

    struct Environment {
        let mainQueue: AnySchedulerOf<DispatchQueue>
        let backgroundQueue: AnySchedulerOf<DispatchQueue>
    }
}
