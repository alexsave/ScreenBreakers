import SwiftUI

@MainActor
class LeaderboardViewModel: ObservableObject {
    private let defaults = UserDefaults.standard
    private let userIdKey = "user_id"
    private let leaderboardIdKey = "leaderboard_id"
    private let server = MockLeaderboardServer.shared
    
    @Published var leaderboardName: String {
        didSet {
            guard let leaderboardId = leaderboardId else { return }
            Task {
                await server.updateLeaderboardName(leaderboardId: leaderboardId, newName: leaderboardName)
            }
        }
    }
    
    @Published var playerName: String {
        didSet {
            guard let userId = userId else { return }
            Task {
                await server.updatePlayerName(userId: userId, newName: playerName)
            }
        }
    }
    
    @Published var currentLeaderboard: LeaderboardData?
    @Published var shareURL: URL?
    
    private(set) var userId: String? {
        didSet {
            if let userId = userId {
                defaults.set(userId, forKey: userIdKey)
            }
        }
    }
    
    private(set) var leaderboardId: String? {
        didSet {
            if let leaderboardId = leaderboardId {
                defaults.set(leaderboardId, forKey: leaderboardIdKey)
                // Only fetch if we're not in the middle of creating/joining
                if currentLeaderboard == nil {
                    Task {
                        await fetchLeaderboard()
                    }
                }
            }
        }
    }
    
    init(leaderboardName: String = "My Leaderboard", playerName: String = "Player 1") {
        self.leaderboardName = leaderboardName
        self.playerName = playerName
        
        // Load existing IDs from UserDefaults
        self.userId = defaults.string(forKey: userIdKey)
        self.leaderboardId = defaults.string(forKey: leaderboardIdKey)
        
        // If no user ID exists, generate one
        if self.userId == nil {
            self.userId = UUID().uuidString
        }
        
        // If we have a leaderboard ID, fetch it
        if let leaderboardId = self.leaderboardId {
            Task {
                await fetchLeaderboard()
            }
        }
    }
    
    func handleDeepLink(_ url: URL) {
        guard url.scheme == "app",
              let leaderboardId = url.host else {
            print("Invalid deep link format")
            return
        }
        
        Task {
            await joinLeaderboard(withId: leaderboardId)
        }
    }
    
    private func fetchLeaderboard() async {
        guard let leaderboardId = leaderboardId else { return }
        currentLeaderboard = await server.getLeaderboard(id: leaderboardId)
    }
    
    func shareLeaderboard() async {
        guard let userId = userId else { return }
        
        // If we don't have a leaderboard yet, create one
        if leaderboardId == nil {
            let newLeaderboardId = String(UUID().uuidString.prefix(7))
            let leaderboard = await server.createAndJoinLeaderboard(
                userId: userId,
                userName: playerName,
                leaderboardId: newLeaderboardId,
                leaderboardName: leaderboardName
            )
            self.leaderboardId = newLeaderboardId
            self.currentLeaderboard = leaderboard
        }
        
        if let leaderboardId = leaderboardId {
            shareURL = URL(string: "app://\(leaderboardId)")
        }
    }
    
    func joinLeaderboard(withId id: String) async -> LeaderboardData? {
        guard let userId = userId else { return nil }
        if let leaderboard = await server.joinExistingLeaderboard(leaderboardId: id, userId: userId, userName: playerName) {
            self.leaderboardId = id
            self.leaderboardName = leaderboard.name
            self.currentLeaderboard = leaderboard
            return leaderboard
        }
        return nil
    }
} 