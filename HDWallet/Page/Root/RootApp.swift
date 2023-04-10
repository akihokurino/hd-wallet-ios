import Combine
import ComposableArchitecture
import Foundation
import Web3Core

enum RootApp {
    static let reducer = AnyReducer<State, Action, Environment> { state, action, environment in
        switch action {
        case .startInit:
            guard !state.isInitialized else {
                return .none
            }

            state.isPresentedHUD = true

            return Future<Account, AppError> { promise in
                Task.detached(priority: .background) {
                    do {
                        promise(.success(try Ethereum.shared.initWallet()))
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
            .map(RootApp.Action.endInit)
        case .endInit(.success(let account)):
            state.isInitialized = true
            state.isPresentedHUD = false
            state.walletState = WalletApp.State(account: account, network: Ethereum.shared.primaryNetwork())
            return .none
        case .endInit(.failure(let error)):
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

        case .walletAction(let action):
            switch action {
            case .reset:
                Ethereum.shared.delete()
                state.isInitialized = false
                return EffectTask(value: .startInit)
            default:
                return .none
            }
        }
    }
    .connect(
        WalletApp.reducer,
        state: \RootApp.State.walletState,
        action: /RootApp.Action.walletAction,
        environment: { env in
            WalletApp.Environment(
                mainQueue: env.mainQueue,
                backgroundQueue: env.backgroundQueue
            )
        }
    )
}

extension RootApp {
    enum Action: Equatable {
        case startInit
        case endInit(Result<Account, AppError>)
        case isPresentedErrorAlert(Bool)
        case isPresentedHUD(Bool)

        case walletAction(WalletApp.Action)
    }

    struct State: Equatable {
        var isInitialized = false
        var isPresentedErrorAlert = false
        var isPresentedHUD = false
        var error: AppError?

        var walletState: WalletApp.State?
    }

    struct Environment {
        let mainQueue: AnySchedulerOf<DispatchQueue>
        let backgroundQueue: AnySchedulerOf<DispatchQueue>
    }
}
