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
    @EnvironmentObject private var deepLinkManager: DeepLinkManager
    @State private var isEditingLeaderboardName = false
    @State private var isEditingPlayerName = false
    @State private var isShowingShareSheet = false
    @State private var showJoinError = false
    
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
                            Task {
                                await viewModel.shareLeaderboard()
                                if viewModel.shareURL != nil {
                                    isShowingShareSheet = true
                                }
                            }
                        }) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 24))
                                .foregroundColor(.blue)
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                
                if viewModel.currentLeaderboard == nil {
                    // Empty state
                    VStack(spacing: 20) {
                        Spacer()
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("Share to Start a Leaderboard")
                            .font(.title2)
                            .foregroundColor(.gray)
                        Text("Tap the share button above to create a leaderboard\nand invite your friends!")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.gray)
                        Spacer()
                    }
                    .padding()
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
            let sharedDefaults = UserDefaults(suiteName: "group.com.alexs.ScreenBreakers")
            let encoder = JSONEncoder()
            let encoded = try? encoder.encode(newValue)
            sharedDefaults?.set(encoded, forKey: "activitySelection")
            if AuthorizationCenter.shared.authorizationStatus == .approved {
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

