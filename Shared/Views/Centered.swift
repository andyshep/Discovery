//
//  Centered.swift
//  Discovery
//
//  Created by Andrew Shepard on 8/29/20.
//

import SwiftUI

struct Centered<Content: View>: View {
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

struct Centered_Previews: PreviewProvider {
    static var previews: some View {
        Centered {
            Text("Hello World!")
        }
    }
}
