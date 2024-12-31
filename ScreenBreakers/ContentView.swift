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
                // Header with controls
                HStack {
                    // Player/Leaderboard name with edit button
                    if viewModel.currentLeaderboard != nil {
                        HStack {
                            Text(viewModel.leaderboardName)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Button(action: {
                                isEditingLeaderboardName = true
                            }) {
                                Image(systemName: "pencil")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Share button
                    Button(action: {
                        print("📱 Share button tapped")
                        Task {
                            print("📱 Starting share task")
                            await viewModel.shareLeaderboard()
                            print("📱 Share completed, URL: \(String(describing: viewModel.shareURL))")
                            if viewModel.shareURL != nil {
                                print("📱 Setting isShowingShareSheet to true")
                                isShowingShareSheet = true
                            }
                        }
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title2)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                
                if !manager.isAuthorized {
                    PrivacyExplanationView(
                        isMonitoring: .init(
                            get: { manager.isAuthorized },
                            set: { isMonitoring in
                                Task {
                                    if isMonitoring {
                                        await manager.requestAuthorization()
                                        if manager.isAuthorized {
                                            manager.isPickerPresented = true
                                        }
                                    }
                                }
                            }
                        )
                    )
                } else if viewModel.currentLeaderboard == nil {
                    // Show current player's stats
                    LeaderboardRow(
                        rank: 1,
                        playerName: viewModel.playerName,
                        minutes: todayMinutes,
                        isAlternate: false,
                        showEditButton: true,
                        onEdit: { isEditingPlayerName = true }
                    )
                    .padding(.top)
                    
                    Spacer()
                    
                    // Empty state message
                    VStack(spacing: 16) {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("Share to Start a Leaderboard")
                            .font(.title2)
                            .foregroundColor(.gray)
                        Text("Tap the share button to create a leaderboard\nand invite your friends!")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.gray)
                        
                        Button(action: {
                            Task {
                                await viewModel.shareLeaderboard()
                                if viewModel.shareURL != nil {
                                    isShowingShareSheet = true
                                }
                            }
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share")
                            }
                            .font(.title2)
                            .foregroundColor(.blue)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(.systemBackground))
                            .cornerRadius(10)
                        }
                        .padding(.top, 8)
                    }
                    .padding()
                    
                    Spacer()
                } else {
                    // Leaderboard list
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(Array(viewModel.currentLeaderboard!.players.enumerated()), id: \.element.id) { index, player in
                                let isCurrentUser = player.id == viewModel.userId
                                LeaderboardRow(
                                    rank: index + 1,
                                    playerName: player.name,
                                    minutes: isCurrentUser ? todayMinutes : player.minutes,
                                    isAlternate: index % 2 == 1,
                                    showEditButton: isCurrentUser,
                                    onEdit: isCurrentUser ? { isEditingPlayerName = true } : nil
                                )
                            }
                        }
                        .background(Color(.systemBackground))
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $isShowingShareSheet) {
            if let shareURL = viewModel.shareURL {
                ShareSheet(activityItems: [shareURL])
                    .presentationDetents([.medium])
            }
        }
        .sheet(isPresented: $isEditingLeaderboardName) {
            NameEditSheet(
                isPresented: $isEditingLeaderboardName,
                name: $viewModel.leaderboardName,
                title: "Edit Leaderboard Name"
            )
        }
        .sheet(isPresented: $isEditingPlayerName) {
            NameEditSheet(
                isPresented: $isEditingPlayerName,
                name: $viewModel.playerName,
                title: "Edit Your Name"
            )
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

