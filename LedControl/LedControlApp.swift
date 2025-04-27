//
//  LedControlApp.swift
//  LedControl
//
//  Created by Mihai on 02.02.2025.
//

import Foundation
import SwiftUI
import SwiftData

@main
struct LedControlApp: App {
    @State private var didTryToConnect = false

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([HomeSettings.self, PresetsSettings.self, BluetoothSettings.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    if !didTryToConnect {
                        // Add a slight delay to ensure the Bluetooth system is ready
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            let modelContext = sharedModelContainer.mainContext
                            AppState.shared.connectToLastDevice(modelContext: modelContext)
                        }
                        didTryToConnect = true
                    }
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
