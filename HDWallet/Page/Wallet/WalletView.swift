import ComposableArchitecture
import SwiftUI

struct WalletView: View {
    let store: Store<WalletApp.State, WalletApp.Action>

    var body: some View {
        WithViewStore(store) { viewStore in
            ZStack(alignment: .bottom) {
                List {
                    VStack(alignment: .center) {
                        Text(viewStore.account.name).font(.headline)
                        Spacer().frame(height: 20)
                        Text("\(viewStore.state.balance) \(viewStore.state.network.displayUnitName)")
                            .font(.largeTitle)
                            .frame(
                                minWidth: 0,
                                maxWidth: .infinity,
                                minHeight: 80,
                                maxHeight: 80,
                                alignment: .center
                            )
                            .background(Color.blue)
                            .foregroundColor(Color.white)
                            .cornerRadius(5.0)
                            .padding(20)
                        Spacer().frame(height: 20)
                        Text(viewStore.account.address.address).font(.caption)
                        Spacer().frame(height: 40)
                        HStack(alignment: .center, spacing: 40) {
                            Button(action: {}) {
                                VStack {
                                    Image(systemName: "arrow.down.circle.fill")
                                        .resizable()
                                        .frame(width: 30, height: 30)
                                        .foregroundColor(Color.blue)
                                        .background(Color.white)
                                        .cornerRadius(15)
                                    Spacer().frame(height: 10)
                                    Text("Receive")
                                        .foregroundColor(Color.blue)
                                        .font(.subheadline)
                                }
                            }
                            .disabled(true)
                            .buttonStyle(PlainButtonStyle())

                            Button(action: {
                                viewStore.send(.isPresentedSendEtherView(true))
                            }) {
                                VStack {
                                    Image(systemName: "arrow.up.forward.circle.fill")
                                        .resizable()
                                        .frame(width: 30, height: 30)
                                        .foregroundColor(Color.blue)
                                        .background(Color.white)
                                        .cornerRadius(15)
                                    Spacer().frame(height: 10)
                                    Text("Send")
                                        .foregroundColor(Color.blue)
                                        .font(.subheadline)
                                }
                            }
                            .disabled(viewStore.balance.isEmpty)
                            .buttonStyle(PlainButtonStyle())
                        }
                        .frame(
                            minWidth: 0,
                            maxWidth: .infinity,
                            minHeight: 80,
                            maxHeight: 80,
                            alignment: .center
                        )
                    }
                    .frame(
                        minWidth: 0,
                        maxWidth: .infinity
                    )
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets())
                    .padding(.vertical, 20)
                }
                .listStyle(PlainListStyle())

                if let privateKey = viewStore.exportedPrivateKey {
                    HStack {
                        Text(privateKey).font(.caption)
                            .padding(.horizontal, 10)
                        Spacer()
                        Image(systemName: "xmark.circle.fill")
                            .padding(.horizontal, 10)
                            .onTapGesture {
                                viewStore.send(.hideExportedPrivateKey)
                            }
                    }
                    .frame(
                        minWidth: 0,
                        maxWidth: .infinity,
                        minHeight: 50,
                        maxHeight: 50,
                        alignment: .center
                    )
                    .background(Color.green)
                    .foregroundColor(Color.white)
                    .cornerRadius(5.0)
                    .padding(15)
                }
            }
            .navigationBarTitle("\(viewStore.network.displayName) Network", displayMode: .inline)
            .navigationBarItems(trailing: Button(action: {
                viewStore.send(.isPresentedMenu(true))
            }) {
                Image(systemName: "ellipsis")
            })
            .actionSheet(isPresented: viewStore.binding(
                get: { $0.isPresentedMenu },
                send: WalletApp.Action.isPresentedMenu
            )) {
                ActionSheet(title: Text(""), buttons:
                    [
                        .default(Text("Select Account")) {
                            viewStore.send(.isPresentedSelectAccountView(true))
                        },
                        .default(Text("Select Network")) {
                            viewStore.send(.isPresentedSelectNetworkView(true))
                        },
                        .default(Text("Import Key")) {
                            viewStore.send(.isPresentedImportWalletView(true))
                        },
                        .default(Text("Export Key")) {
                            viewStore.send(.startExportPrivateKey)
                        },
                        .destructive(Text("Reset")) {
                            viewStore.send(.reset)
                        },
                        .cancel(),
                    ])
            }
            .onAppear {
                viewStore.send(.startInit)
            }
            .overlay(
                Group {
                    if viewStore.state.isPresentedHUD {
                        HUD(isLoading: viewStore.binding(
                            get: { $0.isPresentedHUD },
                            send: WalletApp.Action.isPresentedHUD
                        ))
                    }
                }, alignment: .center
            )
            .refreshable {
                await viewStore.send(.startRefresh, while: { $0.isPresentedPTR })
            }
            .sheet(isPresented: viewStore.binding(
                get: { $0.isPresentedSelectAccountView },
                send: WalletApp.Action.isPresentedSelectAccountView
            ), content: {
                IfLetStore(
                    store.scope(
                        state: { $0.selectAccountState },
                        action: WalletApp.Action.selectAccountAction
                    ),
                    then: SelectAccountView.init(store:)
                )
            })
            .sheet(isPresented: viewStore.binding(
                get: { $0.isPresentedSelectNetworkView },
                send: WalletApp.Action.isPresentedSelectNetworkView
            ), content: {
                IfLetStore(
                    store.scope(
                        state: { $0.selectNetworkState },
                        action: WalletApp.Action.selectNetworkAction
                    ),
                    then: SelectNetworkView.init(store:)
                )
            })
            .sheet(isPresented: viewStore.binding(
                get: { $0.isPresentedImportWalletView },
                send: WalletApp.Action.isPresentedImportWalletView
            ), content: {
                IfLetStore(
                    store.scope(
                        state: { $0.importWalletState },
                        action: WalletApp.Action.importWalletAction
                    ),
                    then: ManageKeyView.init(store:)
                )
            })
            .navigate(
                using: store.scope(
                    state: { $0.sendEtherState },
                    action: WalletApp.Action.sendEtherAction
                ),
                destination: SendEtherView.init(store:),
                onDismiss: {
                    ViewStore(store.stateless).send(.isPresentedSendEtherView(false))
                }
            )
            .alert(
                viewStore.error?.alert.title ?? "",
                isPresented: viewStore.binding(
                    get: { $0.isPresentedErrorAlert },
                    send: WalletApp.Action.isPresentedErrorAlert
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
