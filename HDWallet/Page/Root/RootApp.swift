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

            return Future<Account?, AppError> { promise in
                Task.detached(priority: .background) {
                    do {
                        promise(.success(try Ethereum.shared.primaryAccount()))
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

            if let account = account {
                state.walletState = WalletApp.State(account: account)
            } else {
                state.importWalletState = ManageKeyApp.State()
                state.isPresentedImportWalletView = true
            }

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
        case .isPresentedImportWalletView(let val):
            state.isPresentedImportWalletView = val
            return .none

        case .walletAction(let action):
            switch action {
            case .reset:
                try? ExternalPrivateKeyStore.shared.delete()
                try? InternalPrivateKeyStore.shared.delete()
                try? MnemonicsStore.shared.delete()
                DataStore.shared.delete()
                state.walletState = nil
                state.importWalletState = ManageKeyApp.State()
                state.isPresentedImportWalletView = true
                return .none
            default:
                return .none
            }
        case .importWalletAction(let action):
            switch action {
            case .endGenPrivateKey(.success(let account)):
                state.isPresentedImportWalletView = false
                state.walletState = WalletApp.State(account: account)
                return .none
            case .endRestorePrivateKey(.success(let account)):
                state.isPresentedImportWalletView = false
                state.walletState = WalletApp.State(account: account)
                return .none
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
    .connect(
        ManageKeyApp.reducer,
        state: \RootApp.State.importWalletState,
        action: /RootApp.Action.importWalletAction,
        environment: { env in
            ManageKeyApp.Environment(
                mainQueue: env.mainQueue,
                backgroundQueue: env.backgroundQueue
            )
        }
    )
}

extension RootApp {
    enum Action: Equatable {
        case startInit
        case endInit(Result<Account?, AppError>)
        case isPresentedErrorAlert(Bool)
        case isPresentedHUD(Bool)
        case isPresentedImportWalletView(Bool)

        case walletAction(WalletApp.Action)
        case importWalletAction(ManageKeyApp.Action)
    }

    struct State: Equatable {
        var isInitialized = false
        var isPresentedErrorAlert = false
        var isPresentedHUD = false
        var isPresentedImportWalletView = false
        var error: AppError?

        var walletState: WalletApp.State?
        var importWalletState: ManageKeyApp.State?
    }

    struct Environment {
        let mainQueue: AnySchedulerOf<DispatchQueue>
        let backgroundQueue: AnySchedulerOf<DispatchQueue>
    }
}
