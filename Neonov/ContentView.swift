//
//  ContentView.swift
//  Neonov
//
//  Created by Damiano on 31/10/24.
//

import SwiftUI
import CoreNFC

struct ContentView: View {
    @State private var NFCR = NFCReader()
    @State public var showingAlert = false
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        Navigation
        .padding()
    }
}

#Preview {
    ContentView()
}
