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
                              // save family activity selection to shared defaults
        .onChange(of: manager.activitySelection) { newValue in
            let sharedDefaults = UserDefaults(suiteName: "group.com.alexs.ScreenBreakers")
            // save family activity selection to shared defaults
            let encoder = JSONEncoder()
            let encoded = try? encoder.encode(newValue)
            sharedDefaults?.set(encoded, forKey: "activitySelection")
            // check if we have authorization, if so, start monitoring
            if AuthorizationCenter.shared.authorizationStatus == .approved {
                manager.startMonitoringOneMinuteThreshold()
            }
        }
        .onAppear {
            // load family activity selection from shared defaults
            let sharedDefaults = UserDefaults(suiteName: "group.com.alexs.ScreenBreakers")
            let decoder = JSONDecoder()
            let decoded = sharedDefaults?.data(forKey: "activitySelection")
            print("got decoded")
            if decoded != nil {
                do {
                    let activitySelection = try? decoder.decode(FamilyActivitySelection.self, from: decoded!)
                    print("got activity selection")
                    manager.activitySelection = activitySelection!
                    print("set activity selection")
                    if AuthorizationCenter.shared.authorizationStatus == .approved {
                        print("monitoring automatically becuase already approved and selections set")
                        manager.startMonitoringOneMinuteThreshold()
                    }
                }catch {}
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

