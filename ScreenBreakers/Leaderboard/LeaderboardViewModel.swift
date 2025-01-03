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
                await fetchLeaderboard()
            }
        }
    }
    
    @Published var currentLeaderboard: LeaderboardData?
    @Published var shareURL: URL?
    @Published private(set) var isLoadingLeaderboard = false
    
    private var updateTask: Task<Void, Never>?
    private let debounceInterval: TimeInterval = 30 // Update at most every 30 seconds
    private var isFirstUpdate = true
    
    init() {
        print("📱 Initializing LeaderboardViewModel")
        self.playerName = defaults.string(forKey: userNameKey) ?? "Player 1"
        
        // Load saved leaderboard name if exists
        if let savedName = defaults.string(forKey: leaderboardNameKey) {
            self.leaderboardName = savedName
        }
    }
    
    func initializeAfterAuthorization() async {
        isLoadingLeaderboard = true
        do {
            print("📱 Creating or updating user")
            _ = try await supabase.createOrUpdateUser(name: playerName)
            
            // If we have a saved leaderboard ID, try to load it
            if let savedId = defaults.string(forKey: leaderboardIdKey) {
                print("📱 Found saved leaderboard ID: \(savedId)")
                try await supabase.joinLeaderboard(id: savedId)
                await fetchLeaderboard()
            }
            isLoadingLeaderboard = false
        } catch {
            print("Failed to create initial user or load leaderboard: \(error)")
            isLoadingLeaderboard = false
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
    
    func fetchLeaderboard() async {
        print("📱 Fetching leaderboard data")
        do {
            let members = try await supabase.getLeaderboardData()
            print("📱 Raw leaderboard data: \(members)")
            
            let leaderboardId = supabase.currentLeaderboardId ?? ""
            
            // Get the leaderboard name from the first member (they all have the same name)
            if let firstMember = members.first {
                self.leaderboardName = firstMember.leaderboardName
                print("📱 Setting leaderboard name to: \(firstMember.leaderboardName)")
            }
            
            // Create initial player entry if not in leaderboard
            var mappedPlayers = members.map { member in
                (
                    id: member.userId.uuidString,
                    name: member.userName,
                    minutes: member.todayMinutes
                )
            }
            print("📱 Mapped players before adding current user: \(mappedPlayers)")
            
            // Add current user if not in the list
            if let currentUserId = supabase.currentUserId?.uuidString,
               !mappedPlayers.contains(where: { $0.id == currentUserId }) {
                print("📱 Adding current user to list: \(currentUserId) (\(playerName))")
                mappedPlayers.append((
                    id: currentUserId,
                    name: playerName,
                    minutes: 0
                ))
            }
            
            // Sort players by minutes
            mappedPlayers.sort { $0.minutes < $1.minutes }
            print("📱 Final sorted players: \(mappedPlayers)")
            
            self.currentLeaderboard = LeaderboardData(
                id: leaderboardId,
                name: self.leaderboardName,
                players: mappedPlayers
            )
            print("📱 Successfully fetched leaderboard with \(mappedPlayers.count) players")
            
            // Save the leaderboard ID and name
            if !leaderboardId.isEmpty {
                defaults.set(leaderboardId, forKey: leaderboardIdKey)
                defaults.set(self.leaderboardName, forKey: leaderboardNameKey)
            }
            isLoadingLeaderboard = false
        } catch {
            print("Failed to fetch leaderboard: \(error)")
            let nsError = error as NSError
            // Only clear leaderboard data if we get a specific error indicating it doesn't exist
            if nsError.domain == "SupabaseError" && nsError.code == 404 {
                self.currentLeaderboard = nil
                self.leaderboardName = "Leaderboard"
                defaults.removeObject(forKey: leaderboardIdKey)
                defaults.removeObject(forKey: leaderboardNameKey)
            }
            isLoadingLeaderboard = false
        }
    }
    
    func shareLeaderboard() async {
        print("📱 Starting shareLeaderboard")
        isLoadingLeaderboard = true
        
        // Check if we already have a leaderboard ID saved
        if let savedId = defaults.string(forKey: leaderboardIdKey),
           !savedId.isEmpty {
            print("📱 Using existing leaderboard")
            shareURL = URL(string: "screenbreakers://\(savedId)")
            print("📱 Set share URL: \(shareURL?.absoluteString ?? "nil")")
            await fetchLeaderboard() // Make sure we have the latest data
            return
        }
        
        // Create new leaderboard since we don't have a saved ID
        print("📱 Creating new leaderboard")
        do {
            let leaderboardId = try await supabase.createLeaderboard(name: "Leaderboard")
            print("📱 Created leaderboard with ID: \(leaderboardId)")
            
            // Save the ID first
            defaults.set(leaderboardId, forKey: leaderboardIdKey)
            defaults.set("Leaderboard", forKey: leaderboardNameKey)
            self.leaderboardName = "Leaderboard"
            
            // Set share URL
            shareURL = URL(string: "screenbreakers://\(leaderboardId)")
            print("📱 Set share URL: \(shareURL?.absoluteString ?? "nil")")
            
            // Fetch the leaderboard data
            await fetchLeaderboard() // This will set isLoadingLeaderboard to false when done
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
        print("📱 Starting updateScreenTime with \(minutes) minutes")
        print("📱 Current user ID: \(supabase.currentUserId?.uuidString ?? "nil")")
        print("📱 Current leaderboard ID: \(supabase.currentLeaderboardId ?? "nil")")
        
        // Cancel any pending update
        if updateTask != nil {
            print("📱 Cancelling previous update task")
        }
        updateTask?.cancel()
        
        let shouldDebounce = !isFirstUpdate
        isFirstUpdate = false
        
        // Create new debounced update task
        updateTask = Task {
            do {
                if shouldDebounce {
                    print("📱 Waiting \(debounceInterval) seconds before update")
                    try await Task.sleep(nanoseconds: UInt64(debounceInterval * 1_000_000_000))
                } else {
                    print("📱 First update of session - no delay")
                }
                
                // Check if task was cancelled during sleep
                if Task.isCancelled {
                    print("📱 Update task was cancelled")
                    return
                }
                
                // Ensure we have a valid user ID
                if supabase.currentUserId == nil {
                    print("📱 No current user ID, attempting to create/update user")
                    do {
                        _ = try await supabase.createOrUpdateUser(name: playerName)
                        print("📱 Successfully created/updated user")
                    } catch {
                        print("📱 Failed to create/update user before updating screen time: \(error)")
                        return
                    }
                }
                
                print("📱 Sending screen time update to server: \(minutes) minutes")
                try await supabase.updateDailyUsage(minutes: minutes)
                print("📱 Successfully updated daily usage")
                
                if supabase.currentLeaderboardId != nil {
                    print("📱 Refreshing leaderboard after update")
                    await fetchLeaderboard()
                } else {
                    print("📱 No current leaderboard to refresh")
                }
            } catch {
                if !Task.isCancelled {
                    print("📱 Failed to update screen time: \(error)")
                }
            }
        }
    }
} 
