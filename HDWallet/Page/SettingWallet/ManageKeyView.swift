import ComposableArchitecture
import SwiftUI

struct ManageKeyView: View {
    let store: Store<ManageKeyApp.State, ManageKeyApp.Action>

    var body: some View {
        WithViewStore(store) { viewStore in
            NavigationView {
                List {
                    Spacer().frame(height: 20)
                        .listRowSeparator(.hidden)
                    
                    VStack {
                        Text("A mnemonic code. Do not forget to keep it.")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Spacer().frame(height: 10)
                        
                        Text(viewStore.mnemonics)
                            .font(.subheadline)
                            .frame(
                                minWidth: 0,
                                maxWidth: .infinity,
                                alignment: .leading
                            )
                    }
                    
                    Spacer().frame(height: 20)
                        .listRowSeparator(.hidden)
                    
                    VStack {
                        Text("Generate a private key. The generated private key is stored in the app.")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Spacer().frame(height: 10)
                        
                        ActionButton(text: "Generate", buttonType: .primary, action: {
                            viewStore.send(.startGenPrivateKey(false))
                        })
                    }
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets())
                    .padding(.horizontal, 15)
                    
                    Spacer().frame(height: 20)
                        .listRowSeparator(.hidden)
                    
                    VStack {
                        Text("Import your private key. The imported private key is stored in the app.")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Spacer().frame(height: 10)
                        
                        TextFieldView(value: viewStore.binding(
                            get: { $0.inputPrivateKey },
                            send: ManageKeyApp.Action.inputPrivateKey
                        ), label: "", placeholder: "private key...", keyboardType: .emailAddress)
                        Spacer().frame(height: 10)
                        
                        ActionButton(text: "Import", buttonType: .primary, action: {
                            viewStore.send(.startGenPrivateKey(true))
                        })
                    }
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets())
                    .padding(.horizontal, 15)
                    
                    Spacer().frame(height: 20)
                        .listRowSeparator(.hidden)
                    
                    VStack {
                        Text("Recover private key from mnemonic.")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Spacer().frame(height: 10)
                                            
                        HStack {
                            TextFieldView(value: viewStore.binding(
                                get: { $0.inputMnemonics },
                                send: ManageKeyApp.Action.inputMnemonics
                            ), label: "", placeholder: "patrol moment olive ...", keyboardType: .emailAddress)
                            TextFieldView(value: viewStore.binding(
                                get: { $0.inputRestoreAccountNum },
                                send: ManageKeyApp.Action.inputRestoreAccountNum
                            ), label: "", placeholder: "1", keyboardType: .numberPad)
                            .frame(width: 100)
                        }
                        Spacer().frame(height: 10)
                                            
                        ActionButton(text: "Restore", buttonType: .alert, action: {
                            viewStore.send(.startRestorePrivateKey)
                        })
                    }
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets())
                    .padding(.horizontal, 15)
                }
                .listStyle(PlainListStyle())
                .navigationBarTitle("", displayMode: .inline)
                .onAppear {
                    viewStore.send(.startInit)
                }
                .overlay(
                    Group {
                        if viewStore.state.isPresentedHUD {
                            HUD(isLoading: viewStore.binding(
                                get: { $0.isPresentedHUD },
                                send: ManageKeyApp.Action.isPresentedHUD
                            ))
                        }
                    }, alignment: .center
                )
                .alert(
                    viewStore.error?.alert.title ?? "",
                    isPresented: viewStore.binding(
                        get: { $0.isPresentedErrorAlert },
                        send: ManageKeyApp.Action.isPresentedErrorAlert
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
}
