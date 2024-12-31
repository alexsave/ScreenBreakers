import SwiftUI

struct ActionButtons: View {
    @ObservedObject var manager: ScreenTimeManager
    @ObservedObject var viewModel: LeaderboardViewModel
    @Binding var isShowingShareSheet: Bool
    
    var body: some View {
        HStack {
            Spacer()
            
            HStack(spacing: 16) {
                Button(action: {
                    Task {
                        await manager.requestAuthorization()
                        if manager.isAuthorized {
                            manager.isPickerPresented = true
                        }
                    }
                }) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.green)
                }
                
                Button(action: {
                    Task {
                        await viewModel.shareLeaderboard()
                        if viewModel.shareURL != nil {
                            isShowingShareSheet = true
                        }
                    }
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
} 