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
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([HomeSettings.self, PresetsSettings.self])
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
        }
        .modelContainer(sharedModelContainer)

    }
}
