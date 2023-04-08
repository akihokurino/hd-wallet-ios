import ComposableArchitecture
import SwiftUI

struct SendEtherView: View {
    let store: Store<SendEtherApp.State, SendEtherApp.Action>

    var body: some View {
        WithViewStore(store) { viewStore in
            VStack {
                HStack {
                    Text("From:")
                        .font(.subheadline)
                        .frame(width: 60, alignment: .leading)
                    Spacer().frame(width: 10)
                    VStack(alignment: .leading) {
                        Text(viewStore.account.name)
                            .font(.subheadline)
                        Spacer().frame(height: 10)
                        Text("Balance: \(viewStore.balance) \(viewStore.network.displayUnitName)")
                            .font(.subheadline)
                    }

                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding(10)

                HStack {
                    Text("To:")
                        .font(.subheadline)
                        .frame(width: 60, alignment: .leading)
                    Spacer().frame(width: 10)
                    TextFieldView(value: viewStore.binding(
                        get: { $0.inputToAddress?.address ?? "" },
                        send: SendEtherApp.Action.inputToAddress
                    ), label: "", placeholder: "0x00...", keyboardType: .emailAddress)

                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding(10)

                HStack {
                    Text("Amount:")
                        .font(.subheadline)
                        .frame(width: 60, alignment: .leading)
                    Spacer().frame(width: 10)
                    TextFieldView(value: viewStore.binding(
                        get: { $0.inputAmount },
                        send: SendEtherApp.Action.inputAmount
                    ), label: "", placeholder: "0.1", keyboardType: .decimalPad)

                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding(10)

                Spacer()

                ActionButton(text: "Send", buttonType: .primary, action: {
                    viewStore.send(.startSend)
                })
                    .padding(10)
            }
            .navigationBarTitle("", displayMode: .inline)
            .onAppear {}
            .overlay(
                Group {
                    if viewStore.state.isPresentedHUD {
                        HUD(isLoading: viewStore.binding(
                            get: { $0.isPresentedHUD },
                            send: SendEtherApp.Action.isPresentedHUD
                        ))
                    }
                }, alignment: .center
            )
            .alert(
                viewStore.error?.alert.title ?? "",
                isPresented: viewStore.binding(
                    get: { $0.isPresentedErrorAlert },
                    send: SendEtherApp.Action.isPresentedErrorAlert
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
