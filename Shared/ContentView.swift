//
//  ContentView.swift
//  Shared
//
//  Created by Andrew Shepard on 8/7/20.
//

import SwiftUI

struct ServiceListContainer: View {
    @EnvironmentObject var store: AppStore
    
    @ViewBuilder
    var body: some View {
        Group {
            return ServiceListView(services: store.state.services)
        }
        .onAppear {
            store.send(.discoverServices)
        }
    }
}

struct ServiceListView: View {
    @EnvironmentObject var store: AppStore
    
    @State var selection: SSDPServiceWrapper?
    
    let services: [SSDPServiceWrapper]
    
    var body: some View {
        VStack {
            List(services, id: \.self, selection: $selection) { service in
                NavigationLink(destination: ServiceView(payload: service.payload)) {
                    Text(service.service.uniqueServiceName)
                        .padding(4)
                }
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
        .background(Color.white)
    }
}

struct StatusView: View {
    var label: String
    
    var body: some View {
        Text(label)
            .font(.subheadline)
            .frame(height: 26)
    }
}

struct LoadingView: View {
    var body: some View {
        CenteredView {
            Text("Loading...")
        }
    }
}

struct ErrorView: View {
    let error: Error
    
    var body: some View {
        CenteredView {
            Text("Error: \(error.localizedDescription)")
        }
    }
}

struct CenteredView<Content: View>: View {
    private let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                content
                Spacer()
            }
            Spacer()
        }
    }
}
