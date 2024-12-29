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
    // detect when the app is launched, and write to core data
    // detect when the app is closed, and write to core data

    // This might be useful later
    init() {
        NotificationCenter.default.addObserver(forName: UIApplication.didFinishLaunchingNotification, object: nil, queue: .main) {
            _ in 
            // write to core data
            print("app launched at \(Date())")
        }

        NotificationCenter.default.addObserver(forName: UIApplication.willTerminateNotification, object: nil, queue: .main) {
            _ in 
            // write to core data
            print("app closed at \(Date())")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(SharedContainer.makeConfiguration()!)
    }
}
