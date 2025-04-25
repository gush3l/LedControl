//
//  ContentView.swift
//  LedControl
//
//  Created by Mihai on 02.02.2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showInfoDialog: Bool = false

    var body: some View {
        TabView {
            NavigationView {
                HomeView()
                    .navigationTitle("Home")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: {
                                showInfoDialog = true
                            }) {
                                Image(systemName: "info.circle.fill")
                                    .font(.title3)
                            }
                        }
                    }
                    .alert(isPresented: $showInfoDialog) {
                        Alert(
                            title: Text("Information"),
                            message: Text("Choose a color for your lights using the sliders below.\nTap on the colored rectangle to save the color to your recent colors list.\nYou can change the brightness of your lights using the brightness slider.\nIf you want to turn off the lights use the toggle lights slider."),
                            dismissButton: .default(Text("Close"))
                        )
                    }
            }
            .tabItem {
                Image(systemName: "house.fill")
                Text("Home")
            }
            .tag(0)
            
            NavigationView {
                PresetsView()
                    .navigationTitle("Presets")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: {
                                showInfoDialog = true
                            }) {
                                Image(systemName: "info.circle.fill")
                                    .font(.title3)
                            }
                        }
                    }
                    .alert(isPresented: $showInfoDialog) {
                        Alert(
                            title: Text("Information"),
                            message: Text("Choose a light preset from the list below. Adjust the speed and the brightness using the sliders."),
                            dismissButton: .default(Text("Close"))
                        )
                    }
            }
            .tabItem {
                Image(systemName: "light.max")
                Text("Presets")
            }
            .tag(1)
            
            NavigationView {
                BluetoothView()
            }
            .tabItem {
                Image(systemName: "lightswitch.on.square")
                Text("Devices")
            }
            .tag(2)
        }
    }

}

#Preview {
    ContentView()
}
