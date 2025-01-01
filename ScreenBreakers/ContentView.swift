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
    @StateObject private var screenTimeManager = ScreenTimeManager()
    @StateObject private var leaderboardViewModel = LeaderboardViewModel()
    @State private var isShareSheetPresented = false
    @State private var isEditingPlayerName = false
    @State private var isEditingLeaderboardName = false
    @Query private var dailyActivities: [DailyActivity]
    
    private var todayMinutes: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return dailyActivities
            .first { Calendar.current.startOfDay(for: $0.date) == today }
            .map { Int($0.totalScreenMinutes) } ?? 0
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Header
                HStack {
                    if !leaderboardViewModel.isLoadingLeaderboard {
                        HStack {
                            Text(leaderboardViewModel.leaderboardName)
                                .font(.title)
                                .fontWeight(.bold)
                            
                            if leaderboardViewModel.currentLeaderboard != nil {
                                Button(action: { isEditingLeaderboardName = true }) {
                                    Image(systemName: "pencil")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .padding(.leading)
                        
                        Spacer()
                        
                        Button(action: {
                            Task {
                                await leaderboardViewModel.shareLeaderboard()
                                isShareSheetPresented = true
                            }
                        }) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.title2)
                        }
                        .padding(.trailing)
                    }
                }
                .padding(.vertical)
                
                ScrollView {
                    VStack(spacing: 16) {
                        if !screenTimeManager.isAuthorized {
                            PrivacyExplanationView(manager: screenTimeManager)
                        } else if leaderboardViewModel.isLoadingLeaderboard {
                            ProgressView()
                                .padding()
                        } else {
                            // Always show current user's stats
                            LeaderboardRow(
                                rank: 1,
                                playerName: leaderboardViewModel.playerName,
                                minutes: todayMinutes,
                                isAlternate: false,
                                isCurrentUser: true,
                                onEdit: { isEditingPlayerName = true }
                            )
                            .padding(.horizontal)
                            
                            // If we have a leaderboard, show other players
                            if let leaderboard = leaderboardViewModel.currentLeaderboard {
                                ForEach(Array(leaderboard.players.enumerated()), id: \.1.id) { index, player in
                                    if player.name != leaderboardViewModel.playerName {
                                        LeaderboardRow(
                                            rank: index + 1,
                                            playerName: player.name,
                                            minutes: player.minutes,
                                            isAlternate: index % 2 == 1,
                                            isCurrentUser: false
                                        )
                                        .padding(.horizontal)
                                    }
                                }
                            } else {
                                // Show share prompt if not in a leaderboard
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
                                }
                                .padding(.top, 32)
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $isShareSheetPresented) {
            if let url = leaderboardViewModel.shareURL {
                ShareSheet(activityItems: [url])
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
        }
        .sheet(isPresented: $isEditingPlayerName) {
            NameEditSheet(
                isPresented: $isEditingPlayerName,
                name: $leaderboardViewModel.playerName,
                title: "Edit Your Name"
            )
        }
        .sheet(isPresented: $isEditingLeaderboardName) {
            NameEditSheet(
                isPresented: $isEditingLeaderboardName,
                name: $leaderboardViewModel.leaderboardName,
                title: "Edit Leaderboard Name"
            )
        }
        .familyActivityPicker(
            isPresented: $screenTimeManager.isPickerPresented,
            selection: $screenTimeManager.activitySelection
        )
        .onChange(of: screenTimeManager.activitySelection) { selection in
            screenTimeManager.selectionDidComplete(selection)
        }
        .onChange(of: screenTimeManager.isAuthorized) { isAuthorized in
            if isAuthorized {
                Task {
                    await leaderboardViewModel.initializeAfterAuthorization()
                    await leaderboardViewModel.updateScreenTime(minutes: todayMinutes)
                }
            }
        }
        .task {
            // Initialize leaderboard if already authorized
            if screenTimeManager.isAuthorized {
                await leaderboardViewModel.initializeAfterAuthorization()
                await leaderboardViewModel.updateScreenTime(minutes: todayMinutes)
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

