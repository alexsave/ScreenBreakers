import SwiftUI
import SwiftData
import FamilyControls
import Foundation

// Import the new components

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
    @Environment(\.scenePhase) private var scenePhase
    @Query private var dailyActivities: [DailyActivity]
    @StateObject private var leaderboardViewModel = LeaderboardViewModel()
    @StateObject private var screenTimeManager = ScreenTimeManager()
    @EnvironmentObject private var deepLinkManager: DeepLinkManager
    
    @State private var isEditingPlayerName = false
    @State private var isEditingLeaderboardName = false
    @State private var isShowingShareSheet = false
    @State private var isShowingPrivacyExplanation = false
    
    private var todayMinutes: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return dailyActivities
            .first { Calendar.current.startOfDay(for: $0.date) == today }
            .map { Int($0.totalScreenMinutes) } ?? 0
    }
    
    var body: some View {
        TabView {
            PlayerStatsView(
                isEditingPlayerName: $isEditingPlayerName,
                playerName: $leaderboardViewModel.playerName,
                isMonitoring: .constant(screenTimeManager.isAuthorized),
                isShowingShareSheet: $isShowingShareSheet,
                todayMinutes: todayMinutes,
                onShare: {
                    await leaderboardViewModel.shareLeaderboard()
                }
            )
            .tabItem {
                Label("Stats", systemImage: "chart.bar.fill")
            }
            
            LeaderboardView(
                viewModel: leaderboardViewModel,
                isEditingLeaderboardName: $isEditingLeaderboardName,
                isEditingPlayerName: $isEditingPlayerName,
                isMonitoring: .constant(screenTimeManager.isAuthorized)
            )
            .tabItem {
                Label("Leaderboard", systemImage: "list.number")
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                // Update Supabase with current screen time when app becomes active
                Task {
                    await leaderboardViewModel.updateScreenTime(minutes: todayMinutes)
                }
            }
        }
        .onChange(of: deepLinkManager.pendingLeaderboardId) { _, newId in
            if let id = newId {
                Task {
                    await leaderboardViewModel.joinLeaderboard(withId: id)
                    deepLinkManager.pendingLeaderboardId = nil
                }
            }
        }
        .sheet(isPresented: $isShowingShareSheet) {
            if let url = leaderboardViewModel.shareURL {
                ShareSheet(activityItems: [url])
            }
        }
        .sheet(isPresented: $isShowingPrivacyExplanation) {
            PrivacyExplanationView(isPresented: $isShowingPrivacyExplanation)
        }
        .onAppear {
            if !screenTimeManager.isAuthorized {
                isShowingPrivacyExplanation = true
            }
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

