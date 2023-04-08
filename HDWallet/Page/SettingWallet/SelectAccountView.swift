import ComposableArchitecture
import SwiftUI

struct SelectAccountView: View {
    let store: Store<SelectAccountApp.State, SelectAccountApp.Action>

    var body: some View {
        WithViewStore(store) { viewStore in
            List {
                ForEach(viewStore.state.accounts, id: \.id) { account in
                    HStack {
                        VStack {
                            Text(account.name)
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Spacer().frame(height: 10)
                            Text(account.address.address)
                                .font(.subheadline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        Image(systemName: account.id == viewStore.primaryAccount.id ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(Color.blue)
                    }
                    .onTapGesture {
                        viewStore.send(.startSelectAccount(account))
                    }
                }
            }
            .navigationBarTitle("", displayMode: .inline)
            .onAppear {
                viewStore.send(.startFetchAccounts)
            }
            .overlay(
                Group {
                    if viewStore.state.isPresentedHUD {
                        HUD(isLoading: viewStore.binding(
                            get: { $0.isPresentedHUD },
                            send: SelectAccountApp.Action.isPresentedHUD
                        ))
                    }
                }, alignment: .center
            )
            .alert(
                viewStore.error?.alert.title ?? "",
                isPresented: viewStore.binding(
                    get: { $0.isPresentedErrorAlert },
                    send: SelectAccountApp.Action.isPresentedErrorAlert
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
