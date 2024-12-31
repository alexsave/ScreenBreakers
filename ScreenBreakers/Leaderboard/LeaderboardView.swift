import SwiftUI
import SwiftData

struct LeaderboardView: View {
    @Query private var dailyActivities: [DailyActivity]
    @ObservedObject var viewModel: LeaderboardViewModel
    @Binding var isEditingLeaderboardName: Bool
    @Binding var isEditingPlayerName: Bool
    @Binding var isMonitoring: Bool
    
    private var todayMinutes: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return dailyActivities
            .first { Calendar.current.startOfDay(for: $0.date) == today }
            .map { Int($0.totalScreenMinutes) } ?? 0
    }
    
    private var currentUserId: String? {
        viewModel.supabase.currentUserId?.uuidString
    }
    
    private func makeLeaderboardRow(index: Int, player: (id: String, name: String, minutes: Int)) -> some View {
        let isCurrentUser = player.id == currentUserId
        return LeaderboardRow(
            rank: index + 1,
            playerName: player.name,
            minutes: isCurrentUser ? todayMinutes : player.minutes,
            isAlternate: index % 2 == 1,
            showEditButton: isCurrentUser,
            onEdit: isCurrentUser ? { isEditingPlayerName = true } : nil
        )
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with all controls
            HStack(spacing: 16) {
                // Title with edit button
                HStack(spacing: 4) {
                    Text(viewModel.leaderboardName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .lineLimit(1)
                    
                    if viewModel.currentLeaderboard != nil {
                        Button(action: { isEditingLeaderboardName = true }) {
                            Image(systemName: "pencil")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Share button
                Button(action: {
                    Task {
                        await viewModel.shareLeaderboard()
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
                    if let leaderboard = viewModel.currentLeaderboard {
                        ForEach(Array(leaderboard.players.enumerated()), id: \.element.id) { index, player in
                            makeLeaderboardRow(index: index, player: player)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .background(Color(.systemBackground))
        }
        .sheet(isPresented: $isEditingLeaderboardName) {
            NameEditSheet(
                isPresented: $isEditingLeaderboardName,
                name: $viewModel.leaderboardName,
                title: "Edit Leaderboard Name"
            )
        }
        .sheet(isPresented: $isEditingPlayerName) {
            NameEditSheet(
                isPresented: $isEditingPlayerName,
                name: $viewModel.playerName,
                title: "Edit Your Name"
            )
        }
    }
} 