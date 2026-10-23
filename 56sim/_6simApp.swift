//
//  _6simApp.swift
//  56sim
//
//  Created by Reka Papp on 2026-10-23.
//

import SwiftData
import SwiftUI

@main
struct _6simApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Citizen.self,
            Broadcast.self,
            Report.self,
            RecordAmendment.self,
        ])
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
                .task {
                    // Setup-time download of every model the republic relies on:
                    // the Piper voice (60 MB) and the LFM2.5 interrogator (628 MB).
                    PiperAnnouncer.shared.prefetch()
                    InterrogationEngine.prefetchWeights()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
