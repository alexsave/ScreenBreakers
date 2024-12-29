//
//  ScreenTimeManager.swift
//  ScreenBreakers
//
//  Created by Alex Saveliev on 12/29/24.
//

import Foundation
import FamilyControls
import DeviceActivity
import Combine
import SwiftUI

@MainActor
class ScreenTimeManager: ObservableObject {
    
    // For presenting the Family Activity Picker
    @Published var isPickerPresented: Bool = false
    
    // Stores the user’s chosen apps/categories
    @Published var activitySelection: FamilyActivitySelection = FamilyActivitySelection()
    
    private let center = DeviceActivityCenter()
    private let activityName = DeviceActivityName("com.example.usageMonitor.dailyActivity")
    private let eventName = DeviceActivityEvent.Name("com.example.usageMonitor.thresholdEvent")
    
    // MARK: - Request Authorization
    
    /// Requests authorization to monitor usage on this same device (not a child device).
    func requestAuthorization() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            print("Screen Time authorization granted.")
        } catch {
            print("Error requesting Screen Time authorization: \(error)")
        }
    }
    
    // MARK: - Save / Load Selection
    
    /// Optionally persist the user's FamilyActivitySelection in UserDefaults
    func storeSelection(_ selection: FamilyActivitySelection) {
        do {
            let data = try PropertyListEncoder().encode(selection)
            UserDefaults.standard.set(data, forKey: "SelectedFamilyActivity")
        } catch {
            print("Failed to store selection: \(error)")
        }
    }
    
    /// Retrieve a stored FamilyActivitySelection from UserDefaults
    func loadSelection() -> FamilyActivitySelection? {
        guard let data = UserDefaults.standard.data(forKey: "SelectedFamilyActivity") else {
            return nil
        }
        return try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: data)
    }
    
    // MARK: - Start Monitoring
    
    /// Schedules daily monitoring from midnight to 23:59 with an optional threshold event.
    func startDailyMonitoring(thresholdMinutes: Int) {
        // Load any previously saved selection
        if let saved = loadSelection() {
            activitySelection = saved
        }
        
        // Stop existing monitoring (optional, if you need a fresh start)
        center.stopMonitoring([activityName])
        
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0, second: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59, second: 59),
            repeats: true,
            warningTime: DateComponents(minute: 1) // optional 1-min warning
        )
        
        // Create an event that triggers at 'thresholdMinutes' of usage 
        // across the selected apps/web domains.
        let event = DeviceActivityEvent(
            applications: activitySelection.applicationTokens,
            categories: activitySelection.categoryTokens,
            webDomains: activitySelection.webDomainTokens,
            threshold: DateComponents(minute: thresholdMinutes)
        )
        
        do {
            try center.startMonitoring(
                activityName,
                during: schedule,
                events: [eventName: event]
            )
            print("Started daily monitoring with a \(thresholdMinutes)-minute threshold.")
        } catch {
            print("Failed to start monitoring: \(error)")
        }
    }
}
