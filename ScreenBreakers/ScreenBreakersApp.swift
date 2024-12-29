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
            
            // write to core data
            /*self.lastSavedAt = Date()
            print("app launched at \(Date())")*/
            // retrieve last DailyActivity
            /*let lastDailyActivity = try? container.mainContext.fetch(FetchDescriptor<DailyActivity>(
                predicate: #Predicate { $0.date == today }
            )).first
            print("lastDailyActivity: \(lastDailyActivity)")

            if lastDailyActivity == nil {
                // create new DailyActivity
                let newDailyActivity = DailyActivity(date: today, totalScreenMinutes: 0)
                container.mainContext.insert(newDailyActivity)
            }*/
        }

        NotificationCenter.default.addObserver(forName: UIApplication.willTerminateNotification, object: nil, queue: .main) {
            _ in
            manager.appClosed()
            // write to core data
            /*print("app closed at \(Date())")
            let now = Date()
            let today = Calendar.current.startOfDay(for: now)
            let lastDailyActivity = try? container.mainContext.fetch(FetchDescriptor<DailyActivity>(
                predicate: #Predicate { $0.date == today }
            )).first
            print("lastDailyActivity: \(lastDailyActivity)")
            if lastDailyActivity != nil {
                lastDailyActivity?.totalMonitoringMinutes += now.timeIntervalSince(lastSavedAt!) / 60
                //container.mainContext.insert(lastDailyActivity)
            } else {
                // this should reset lastSavedAt
                let newDailyActivity = DailyActivity(date: today, totalScreenMinutes: 0, totalMonitoringMinutes: now.timeIntervalSince(lastSavedAt ?? now) / 60)
                container.mainContext.insert(newDailyActivity)
            }
            // save
            try? container.mainContext.save()
            lastSavedAt = now*/
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
