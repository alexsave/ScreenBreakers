import DeviceActivity
import Foundation
import os.log

class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    
    private let center = DeviceActivityCenter()
    private let activityName = DeviceActivityName("group.com.alexs.ScreenBreakers.oneMinuteActivity")
    private let eventName = DeviceActivityEvent.Name("group.com.alexs.ScreenBreakers.oneMinuteThresholdEvent")

    // Access the shared defaults in the extension
    private let sharedDefaults = UserDefaults(suiteName: "group.com.alexs.ScreenBreakers")

    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        
        guard event == eventName, activity == activityName else { return }
        
        // 1) Increment the "accumulated usage" by 1 minute
        let current = sharedDefaults?.integer(forKey: "accumulatedUsageMinutes") ?? 0
        let updated = current + 1
        sharedDefaults?.set(updated, forKey: "accumulatedUsageMinutes")
        
        os_log("1-minute threshold hit. Updated usage to: %d minutes", updated)
        
        // 2) Re-arm the threshold by stopping + starting monitoring again
        //    so we can catch the next minute.
        do {
            // First, stop monitoring for the current activity
            center.stopMonitoring([activityName])
            
            // Re-configure the same daily schedule
            let schedule = DeviceActivitySchedule(
                intervalStart: DateComponents(hour: 0, minute: 0),
                intervalEnd: DateComponents(hour: 23, minute: 59),
                repeats: true
            )
            
            // Create the 1-minute threshold event again
            // (In real usage, you might read from shared config if needed)
            let event = DeviceActivityEvent(
                applications: [],     // If you can store tokens in shared defaults, retrieve them here
                categories: [],
                webDomains: [],
                threshold: DateComponents(minute: 1)
            )
            
            // The big question: do we have the user's actual tokens? 
            // The extension typically doesn't know which apps the user selected. 
            // => Option 1: Store the user's FamilyActivitySelection tokens in shared defaults too 
            // => Option 2: Just re-arm an "all apps" or blank set. 
            
            // For simplicity, let's assume we only track the *exact tokens* if you stored them in shared defaults:
            // let savedAppsData = sharedDefaults?.data(forKey: "selectedApps")
            // decode to FamilyActivitySelection, if needed, then fill in the event. 
            // Below is a simple skeleton.
            
            try center.startMonitoring(
                activityName,
                during: schedule,
                events: [eventName: event]
            )
            
            os_log("Re-armed 1-minute threshold monitoring after incrementing usage.")
        } catch {
            os_log("Error re-arming threshold: %{public}@", "\(error)")
        }
    }
}

