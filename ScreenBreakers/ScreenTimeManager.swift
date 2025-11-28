import SwiftUI
import FamilyControls
import DeviceActivity

 replicate last nights problem by creating a user whose last daily_usage is from yesterday, and hasn't opened the app today
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
    private let selectionKey = "FamilyActivitySelection"
    
    init() {
        // Check current authorization status and saved status
        let currentStatus = AuthorizationCenter.shared.authorizationStatus == .approved
        let savedStatus = defaults.bool(forKey: authorizationKey)
        isAuthorized = currentStatus || savedStatus
        
        // Load any saved selection
        if let savedSelection = loadSelection() {
            activitySelection = savedSelection
            if isAuthorized {
                startMonitoringOneMinuteThreshold()
            }
        }
    }
    
    func requestAuthorization() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            isAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
            
            if isAuthorized {
                // Save authorization status
                defaults.set(true, forKey: authorizationKey)
                // Show picker immediately after authorization
                isPickerPresented = true
            }
            
            print("Screen Time authorization status: \(isAuthorized)")
        } catch {
            isAuthorized = false
            defaults.set(false, forKey: authorizationKey)
            print("Failed to request authorization: \(error)")
        }
    }
    
    func selectionDidComplete(_ selection: FamilyActivitySelection) {
        print("Selection completed with \(selection.applicationTokens.count) apps")
        storeSelection(selection)
        startMonitoringOneMinuteThreshold()
    }
    
    private func storeSelection(_ selection: FamilyActivitySelection) {
        do {
            let data = try PropertyListEncoder().encode(selection)
            defaults.set(data, forKey: selectionKey)
            print("Stored selection successfully")
        } catch {
            print("Error encoding selection: \(error)")
        }
    }
    
    private func loadSelection() -> FamilyActivitySelection? {
        guard let data = defaults.data(forKey: selectionKey) else {
            print("No saved selection found")
            return nil
        }
        do {
            let selection = try PropertyListDecoder().decode(FamilyActivitySelection.self, from: data)
            print("Loaded selection with \(selection.applicationTokens.count) apps")
            return selection
        } catch {
            print("Error decoding selection: \(error)")
            return nil
        }
    }
    
    func startMonitoringOneMinuteThreshold() {
        print("Starting monitoring with \(activitySelection.applicationTokens.count) apps")
        
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

