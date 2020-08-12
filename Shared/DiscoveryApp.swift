//
//  DiscoveryApp.swift
//  Shared
//
//  Created by Andrew Shepard on 8/7/20.
//

import SwiftUI

@main
struct DiscoveryApp: App {
    
    private let store = AppStore(
        initial: .init(),
        reducer: appReducer,
        environment: AppEnvironment()
    )

    var body: some Scene {
        WindowGroup {
            NavigationView {
                ServiceListContainer()
                    .environmentObject(store)
            }
            .toolbar(items: {
                ToolbarItem {
                    Button {
                        store.send(.refresh)
                    } label: {
                        Label("Reload", systemImage: "arrow.counterclockwise")
                            .labelStyle(IconOnlyLabelStyle())
                    }

                }
            })
            .navigationViewStyle(DoubleColumnNavigationViewStyle())
            .presentedWindowToolbarStyle(UnifiedCompactWindowToolbarStyle())
            .presentedWindowStyle(HiddenTitleBarWindowStyle())
        }
    }
}
