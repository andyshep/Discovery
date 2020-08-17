//
//  ColumnAppScene.swift
//  Discovery (iOS)
//
//  Created by Andrew Shepard on 8/29/20.
//

import SwiftUI

struct ColumnAppScene: Scene {
    @ObservedObject var store: AppStore
    
    var body: some Scene {
        WindowGroup {
            WindowContainerView()
                .environmentObject(store)
            .navigationViewStyle(DoubleColumnNavigationViewStyle())
            .presentedWindowToolbarStyle(UnifiedCompactWindowToolbarStyle())
            .presentedWindowStyle(HiddenTitleBarWindowStyle())
        }
    }
}

//struct ColumnAppScene_Previews: PreviewProvider {
//    static var previews: some Scene {
//        ColumnAppScene()
//    }
//}
