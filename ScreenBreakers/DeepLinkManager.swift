import SwiftUI

class DeepLinkManager: ObservableObject {
    @Published var pendingLeaderboardId: String?
    
    func handleDeepLink(_ url: URL) {
        guard url.scheme == "app",
              let leaderboardId = url.host else {
            print("Invalid deep link format")
            return
        }
        
        pendingLeaderboardId = leaderboardId
    }
} 