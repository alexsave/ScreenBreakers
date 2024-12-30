import SwiftUI
import SwiftData
import FamilyControls
import Foundation
import SwiftData

struct ModelConfigurationManager {
    
    private static var container: ModelContainer?
    
    static func makeConfiguration() throws -> ModelContainer {
        let configuration = ModelConfiguration(
            isStoredInMemoryOnly: false,
            allowsSave: true,
            groupContainer: .identifier("group.com.alexs.ScreenBreakers")
        )
        let container = try ModelContainer(
            for: DailyActivity.self,
            configurations: configuration
        )
        return container
    }
    
    @MainActor
    static func getContext() throws -> ModelContext {
        guard let container = container else {
            throw NSError(domain: "container_uninitialized", code: 500, userInfo: [NSLocalizedDescriptionKey: "ModelContainer is not initialized"])
        }
        return container.mainContext
    }
}

struct ContentView: View {
    @Query private var dailyActivities: [DailyActivity]
    
    @StateObject private var manager = ScreenTimeManager()
    
    @State private var accumulatedMinutes = 0
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Screentime Leaderboard")
                .font(.headline)
                .padding(.top, 40)
            
            List(dailyActivities) { dailyActivity in
                VStack(alignment: .leading) {
                    Text("Date: \(dailyActivity.date)")
                    Text("Total Minutes of Activity: \(dailyActivity.totalScreenMinutes)")
                    Text("Total Active Time: \(dailyActivity.totalMonitoringMinutes)")
                }
            }
            Button("Start Monitoring") {
                Task {
                    await manager.requestAuthorization()
                    manager.isPickerPresented = true
                    // starting monitoring will be handled by onChange
                }
            }
            
            Spacer()
        }
        .padding()
        .familyActivityPicker(isPresented: $manager.isPickerPresented,
                              selection: $manager.activitySelection)
        .onChange(of: manager.activitySelection) { newValue in
            // check if we have authorization, if so, start monitoring
            if AuthorizationCenter.shared.authorizationStatus == .approved {
                manager.startMonitoringOneMinuteThreshold()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

