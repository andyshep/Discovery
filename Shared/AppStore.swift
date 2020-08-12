//
//  AppState.swift
//  Discovery
//
//  Created by Andrew Shepard on 8/12/20.
//

import Foundation
import Combine

struct AppState {
    var services: [SSDPServiceWrapper] = []
    var selected: SSDPServiceWrapper?
    var error: Error?
}

enum AppAction {
    case discoverServices
    case setServices(services: [SSDPServiceWrapper])
    case refresh
}

typealias Reducer<State, Action, Environment> =
    (inout State, Action, Environment) -> AnyPublisher<Action, Never>?

typealias AppStore = Store<AppState, AppAction, AppEnvironment>

final class Store<State, Action, Environment>: ObservableObject {
    @Published private(set) var state: State
    
    private let reducer: Reducer<State, Action, Environment>
    private let environment: Environment
    
    private var cancellables: Set<AnyCancellable> = []
    
    init(initial state: State,
         reducer: @escaping Reducer<State, Action, Environment>,
         environment: Environment) {
        self.state = state
        self.reducer = reducer
        self.environment = environment
    }

    func send(_ action: Action) {
        guard let effect = reducer(&state, action, environment) else {
            return
        }

        effect
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: send)
            .store(in: &cancellables)
    }
}

func appReducer(
    state: inout AppState,
    action: AppAction,
    environment: AppEnvironment
) -> AnyPublisher<AppAction, Never>? {
    switch action {
    case .discoverServices:
        return environment.discoveredServicesPublisher()
            .throttle(for: 2.0, scheduler: DispatchQueue.main, latest: true)
            .replaceError(with: [])
            .map { AppAction.setServices(services: $0) }
            .eraseToAnyPublisher()
    case .setServices(let services):
        state.services = services
        
    case .refresh:
        state.services = []
        return Just(())
            .map { AppAction.discoverServices }
            .eraseToAnyPublisher()
    }
    
    return nil
}
