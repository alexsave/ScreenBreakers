import SwiftUI

// Helper struct to maintain compatibility with existing views
public struct LeaderboardData {
    let id: String
    var name: String
    var players: [(id: String, name: String, minutes: Int)]
}

@MainActor
class LeaderboardViewModel: ObservableObject {
    private let defaults = UserDefaults.standard
    private let userNameKey = "user_name"
    let supabase = SupabaseManager.shared
    
    @Published var leaderboardName: String = "" {
        didSet {
            Task {
                await updateLeaderboardName(leaderboardName)
            }
        }
    }
    
    @Published var playerName: String {
        didSet {
            Task {
                await updatePlayerName(playerName)
            }
        }
    }
    
    @Published var currentLeaderboard: LeaderboardData?
    @Published var shareURL: URL?
    
    init() {
        self.playerName = defaults.string(forKey: userNameKey) ?? "Player 1"
        
        // Create initial user if needed
        Task {
            do {
                _ = try await supabase.createOrUpdateUser(name: playerName)
            } catch {
                print("Failed to create initial user: \(error)")
            }
        }
    }
    
    private func updateLeaderboardName(_ newName: String) async {
        guard let leaderboardId = supabase.currentLeaderboardId else { return }
        do {
            try await supabase.updateLeaderboardName(leaderboardId: leaderboardId, newName: newName)
        } catch {
            print("Failed to update leaderboard name: \(error)")
        }
    }
    
    private func updatePlayerName(_ newName: String) async {
        defaults.set(newName, forKey: userNameKey)
        do {
            _ = try await supabase.createOrUpdateUser(name: newName)
        } catch {
            print("Failed to update player name: \(error)")
        }
    }
    
    private func fetchLeaderboard() async {
        do {
            let members = try await supabase.getLeaderboardData()
            let leaderboardId = supabase.currentLeaderboardId ?? ""
            
            let mappedPlayers = members.map { member in
                (
                    id: member.userId.uuidString,
                    name: member.userName,
                    minutes: member.todayMinutes
                )
            }
            
            self.currentLeaderboard = LeaderboardData(
                id: leaderboardId,
                name: leaderboardName,
                players: mappedPlayers
            )
        } catch {
            print("Failed to fetch leaderboard: \(error)")
            self.currentLeaderboard = nil
            self.leaderboardName = ""
        }
    }
    
    func shareLeaderboard() async {
        print("📱 Starting shareLeaderboard")
        
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
            if supabase.currentLeaderboardId != nil {
                await fetchLeaderboard()
            }
        } catch {
            print("Failed to update screen time: \(error)")
        }
    }
} 
