//
//  ContentView.swift
//  Shared
//
//  Created by Andrew Shepard on 8/7/20.
//

import SwiftUI

struct StatusView: View {
    var label: String
    
    var body: some View {
        Text(label)
            .font(.subheadline)
            .frame(height: 26)
    }
}

struct StatusView_Previews: PreviewProvider {
    static var previews: some View {
        StatusView(label: "20 records found")
    }
}

struct LoadingView: View {
    var body: some View {
        Centered {
            Text("Loading...")
        }
    }
}

struct ErrorView: View {
    let error: Error
    
    var body: some View {
        Centered {
            Text("Error: \(error.localizedDescription)")
        }
    }
}
