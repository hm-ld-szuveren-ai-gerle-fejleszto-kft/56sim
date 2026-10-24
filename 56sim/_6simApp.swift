//
//  _6simApp.swift
//  56sim
//
//  Created by Reka Papp on 2026-10-23.
//

import SwiftUI

@main
struct _6simApp: App {
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
    }
}
