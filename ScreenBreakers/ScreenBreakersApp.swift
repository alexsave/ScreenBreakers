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

    // this should be used somewhere else, I think. if we're never going to close the app, we'll have to have some periodic check
    @State private var lastSavedAt: Date?

    // This might be useful later
    init() {
        let manager = UsageMonitorManager.shared
        
        container = SharedContainer.makeConfiguration()
        // set timer to call appCLosed vevery 5 min to sync
        let timer = Timer.scheduledTimer(withTimeInterval: 5*60, repeats: true) {
            _ in
            manager.appClosed()
        }
        NotificationCenter.default.addObserver(forName: UIApplication.didFinishLaunchingNotification, object: nil, queue: .main) {
            _ in
            manager.appLaunched()
        }

        NotificationCenter.default.addObserver(forName: UIApplication.willTerminateNotification, object: nil, queue: .main) {
            _ in
            manager.appClosed()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
