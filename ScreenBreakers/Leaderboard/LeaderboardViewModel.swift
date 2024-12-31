import SwiftUI

@MainActor
class LeaderboardViewModel: ObservableObject {
    @Published var leaderboardName: String {
        didSet {
            // TODO: API call to update leaderboard name
            print("Will update leaderboard name to: \(leaderboardName)")
        }
    }
    
    @Published var playerName: String {
        didSet {
            // TODO: API call to update player name
            print("Will update player name to: \(playerName)")
        }
    }
    
    init(leaderboardName: String = "My Leaderboard", playerName: String = "Player 1") {
        self.leaderboardName = leaderboardName
        self.playerName = playerName
    }
} 