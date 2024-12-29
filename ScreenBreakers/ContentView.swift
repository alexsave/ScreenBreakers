import SwiftUI
import FamilyControls

struct ContentView: View {
    @StateObject private var manager = ScreenTimeManager()
    
    @State private var accumulatedMinutes = 0
    
    var body: some View {
        VStack(spacing: 30) {
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
            accumulatedMinutes = manager.fetchAccumulatedUsageMinutes()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

