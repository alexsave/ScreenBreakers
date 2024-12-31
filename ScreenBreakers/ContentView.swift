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
    @Query private var dailyActivities: [DailyActivity]
    @StateObject private var manager = ScreenTimeManager()
    @StateObject private var viewModel = LeaderboardViewModel()
    @EnvironmentObject private var deepLinkManager: DeepLinkManager
    @State private var isEditingLeaderboardName = false
    @State private var isEditingPlayerName = false
    @State private var isShowingShareSheet = false
    @State private var showJoinError = false
    
    private var todayMinutes: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return dailyActivities
            .first { Calendar.current.startOfDay(for: $0.date) == today }
            .map { Int($0.totalScreenMinutes) } ?? 0
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ActionButtons(manager: manager, viewModel: viewModel, isShowingShareSheet: $isShowingShareSheet)
                
                if !manager.isAuthorized {
                    PrivacyExplanationView()
                } else if viewModel.currentLeaderboard == nil {
                    PlayerStatsView(playerName: viewModel.playerName, todayMinutes: todayMinutes)
                } else {
                    LeaderboardView(
                        viewModel: viewModel,
                        isEditingLeaderboardName: $isEditingLeaderboardName
                    )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    PlayerNameEditor(isEditingPlayerName: $isEditingPlayerName, playerName: $viewModel.playerName)
                }
            }
        }
        .sheet(isPresented: $isShowingShareSheet) {
            if let shareURL = viewModel.shareURL {
                ShareSheet(activityItems: [shareURL])
            }
        }
        .alert("Couldn't Join Leaderboard", isPresented: $showJoinError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("The leaderboard you're trying to join doesn't exist or is no longer available.")
        }
        .familyActivityPicker(isPresented: $manager.isPickerPresented,
                            selection: $manager.activitySelection)
        .onChange(of: manager.activitySelection) { newValue in
            manager.storeSelection(newValue)
            if manager.isAuthorized {
                manager.startMonitoringOneMinuteThreshold()
            }
        }
        .onChange(of: deepLinkManager.pendingLeaderboardId) { leaderboardId in
            guard let leaderboardId = leaderboardId else { return }
            
            // Clear the pending ID immediately to prevent duplicate joins
            deepLinkManager.pendingLeaderboardId = nil
            
            // Attempt to join the leaderboard
            Task {
                if await viewModel.joinLeaderboard(withId: leaderboardId) == nil {
                    showJoinError = true
                }
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
        .onOpenURL { url in
            deepLinkManager.handleDeepLink(url)
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

