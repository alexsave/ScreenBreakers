import DeviceActivity
import SwiftData
import Foundation
import os.log

@MainActor
class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    
    private let center = DeviceActivityCenter()
    private let activityName = DeviceActivityName("group.com.alexs.ScreenBreakers.oneMinuteActivity")
    private let eventName = DeviceActivityEvent.Name("group.com.alexs.ScreenBreakers.oneMinuteThresholdEvent")
    
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        
        guard event == eventName, activity == activityName else {
            os_log("Event or activity mismatch. Ignoring.")
            return
        }
        
        os_log("1-minute threshold reached for activity: %{public}@", activity.rawValue)
        
        Task {
            await updateAccumulatedUsage()
            await rearmThreshold()
        }
    }
    
    /// Updates the accumulated usage in the shared SwiftData database
    private func updateAccumulatedUsage() async {
        //await MainActor.run {
            do {
                let today = Calendar.current.startOfDay(for: Date())
                let fetchDescriptor = FetchDescriptor<DailyActivity>(
                    predicate: #Predicate { $0.date == today }
                )
                
                let container = try SharedContainer.makeConfiguration()

                if container == nil{
                    os_log("model context is nil")
                    return
                }
                let context = container.mainContext
                
                let existingData = try context.fetch(fetchDescriptor).first
                if let data = existingData {
                    data.totalScreenMinutes += 1
                    os_log("Updated accumulated usage to: %f minutes", data.totalScreenMinutes)
                } else {
                    // must be new
                    let newData = DailyActivity(date: today, totalScreenMinutes: 1, totalMonitoringMinutes: 0)
                    context.insert(newData)
                    os_log("Created new activity record with 1 minute.")
                }
                //} catch {
                //os_log("fetch error \(error)")
                //}
                
                // Save the changes to the SwiftData store
                try context.save()
            } catch {
                os_log("Failed to update accumulated usage: %{public}@", "\(error)")
            }
        //}
    }
    
    /// Rearms the 1-minute threshold by stopping and restarting monitoring
    private func rearmThreshold() async {
        do {
            // Stop monitoring the current activity
            center.stopMonitoring([activityName])
            
            // Configure the daily monitoring schedule
            let schedule = DeviceActivitySchedule(
                intervalStart: DateComponents(hour: 0, minute: 0),
                intervalEnd: DateComponents(hour: 23, minute: 59),
                repeats: true
            )
            
            // Create the 1-minute threshold event
            let event = DeviceActivityEvent(
                applications: [],
                categories: [],
                webDomains: [],
                threshold: DateComponents(minute: 1)
            )
            
            // Restart monitoring with the rearmed event
            try center.startMonitoring(
                activityName,
                during: schedule,
                events: [eventName: event]
            )
            
            os_log("Rearmed 1-minute threshold monitoring.")
        } catch {
            os_log("Error re-arming threshold: %{public}@", "\(error)")
        }
    }
}

