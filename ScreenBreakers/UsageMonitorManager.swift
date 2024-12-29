import Foundation
import SwiftData

class UsageMonitorManager {
    static let shared = UsageMonitorManager()
    private var lastSavedAt: Date?
    let container: ModelContainer

    private init() {
        container = SharedContainer.makeConfiguration()
    }

    @MainActor func appLaunched() {
        lastSavedAt = Date()
        print("App launched at \(Date())")
        // Perform operations for app launch
        let today = Calendar.current.startOfDay(for: Date())
        let lastDailyActivity = try? container.mainContext.fetch(FetchDescriptor<DailyActivity>(
            predicate: #Predicate { $0.date == today }
        )).first

        if lastDailyActivity == nil {
            let newDailyActivity = DailyActivity(date: today, totalScreenMinutes: 0, totalMonitoringMinutes: 0)
            container.mainContext.insert(newDailyActivity)
        }
        try? container.mainContext.save()
    }

    @MainActor func appClosed() {
        let now = Date()
        print("App closed at \(now)")
        guard let lastSavedAt = lastSavedAt else { return }
        let today = Calendar.current.startOfDay(for: now)
        let lastDailyActivity = try? container.mainContext.fetch(FetchDescriptor<DailyActivity>(
            predicate: #Predicate { $0.date == today }
        )).first

        if let activity = lastDailyActivity {
            activity.totalMonitoringMinutes += now.timeIntervalSince(lastSavedAt) / 60
        } else {
            let newDailyActivity = DailyActivity(
                date: today,
                totalScreenMinutes: 0,
                totalMonitoringMinutes: now.timeIntervalSince(lastSavedAt) / 60
            )
            container.mainContext.insert(newDailyActivity)
        }
        try? container.mainContext.save()
        self.lastSavedAt = now
    }
}

