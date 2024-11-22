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
            Button("Scan pen") {
                NFCR.read()
            }
            Text("NFC data: \(NFCR.raw)")
        }
        .alert("NFC data: \(NFCR.raw)", isPresented: $NFCR.showAlert) {
            Button("OK", role: .cancel) { }
        }
        Navigation
        .padding()
    }
}

#Preview {
    ContentView()
}
