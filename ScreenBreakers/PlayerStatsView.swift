import SwiftUI

struct PlayerStatsView: View {
    @Binding var isEditingPlayerName: Bool
    @Binding var playerName: String
    @Binding var isMonitoring: Bool
    @Binding var isShowingShareSheet: Bool
    let todayMinutes: Int
    let onShare: () async -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with all controls
            HStack(spacing: 16) {
                // Title with edit button
                HStack(spacing: 4) {
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
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
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(height: 56)
            .background(Color(.systemBackground))
            
            ScrollView {
                VStack(spacing: 0) {
                    LeaderboardRow(
                        rank: 1,
                        playerName: playerName,
                        minutes: todayMinutes,
                        isAlternate: false,
                        showEditButton: true,
                        onEdit: { isEditingPlayerName = true }
                    )
                    
                    VStack(spacing: 16) {
                        Spacer()
                            .frame(height: 40)
                        
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
                        
                        Spacer()
                    }
                }
                .padding(.horizontal, 16)
            }
            .background(Color(.systemBackground))
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
