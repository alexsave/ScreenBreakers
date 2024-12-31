//
//  UsageMonitorApp.swift
//  UsageMonitor
//
//  Created by You on [Date].
//

import SwiftUI
import SwiftData

@main
struct UsageMonitorApp: App {
    let container: ModelContainer

    init() {
        container = SharedContainer.makeConfiguration()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
