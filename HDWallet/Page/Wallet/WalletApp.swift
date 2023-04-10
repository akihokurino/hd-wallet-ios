import Combine
import ComposableArchitecture
import Foundation

enum WalletApp {
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
                        promise(.success(try await Ethereum.shared.balance()))
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
            .map(WalletApp.Action.endInit)
        case .endInit(.success(let balance)):
            state.balance = balance
            state.isInitialized = true
            state.isPresentedHUD = false
            return .none
        case .endInit(.failure(let error)):
            state.isPresentedHUD = false
            state.isPresentedErrorAlert = true
            state.error = error
            return .none
        case .startRefresh:
            state.isPresentedPTR = true

            return Future<String, AppError> { promise in
                Task.detached(priority: .background) {
                    do {
                        promise(.success(try await Ethereum.shared.balance()))
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
            .map(WalletApp.Action.endRefresh)
        case .endRefresh(.success(let balance)):
            state.balance = balance
            state.isPresentedPTR = false
            return .none
        case .endRefresh(.failure(let error)):
            state.isPresentedPTR = false
            state.isPresentedErrorAlert = true
            state.error = error
            return .none
        case .startExportPrivateKey:
            state.isPresentedHUD = true

            return Future<String, AppError> { promise in
                Task.detached(priority: .background) {
                    do {
                        promise(.success(try Ethereum.shared.export()))
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
            .map(WalletApp.Action.endExportPrivateKey)
        case .endExportPrivateKey(.success(let privateKey)):
            print("export private key: \(privateKey)")
            state.exportedPrivateKey = privateKey
            state.isPresentedHUD = false
            return .none
        case .endExportPrivateKey(.failure(let error)):
            state.isPresentedHUD = false
            state.isPresentedErrorAlert = true
            state.error = error
            return .none
        case .startExportMnemonics:
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
            .map(WalletApp.Action.endExportMnemonics)
        case .endExportMnemonics(.success(let mnemonics)):
            print("exported mnemonics: \(mnemonics)")
            state.exportedMnemonics = mnemonics
            state.isPresentedHUD = false
            return .none
        case .endExportMnemonics(.failure(let error)):
            state.isPresentedHUD = false
            state.isPresentedErrorAlert = true
            state.error = error
            return .none
        case .hideExported:
            state.exportedPrivateKey = nil
            state.exportedMnemonics = nil
            return .none
        case .reset:
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
        case .isPresentedPTR(let val):
            state.isPresentedPTR = val
            return .none
        case .isPresentedMenu(let val):
            state.isPresentedMenu = val
            return .none
        case .isPresentedImportWalletView(let val):
            state.importWalletState = val ? ManageKeyApp.State() : nil
            state.isPresentedImportWalletView = val
            return .none
        case .isPresentedSelectNetworkView(let val):
            state.selectNetworkState = val ? SelectNetworkApp.State(primaryNetwork: state.network) : nil
            state.isPresentedSelectNetworkView = val
            return .none
        case .isPresentedSelectAccountView(let val):
            state.selectAccountState = val ? SelectAccountApp.State(primaryAccount: state.account) : nil
            state.isPresentedSelectAccountView = val
            return .none
        case .isPresentedSendEtherView(let val):
            state.sendEtherState = val ? SendEtherApp.State(account: state.account, network: state.network, balance: state.balance) : nil
            state.isPresentedSendEtherView = val
            return val ? .none : EffectTask(value: .startRefresh)

        case .selectAccountAction(let action):
            switch action {
            case .endSelectAccount(.success(let account)):
                state.account = account
                state.isPresentedSelectAccountView = false
                state.balance = "---"
                return EffectTask(value: .startRefresh)
            default:
                return .none
            }
        case .selectNetworkAction(let action):
            switch action {
            case .selectNetwork(let network):
                state.network = network
                state.isPresentedSelectNetworkView = false
                state.balance = "---"
                return EffectTask(value: .startRefresh)
            default:
                return .none
            }
        case .importWalletAction(let action):
            switch action {
            case .endGenPrivateKey(.success(let account)):
                state.account = account
                state.isPresentedImportWalletView = false
                state.balance = "---"
                return EffectTask(value: .startRefresh)
            case .endRestorePrivateKey(.success(let account)):
                state.account = account
                state.isPresentedImportWalletView = false
                state.balance = "---"
                return EffectTask(value: .startRefresh)
            default:
                return .none
            }
        case .sendEtherAction(let action):
            return .none
        }
    }
    .connect(
        SelectAccountApp.reducer,
        state: \WalletApp.State.selectAccountState,
        action: /WalletApp.Action.selectAccountAction,
        environment: { env in
            SelectAccountApp.Environment(
                mainQueue: env.mainQueue,
                backgroundQueue: env.backgroundQueue
            )
        }
    )
    .connect(
        SelectNetworkApp.reducer,
        state: \WalletApp.State.selectNetworkState,
        action: /WalletApp.Action.selectNetworkAction,
        environment: { env in
            SelectNetworkApp.Environment(
                mainQueue: env.mainQueue,
                backgroundQueue: env.backgroundQueue
            )
        }
    )
    .connect(
        ManageKeyApp.reducer,
        state: \WalletApp.State.importWalletState,
        action: /WalletApp.Action.importWalletAction,
        environment: { env in
            ManageKeyApp.Environment(
                mainQueue: env.mainQueue,
                backgroundQueue: env.backgroundQueue
            )
        }
    )
    .connect(
        SendEtherApp.reducer,
        state: \WalletApp.State.sendEtherState,
        action: /WalletApp.Action.sendEtherAction,
        environment: { env in
            SendEtherApp.Environment(
                mainQueue: env.mainQueue,
                backgroundQueue: env.backgroundQueue
            )
        }
    )
}

extension WalletApp {
    enum Action: Equatable {
        case startInit
        case endInit(Result<String, AppError>)
        case startRefresh
        case endRefresh(Result<String, AppError>)
        case startExportPrivateKey
        case endExportPrivateKey(Result<String, AppError>)
        case startExportMnemonics
        case endExportMnemonics(Result<String, AppError>)
        case hideExported
        case reset
        case isPresentedErrorAlert(Bool)
        case isPresentedHUD(Bool)
        case isPresentedPTR(Bool)
        case isPresentedMenu(Bool)
        case isPresentedImportWalletView(Bool)
        case isPresentedSelectNetworkView(Bool)
        case isPresentedSelectAccountView(Bool)
        case isPresentedSendEtherView(Bool)

        case selectAccountAction(SelectAccountApp.Action)
        case selectNetworkAction(SelectNetworkApp.Action)
        case importWalletAction(ManageKeyApp.Action)
        case sendEtherAction(SendEtherApp.Action)
    }

    struct State: Equatable {
        var isInitialized = false
        var isPresentedErrorAlert = false
        var isPresentedHUD = false
        var isPresentedPTR = false
        var isPresentedMenu = false
        var isPresentedImportWalletView = false
        var isPresentedSelectNetworkView = false
        var isPresentedSelectAccountView = false
        var isPresentedSendEtherView = false
        var error: AppError?
        var account: Account
        var network: Network
        var balance = ""
        var exportedPrivateKey: String?
        var exportedMnemonics: String?

        var selectAccountState: SelectAccountApp.State?
        var selectNetworkState: SelectNetworkApp.State?
        var importWalletState: ManageKeyApp.State?
        var sendEtherState: SendEtherApp.State?
    }

    struct Environment {
        let mainQueue: AnySchedulerOf<DispatchQueue>
        let backgroundQueue: AnySchedulerOf<DispatchQueue>
    }
}
