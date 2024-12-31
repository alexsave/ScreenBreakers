import SwiftUI

@MainActor
class LeaderboardViewModel: ObservableObject {
    private let defaults = UserDefaults.standard
    private let userNameKey = "user_name"
    private let supabase = SupabaseManager.shared
    
    @Published var leaderboardName: String {
        didSet {
            guard let leaderboardId = supabase.currentLeaderboardId else { return }
            Task {
                do {
                    try await supabase.updateLeaderboardName(leaderboardId: leaderboardId, newName: leaderboardName)
                } catch {
                    print("Failed to update leaderboard name: \(error)")
                }
            }
        }
    }
    
    @Published var playerName: String {
        didSet {
            defaults.set(playerName, forKey: userNameKey)
            Task {
                do {
                    _ = try await supabase.createOrUpdateUser(name: playerName)
                } catch {
                    print("Failed to update player name: \(error)")
                }
            }
        }
    }
    
    @Published var currentLeaderboard: LeaderboardData?
    @Published var shareURL: URL?
    
    init() {
        // Load existing values from UserDefaults
        self.playerName = defaults.string(forKey: userNameKey) ?? "Player 1"
        self.leaderboardName = ""
        
        // Create initial user if needed
        Task {
            do {
                _ = try await supabase.createOrUpdateUser(name: playerName)
            } catch {
                print("Failed to create initial user: \(error)")
            }
        }
    }
    
    private func fetchLeaderboard() async {
        do {
            let members = try await supabase.getLeaderboardData()
            self.currentLeaderboard = LeaderboardData(
                id: supabase.currentLeaderboardId ?? "",
                name: leaderboardName,
                players: members.map { member in
                    (id: member.userId.uuidString, name: member.userName, minutes: member.todayMinutes)
                }
            )
        } catch {
            print("Failed to fetch leaderboard: \(error)")
            self.currentLeaderboard = nil
            self.leaderboardName = ""
        }
    }
    
    func shareLeaderboard() async {
        print("📱 Starting shareLeaderboard")
        
        // If we don't have a leaderboard yet, create one
        if currentLeaderboard == nil {
            print("📱 Creating new leaderboard")
            do {
                let leaderboardId = try await supabase.createLeaderboard(name: "Leaderboard")
                print("📱 Created leaderboard with ID: \(leaderboardId)")
                await fetchLeaderboard()
            } catch {
                print("Failed to create leaderboard: \(error)")
                return
            }
        }
        
        if let leaderboardId = supabase.currentLeaderboardId {
            shareURL = URL(string: "screenbreakers://\(leaderboardId)")
            print("📱 Set share URL: \(shareURL?.absoluteString ?? "nil")")
        }
    }
    
    func joinLeaderboard(withId id: String) async -> LeaderboardData? {
        do {
            try await supabase.joinLeaderboard(id: id)
            await fetchLeaderboard()
            return currentLeaderboard
        } catch {
            print("Failed to join leaderboard: \(error)")
            return nil
        }
    }
    
    func updateScreenTime(minutes: Int) async {
        do {
            try await supabase.updateDailyUsage(minutes: minutes)
            await fetchLeaderboard() // Refresh leaderboard data
        } catch {
            print("Failed to update screen time: \(error)")
        }
    }
}

// Helper struct to maintain compatibility with existing views
struct LeaderboardData {
    let id: String
    var name: String
    var players: [(id: String, name: String, minutes: Int)]
} 
