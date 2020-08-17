//
//  DiscoveryApp.swift
//  Shared
//
//  Created by Andrew Shepard on 8/7/20.
//

import SwiftUI

@main
struct DiscoveryApp: App {
    
    @StateObject private var store = AppStore(
        initial: .init(),
        reducer: appReducer,
        environment: AppEnvironment()
    )

    var body: some Scene {
        ColumnAppScene(store: store)
    }
}
