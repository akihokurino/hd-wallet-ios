import ComposableArchitecture
import SwiftUI

struct RootView: View {
    let store: Store<RootApp.State, RootApp.Action>

    var body: some View {
        WithViewStore(store) { viewStore in
            NavigationView {
                IfLetStore(
                    store.scope(
                        state: { $0.walletState },
                        action: RootApp.Action.walletAction
                    ),
                    then: WalletView.init(store:)
                )
            }
            .onAppear {
                viewStore.send(.startInit)
            }
            .overlay(
                Group {
                    if viewStore.state.isPresentedHUD {
                        HUD(isLoading: viewStore.binding(
                            get: { $0.isPresentedHUD },
                            send: RootApp.Action.isPresentedHUD
                        ))
                    }
                }, alignment: .center
            )
            .alert(
                viewStore.error?.alert.title ?? "",
                isPresented: viewStore.binding(
                    get: { $0.isPresentedErrorAlert },
                    send: RootApp.Action.isPresentedErrorAlert
                ),
                presenting: viewStore.error?.alert
            ) { _ in
                Button("OK") {
                    viewStore.send(.isPresentedErrorAlert(false))
                }
            } message: { entity in
                Text(entity.message)
            }
        }
    }
}
