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
            Text("Daily Activities count: \(dailyActivities.count)")
            List(dailyActivities) { dailyActivity in
                VStack(alignment: .leading) {
                    Text("Date: \(dailyActivity.date)")
                    Text("Total Minutes of Activity: \(dailyActivity.totalMinutesOfActivity)")
                    Text("Total Active Time: \(dailyActivity.totalActiveTime)")
                }
            }
            Text("1-Minute Threshold Demo")
                .font(.title)
                .padding(.top, 40)
            
            // Current "accumulated" usage read from the shared container
            Text("Accumulated Usage: \(accumulatedMinutes) minutes")
                .font(.headline)
            
            Button("Refresh Usage") {
                accumulatedMinutes = manager.fetchAccumulatedUsageMinutes()
            }
            
            Button("Request Screen Time Auth") {
                Task {
                    await manager.requestAuthorization()
                }
            }
            
            Button("Select Apps to Monitor") {
                manager.isPickerPresented = true
            }
            
            Button("Start 1-Minute Threshold Monitoring") {
                manager.startMonitoringOneMinuteThreshold()
            }
            
            Spacer()
        }
        .padding()
        .familyActivityPicker(isPresented: $manager.isPickerPresented,
                              selection: $manager.activitySelection)
        .onChange(of: manager.activitySelection) { newValue in
            manager.storeSelection(newValue)
        }
        .onAppear {
            
            
            
            do{
                // this actually seems to work
                let container = try ModelConfigurationManager.makeConfiguration()
                let context = container.mainContext
                let today = Calendar.current.startOfDay(for: Date())
                let fetchDescriptor = FetchDescriptor<DailyActivity>(
                    predicate: #Predicate { $0.date == today }
                )
                let result = try context.fetch(fetchDescriptor)
                print(result)
                
            } catch{}
            // piece of shit
            
            accumulatedMinutes = manager.fetchAccumulatedUsageMinutes()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

