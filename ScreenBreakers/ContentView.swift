import SwiftUI
import SwiftData
import FamilyControls
import Foundation

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
    @StateObject private var manager = ScreenTimeManager()
    @StateObject private var viewModel = LeaderboardViewModel()
    @State private var isEditingLeaderboardName = false
    @State private var isEditingPlayerName = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Action buttons
                HStack {
                    Spacer()
                    
                    HStack(spacing: 16) {
                        Button(action: {
                            Task {
                                await manager.requestAuthorization()
                                manager.isPickerPresented = true
                            }
                        }) {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.green)
                        }
                        
                        Button(action: {
                            // Share functionality will be added later
                        }) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 24))
                                .foregroundColor(.blue)
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                
                LeaderboardView(
                    viewModel: viewModel,
                    isEditingLeaderboardName: $isEditingLeaderboardName
                )
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if isEditingPlayerName {
                        TextField("Your Name", text: $viewModel.playerName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 120)
                            .onSubmit { isEditingPlayerName = false }
                    } else {
                        Button(viewModel.playerName) {
                            isEditingPlayerName = true
                        }
                    }
                }
            }
        }
        .familyActivityPicker(isPresented: $manager.isPickerPresented,
                            selection: $manager.activitySelection)
        .onChange(of: manager.activitySelection) { newValue in
            let sharedDefaults = UserDefaults(suiteName: "group.com.alexs.ScreenBreakers")
            let encoder = JSONEncoder()
            let encoded = try? encoder.encode(newValue)
            sharedDefaults?.set(encoded, forKey: "activitySelection")
            if AuthorizationCenter.shared.authorizationStatus == .approved {
                manager.startMonitoringOneMinuteThreshold()
            }
        }
        .onAppear {
            Task {
                let sharedDefaults = UserDefaults(suiteName: "group.com.alexs.ScreenBreakers")
                let decoder = JSONDecoder()
                let decoded = sharedDefaults?.data(forKey: "activitySelection")
                if decoded != nil {
                    let activitySelection = try? decoder.decode(FamilyActivitySelection.self, from: decoded!)
                    manager.activitySelection = activitySelection!
                    if AuthorizationCenter.shared.authorizationStatus == .approved {
                        manager.startMonitoringOneMinuteThreshold()
                    }
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

