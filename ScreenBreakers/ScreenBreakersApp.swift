//
//  UsageMonitorApp.swift
//  UsageMonitor
//
//  Created by You on [Date].
//

import SwiftUI
import SwiftData

@main
struct ScreenBreakersApp: App {
    let container: ModelContainer
    @StateObject private var deepLinkManager = DeepLinkManager()
    
    init() {
        container = SharedContainer.makeConfiguration()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(deepLinkManager)
                .modelContainer(container)
        }
    }
}
