import SwiftUI
import SwiftData

struct LeaderboardView: View {
    @Query private var dailyActivities: [DailyActivity]
    @ObservedObject var viewModel: LeaderboardViewModel
    @Binding var isEditingLeaderboardName: Bool
    
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
                    ForEach(Array(dailyActivities.enumerated()), id: \.element.id) { index, activity in
                        LeaderboardRow(
                            rank: index + 1,
                            playerName: viewModel.playerName,
                            minutes: Int(activity.totalScreenMinutes),
                            isAlternate: index % 2 == 1
                        )
                    }
                }
                .background(Color(.systemBackground))
            }
        }
    }
} 