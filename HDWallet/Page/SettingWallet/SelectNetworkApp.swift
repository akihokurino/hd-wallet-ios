import Combine
import ComposableArchitecture
import Foundation

enum SelectNetworkApp {
    static let reducer = AnyReducer<State, Action, Environment> { state, action, environment in
        switch action {
        case .fetchNetworks:
            state.networks = Network.allCases
            return .none
        case .selectNetwork(let network):
            state.primaryNetwork = network
            Ethereum.shared.changeNetwork(network: network)
            return .none
        }
    }
}

extension SelectNetworkApp {
    enum Action: Equatable {
        case fetchNetworks
        case selectNetwork(Network)
    }

    struct State: Equatable {
        var networks: [Network] = []
        var primaryNetwork: Network
    }

    struct Environment {
        let mainQueue: AnySchedulerOf<DispatchQueue>
        let backgroundQueue: AnySchedulerOf<DispatchQueue>
    }
}
