import ComposableArchitecture
import SwiftUI

struct SelectNetworkView: View {
    let store: Store<SelectNetworkApp.State, SelectNetworkApp.Action>

    var body: some View {
        WithViewStore(store) { viewStore in
            List {
                ForEach(viewStore.state.networks, id: \.id) { network in
                    HStack {
                        VStack {
                            Text(network.displayName)
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        Image(systemName: network.id == viewStore.primaryNetwork.id ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(Color.blue)
                    }
                    .onTapGesture {
                        viewStore.send(.selectNetwork(network))
                    }
                }
            }
            .navigationBarTitle("", displayMode: .inline)
            .onAppear {
                viewStore.send(.fetchNetworks)
            }
        }
    }
}
