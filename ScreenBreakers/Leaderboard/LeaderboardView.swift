import SwiftUI
import SwiftData

struct LeaderboardView: View {
    @Query private var dailyActivities: [DailyActivity]
    @ObservedObject var viewModel: LeaderboardViewModel
    @Binding var isEditingLeaderboardName: Bool
    @Binding var isEditingPlayerName: Bool
    
    private var todayMinutes: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return dailyActivities
            .first { Calendar.current.startOfDay(for: $0.date) == today }
            .map { Int($0.totalScreenMinutes) } ?? 0
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with buttons
            HStack {
                if isEditingLeaderboardName {
                    TextField("Leaderboard Name", text: $viewModel.leaderboardName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                        .onSubmit { isEditingLeaderboardName = false }
                } else {
                    Text(viewModel.leaderboardName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .onTapGesture { isEditingLeaderboardName = true }
                }
                
                Spacer()
            }
            .padding()
            .background(Color(.systemBackground))
            
            // Leaderboard list
            ScrollView {
                VStack(spacing: 0) {
                    if let leaderboard = viewModel.currentLeaderboard {
                        ForEach(Array(leaderboard.players.enumerated()), id: \.element.id) { index, player in
                            let isCurrentUser = player.id == viewModel.userId
                            LeaderboardRow(
                                rank: index + 1,
                                playerName: player.name,
                                minutes: isCurrentUser ? todayMinutes : player.minutes,
                                isAlternate: index % 2 == 1,
                                showEditButton: isCurrentUser,
                                onEdit: isCurrentUser ? { isEditingPlayerName = true } : nil
                            )
                        }
                    }
                }
                .background(Color(.systemBackground))
            }
        }
        .sheet(isPresented: $isEditingPlayerName) {
            PlayerNameEditor(isEditingPlayerName: $isEditingPlayerName, playerName: $viewModel.playerName)
        }
    }
} 