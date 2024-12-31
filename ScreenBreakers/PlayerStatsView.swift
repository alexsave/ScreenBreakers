import SwiftUI

struct PlayerStatsView: View {
    @Binding var isEditingPlayerName: Bool
    @Binding var playerName: String
    @Binding var isMonitoring: Bool
    @Binding var isShowingShareSheet: Bool
    let todayMinutes: Int
    let onShare: () async -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Header with all controls
            HStack {
                // Player name with edit button
                HStack {
                    Text(playerName)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Button(action: {
                        isEditingPlayerName = true
                    }) {
                        Image(systemName: "pencil")
                            .foregroundColor(.blue)
                    }
                }
                
                Spacer()
                
                // Share button
                Button(action: {
                    Task {
                        await onShare()
                        isShowingShareSheet = true
                    }
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title2)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            
            // Show current player's stats
            LeaderboardRow(
                rank: 1,
                playerName: playerName,
                minutes: todayMinutes,
                isAlternate: false,
                showEditButton: true,
                onEdit: { isEditingPlayerName = true }
            )
            
            Spacer()
            
            // Empty state message
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
                
                Button(action: {
                    Task {
                        await onShare()
                        isShowingShareSheet = true
                    }
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share")
                    }
                    .font(.title2)
                    .foregroundColor(.blue)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                }
                .padding(.top, 8)
            }
            
            Spacer()
        }
        .sheet(isPresented: $isEditingPlayerName) {
            NameEditSheet(
                isPresented: $isEditingPlayerName,
                name: $playerName,
                title: "Edit Your Name"
            )
        }
    }
} 