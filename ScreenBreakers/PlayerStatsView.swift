import SwiftUI

struct PlayerStatsView: View {
    let playerName: String
    let todayMinutes: Int
    
    var body: some View {
        VStack(spacing: 20) {
            // Show current player's stats
            LeaderboardRow(
                rank: 1,
                playerName: playerName,
                minutes: todayMinutes,
                isAlternate: false
            )
            .padding(.horizontal)
            
            Spacer()
            
            // Empty state message
            VStack(spacing: 16) {
                Image(systemName: "person.3.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                Text("Share to Start a Leaderboard")
                    .font(.title2)
                    .foregroundColor(.gray)
                Text("Tap the share button above to create a leaderboard\nand invite your friends!")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding()
    }
} 