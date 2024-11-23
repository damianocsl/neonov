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
    
    func readNfc() {
        NFCR.read()
    }
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: readNfc) {
                    Image(systemName: "wave.3.right")
                }
            }
            TabView {
                Text("NFC data: \(NFCR.raw)")
                    .tabItem {
                        Image(systemName: "syringe")
                        Text("Log")
                    }
                Text("Settings")
                    .tabItem {
                        Image(systemName: "gearshape")
                        Text("Settings")
                    }
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
