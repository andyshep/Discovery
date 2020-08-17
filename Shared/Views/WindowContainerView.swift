//
//  WindowContainerView.swift
//  Discovery (iOS)
//
//  Created by Andrew Shepard on 8/29/20.
//

import SwiftUI

struct WindowContainerView: View {
    @EnvironmentObject var store: AppStore
    
    var body: some View {
        NavigationView {
            ContainerView()
        }
        .toolbar(content: {
            ToolbarItem {
                Button {
                    store.send(.share)
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .labelStyle(IconOnlyLabelStyle())
                }
//                .sheet(
//                    item: store.binding(for: \.selected, transform: { .select(service: $0) } ),
//                    content: { (item) in
//                        Text("testing")
//                    }
//                )
                .disabled(store.state.selected == nil)
            }
            ToolbarItem {
                Button {
                    store.send(.refresh)
                } label: {
                    Label("Reload", systemImage: "arrow.counterclockwise")
                        .labelStyle(IconOnlyLabelStyle())
                }
            }
        })
    }
}


//struct WindowContainerView_Previews: PreviewProvider {
//    static var previews: some View {
//        WindowContainerView()
//    }
//}
