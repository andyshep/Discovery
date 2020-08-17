//
//  ServiceViews.swift
//  Discovery
//
//  Created by Andrew Shepard on 8/29/20.
//

import SwiftUI

struct ContainerView: View {
    @EnvironmentObject var store: AppStore
    
    var body: some View {
        Group {
            ServiceListView(
                selection: store.binding(for: \.selected, transform: { .select(service: $0) } ),
                services: store.state.services
            )
            if let service = store.state.selected {
                ServiceView(payload: service.payload)
            } else {
                Text("Select a service")
            }
        }
        .onAppear {
            store.send(.discoverServices)
        }
    }
}

struct ServiceListView: View {
    @EnvironmentObject var store: AppStore
    @Binding var selection: SSDPServiceWrapper?
    
    let services: [SSDPServiceWrapper]
    
    var body: some View {
        VStack {
            List(services, id: \.self, selection: $selection) { service in
//                NavigationLink(destination: ServiceView(payload: service.payload)) {
                    Text(service.service.uniqueServiceName)
                        .padding(4)
//                }
            }
            .listStyle(PlainListStyle())
            StatusView(label: "\(services.count) services")
        }
    }
}

struct ServiceView: View {
    let payload: String
 
    var body: some View {
        Divider()
            .padding(0)
        VStack {
            HStack {
                Text(payload)
                    .font(.system(.body, design: .monospaced))
                Spacer()
            }
            Spacer()
        }
        .padding(16)
    }
}
