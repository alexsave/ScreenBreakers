import SwiftUI
import FamilyControls
import DeviceActivity

@MainActor
class ScreenTimeManager: ObservableObject {
    @Published var isPickerPresented = false
    
    // The user’s chosen apps/categories
    @Published var activitySelection = FamilyActivitySelection()
    
    // We'll store a single "daily schedule" with a 1-minute threshold
    private let center = DeviceActivityCenter()
    private let activityName = DeviceActivityName("group.com.alexs.ScreenBreakers.oneMinuteActivity")
    private let eventName = DeviceActivityEvent.Name("group.com.alexs.ScreenBreakers.oneMinuteThresholdEvent")
    
    // Access the shared container
    // MARK: - Request Authorization
    
    func requestAuthorization() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            print("Screen Time authorization granted.")
        } catch {
            print("Failed to request authorization: \(error)")
        }
    }
    
    // MARK: - Store / Load Selection
    
    func storeSelection(_ selection: FamilyActivitySelection) {
        do {
            let data = try PropertyListEncoder().encode(selection)
            UserDefaults.standard.set(data, forKey: "FamilyActivitySelection")
        } catch {
            print("Error encoding selection: \(error)")
        }
    }
    
    func loadSelection() -> FamilyActivitySelection? {
        guard let data = UserDefaults.standard.data(forKey: "FamilyActivitySelection") else {
            return nil
        }
        return try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: data)
    }
    
    // MARK: - Start Monitoring (1-minute threshold)
    
    /// Sets up a daily schedule from 00:00 - 23:59 with a 1-minute threshold.
    /// The extension will increment "accumulated usage" each time the user crosses that minute of usage.
    func startMonitoringOneMinuteThreshold() {
        // Reload selection if available
        if let saved = loadSelection() {
            activitySelection = saved
        }
        
        // Stop any existing monitoring to re-arm
        center.stopMonitoring([activityName])
        
        // A daily schedule
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )
        
        // 1-minute threshold event
        let event = DeviceActivityEvent(
            applications: activitySelection.applicationTokens,
            categories: activitySelection.categoryTokens,
            webDomains: activitySelection.webDomainTokens,
            threshold: DateComponents(minute: 1)
        )
        
        do {
            try center.startMonitoring(
                activityName,
                during: schedule,
                events: [eventName: event]
            )
            print("Started 1-minute threshold monitoring.")
            
            // Reset the shared usage if you want to start fresh daily, or do it in extension
            
        } catch {
            print("Failed to start monitoring: \(error)")
        }
    }
    
}

