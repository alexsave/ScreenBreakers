import SwiftUI
import FamilyControls
import DeviceActivity

@MainActor
class ScreenTimeManager: ObservableObject {
    @Published var isPickerPresented = false
    @Published var isAuthorized = false
    
    // The user's chosen apps/categories
    @Published var activitySelection = FamilyActivitySelection()
    
    // We'll store a single "daily schedule" with a 1-minute threshold
    private let center = DeviceActivityCenter()
    private let activityName = DeviceActivityName("group.com.alexs.ScreenBreakers.oneMinuteActivity")
    private let eventName = DeviceActivityEvent.Name("group.com.alexs.ScreenBreakers.oneMinuteThresholdEvent")
    private let defaults = UserDefaults.standard
    private let authorizationKey = "isAuthorized"
    
    init() {
        // Load any saved selection
        if let savedSelection = loadSelection() {
            activitySelection = savedSelection
            // Check saved authorization status
            isAuthorized = defaults.bool(forKey: authorizationKey)
            if isAuthorized {
                startMonitoringOneMinuteThreshold()
            }
        }
    }
    
    func requestAuthorization() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            isAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
            defaults.set(isAuthorized, forKey: authorizationKey)
            print("Screen Time authorization granted.")
        } catch {
            isAuthorized = false
            defaults.set(isAuthorized, forKey: authorizationKey)
            print("Failed to request authorization: \(error)")
        }
    }
    
    func storeSelection(_ selection: FamilyActivitySelection) {
        do {
            let data = try PropertyListEncoder().encode(selection)
            defaults.set(data, forKey: "FamilyActivitySelection")
            isAuthorized = true
            defaults.set(isAuthorized, forKey: authorizationKey)
        } catch {
            print("Error encoding selection: \(error)")
        }
    }
    
    func loadSelection() -> FamilyActivitySelection? {
        guard let data = defaults.data(forKey: "FamilyActivitySelection") else {
            return nil
        }
        return try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: data)
    }
    
    func startMonitoringOneMinuteThreshold() {
        // Store the current selection
        storeSelection(activitySelection)
        
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
        } catch {
            print("Failed to start monitoring: \(error)")
        }
    }
    
}

