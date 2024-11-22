//
//  Navigation.swift
//  Neonov
//
//  Created by Damiano on 20/11/24.
//

import SwiftUI

var Navigation: some View {
    TabView {
        Text("Log")
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
