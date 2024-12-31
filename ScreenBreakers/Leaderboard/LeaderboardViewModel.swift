import SwiftUI

@MainActor
class LeaderboardViewModel: ObservableObject {
    private let defaults = UserDefaults.standard
    private let userIdKey = "user_id"
    private let userNameKey = "user_name"
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
            defaults.set(playerName, forKey: userNameKey)
            guard let userId = userId else { return }
            Task {
                await server.updatePlayerName(userId: userId, newName: playerName)
            }
        }
    }
    
    @Published var currentLeaderboard: LeaderboardData?
    @Published var shareURL: URL?
    
    var userId: String? {
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
            } else {
                defaults.removeObject(forKey: leaderboardIdKey)
                currentLeaderboard = nil
                leaderboardName = ""
            }
        }
    }
    
    init() {
        // Load existing values from UserDefaults
        self.userId = defaults.string(forKey: userIdKey)
        self.playerName = defaults.string(forKey: userNameKey) ?? "Player 1"
        self.leaderboardName = ""
        
        // If no user ID exists, generate one and save initial player name
        if self.userId == nil {
            self.userId = UUID().uuidString
            defaults.set(self.playerName, forKey: userNameKey)
        }
        
        // Initialize without a leaderboard
        self.leaderboardId = nil
        self.currentLeaderboard = nil
        
        // Then try to load the leaderboard if we have an ID
        if let leaderboardId = defaults.string(forKey: leaderboardIdKey) {
            Task {
                await loadExistingLeaderboard(id: leaderboardId)
            }
        }
    }
    
    private func loadExistingLeaderboard(id: String) async {
        if let leaderboard = await server.getLeaderboard(id: id) {
            withAnimation {
                self.leaderboardId = id
                self.leaderboardName = leaderboard.name
                self.currentLeaderboard = leaderboard
            }
        } else {
            // If we can't load the leaderboard, clear the ID from defaults
            defaults.removeObject(forKey: leaderboardIdKey)
        }
    }
    
    func handleDeepLink(_ url: URL) {
        guard url.scheme == "screenbreakers",
              let leaderboardId = url.host else {
            print("Invalid deep link format")
            return
        }
        
        Task {
            await joinLeaderboard(withId: leaderboardId)
        }
    }
    
    private func fetchLeaderboard() async {
        guard let leaderboardId = leaderboardId else {
            currentLeaderboard = nil
            leaderboardName = ""
            return
        }
        
        if let leaderboard = await server.getLeaderboard(id: leaderboardId) {
            self.currentLeaderboard = leaderboard
            self.leaderboardName = leaderboard.name
        } else {
            // If we can't fetch the leaderboard, clear everything
            self.leaderboardId = nil
            self.currentLeaderboard = nil
            self.leaderboardName = ""
        }
    }
    
    func shareLeaderboard() async {
        print("📱 Starting shareLeaderboard")
        guard let userId = userId else {
            print("❌ No userId found")
            return
        }
        print("📱 UserId: \(userId)")
        
        // If we don't have a leaderboard yet, create one
        if currentLeaderboard == nil {
            print("📱 Creating new leaderboard")
            let newLeaderboardId = String(UUID().uuidString.prefix(7))
            let newLeaderboardName = "Leaderboard"
            print("📱 New leaderboard ID: \(newLeaderboardId), name: \(newLeaderboardName)")
            
            let leaderboard = await server.createAndJoinLeaderboard(
                userId: userId,
                userName: playerName,
                leaderboardId: newLeaderboardId,
                leaderboardName: newLeaderboardName
            )
            print("📱 Got leaderboard response: \(leaderboard)")
            
            // Set all properties in a single update
            withAnimation {
                self.leaderboardId = newLeaderboardId
                self.leaderboardName = newLeaderboardName
                self.currentLeaderboard = leaderboard
            }
            print("📱 Set all leaderboard properties")
        }
        
        if let leaderboardId = leaderboardId {
            shareURL = URL(string: "screenbreakers://\(leaderboardId)")
            print("📱 Set share URL: \(shareURL?.absoluteString ?? "nil")")
        }
    }
    
    func joinLeaderboard(withId id: String) async -> LeaderboardData? {
        guard let userId = userId else { return nil }
        if let leaderboard = await server.joinExistingLeaderboard(leaderboardId: id, userId: userId, userName: playerName) {
            withAnimation {
                self.leaderboardId = id
                self.leaderboardName = leaderboard.name
                self.currentLeaderboard = leaderboard
            }
            return leaderboard
        }
        return nil
    }
} 
