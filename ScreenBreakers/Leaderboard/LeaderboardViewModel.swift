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
    private let leaderboardNameKey = "leaderboard_name"
    private let leaderboardIdKey = "leaderboard_id"
    let supabase = SupabaseManager.shared
    
    @Published var leaderboardName: String = "Leaderboard" {
        didSet {
            Task {
                await updateLeaderboardName(leaderboardName)
            }
            // Save the name locally
            defaults.set(leaderboardName, forKey: leaderboardNameKey)
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
    @Published private(set) var isLoadingLeaderboard = true
    
    private var updateTask: Task<Void, Never>?
    private let debounceInterval: TimeInterval = 30 // Update at most every 30 seconds
    
    init() {
        print("📱 Initializing LeaderboardViewModel")
        self.playerName = defaults.string(forKey: userNameKey) ?? "Player 1"
        
        // Load saved leaderboard name if exists
        if let savedName = defaults.string(forKey: leaderboardNameKey) {
            self.leaderboardName = savedName
        }
        
        // Set loading to false initially if we don't have a saved ID
        if defaults.string(forKey: leaderboardIdKey) == nil {
            print("📱 No saved leaderboard ID, setting loading to false")
            isLoadingLeaderboard = false
        }
        
        // Create initial user if needed and load leaderboard
        Task {
            do {
                print("📱 Creating or updating user")
                _ = try await supabase.createOrUpdateUser(name: playerName)
                
                // If we have a saved leaderboard ID, try to load it
                if let savedId = defaults.string(forKey: leaderboardIdKey) {
                    print("📱 Found saved leaderboard ID: \(savedId)")
                    try await supabase.joinLeaderboard(id: savedId)
                    await fetchLeaderboard()
                }
            } catch {
                print("Failed to create initial user or load leaderboard: \(error)")
                isLoadingLeaderboard = false
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
        print("📱 Fetching leaderboard data")
        do {
            let members = try await supabase.getLeaderboardData()
            let leaderboardId = supabase.currentLeaderboardId ?? ""
            
            // Create initial player entry if not in leaderboard
            var mappedPlayers = members.map { member in
                (
                    id: member.userId.uuidString,
                    name: member.userName,
                    minutes: member.todayMinutes
                )
            }
            
            // Add current user if not in the list
            if let currentUserId = supabase.currentUserId?.uuidString,
               !mappedPlayers.contains(where: { $0.id == currentUserId }) {
                mappedPlayers.append((
                    id: currentUserId,
                    name: playerName,
                    minutes: 0
                ))
            }
            
            // Sort players by minutes
            mappedPlayers.sort { $0.minutes > $1.minutes }
            
            self.currentLeaderboard = LeaderboardData(
                id: leaderboardId,
                name: leaderboardName,
                players: mappedPlayers
            )
            print("📱 Successfully fetched leaderboard with \(mappedPlayers.count) players")
            
            // Save the leaderboard ID
            defaults.set(leaderboardId, forKey: leaderboardIdKey)
            isLoadingLeaderboard = false
        } catch {
            print("Failed to fetch leaderboard: \(error)")
            self.currentLeaderboard = nil
            self.leaderboardName = "Leaderboard"
            defaults.removeObject(forKey: leaderboardIdKey)
            defaults.removeObject(forKey: leaderboardNameKey)
            isLoadingLeaderboard = false
        }
    }
    
    func shareLeaderboard() async {
        print("📱 Starting shareLeaderboard")
        isLoadingLeaderboard = true
        
        // Check if we already have a leaderboard ID saved
        if let savedId = defaults.string(forKey: leaderboardIdKey) {
            print("📱 Using existing leaderboard")
            shareURL = URL(string: "screenbreakers://\(savedId)")
            print("📱 Set share URL: \(shareURL?.absoluteString ?? "nil")")
            isLoadingLeaderboard = false
            return
        }
        
        // Create new leaderboard since we don't have a saved ID
        print("📱 Creating new leaderboard")
        do {
            let leaderboardId = try await supabase.createLeaderboard(name: "Leaderboard")
            self.leaderboardName = "Leaderboard"
            defaults.set(leaderboardId, forKey: leaderboardIdKey)
            defaults.set("Leaderboard", forKey: leaderboardNameKey)
            print("📱 Created leaderboard with ID: \(leaderboardId)")
            await fetchLeaderboard()
            
            shareURL = URL(string: "screenbreakers://\(leaderboardId)")
            print("📱 Set share URL: \(shareURL?.absoluteString ?? "nil")")
        } catch {
            print("Failed to create leaderboard: \(error)")
            isLoadingLeaderboard = false
        }
    }
    
    func joinLeaderboard(withId id: String) async -> LeaderboardData? {
        print("📱 Joining leaderboard with ID: \(id)")
        isLoadingLeaderboard = true
        do {
            try await supabase.joinLeaderboard(id: id)
            defaults.set(id, forKey: leaderboardIdKey)
            await fetchLeaderboard()
            print("📱 Successfully joined leaderboard")
            return currentLeaderboard
        } catch {
            print("Failed to join leaderboard: \(error)")
            defaults.removeObject(forKey: leaderboardIdKey)
            defaults.removeObject(forKey: leaderboardNameKey)
            isLoadingLeaderboard = false
            return nil
        }
    }
    
    func updateScreenTime(minutes: Int) async {
        // Cancel any pending update
        updateTask?.cancel()
        
        // Create new debounced update task
        updateTask = Task {
            do {
                try await Task.sleep(nanoseconds: UInt64(debounceInterval * 1_000_000_000))
                
                // Check if task was cancelled during sleep
                if Task.isCancelled { return }
                
                // Ensure we have a valid user ID
                if supabase.currentUserId == nil {
                    do {
                        _ = try await supabase.createOrUpdateUser(name: playerName)
                    } catch {
                        print("Failed to create/update user before updating screen time: \(error)")
                        return
                    }
                }
                
                try await supabase.updateDailyUsage(minutes: minutes)
                if supabase.currentLeaderboardId != nil {
                    await fetchLeaderboard()
                }
            } catch {
                if !Task.isCancelled {
                    print("Failed to update screen time: \(error)")
                }
            }
        }
    }
} 
