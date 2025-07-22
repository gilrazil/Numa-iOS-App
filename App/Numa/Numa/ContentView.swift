//
//  ContentView.swift
//  Numa
//
//  Created by GIl Raz on 21/07/2025.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text(LocalizedStringKey("hello_world"))
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
