import Foundation

struct LeaderboardData {
    let id: String
    var name: String
    var players: [(id: String, name: String, minutes: Int)]
}

actor MockLeaderboardServer {
    static let shared = MockLeaderboardServer()
    private var leaderboards: [String: LeaderboardData] = [:]
    private var userLeaderboards: [String: String] = [:] // userId -> leaderboardId
    
    private init() {}
    
    func registerUser(userId: String, userName: String) async {
        print("📡 Server: Registering user \(userId) with name \(userName)")
    }
    
    func createAndJoinLeaderboard(userId: String, userName: String, leaderboardId: String, leaderboardName: String) async -> LeaderboardData {
        print("📡 Server: Creating new leaderboard \(leaderboardId) for user \(userId)")
        
        let leaderboard = LeaderboardData(
            id: leaderboardId,
            name: leaderboardName,
            players: [(id: userId, name: userName, minutes: 0)]
        )
        leaderboards[leaderboardId] = leaderboard
        userLeaderboards[userId] = leaderboardId
        
        print("📡 Server: Created leaderboard and added user as first member")
        return leaderboard
    }
    
    func joinExistingLeaderboard(leaderboardId: String, userId: String, userName: String) async -> LeaderboardData? {
        print("📡 Server: User \(userId) (\(userName)) requesting to join existing leaderboard \(leaderboardId)")
        
        guard var leaderboard = leaderboards[leaderboardId] else {
            print("📡 Server: Leaderboard not found")
            return nil
        }
        
        if !leaderboard.players.contains(where: { $0.id == userId }) {
            leaderboard.players.append((id: userId, name: userName, minutes: 0))
            leaderboards[leaderboardId] = leaderboard
            userLeaderboards[userId] = leaderboardId
            print("📡 Server: Added user to leaderboard")
        }
        
        return leaderboard
    }
    
    func updatePlayerName(userId: String, newName: String) async {
        print("📡 Server: Updating name for user \(userId) to \(newName)")
        if let leaderboardId = userLeaderboards[userId],
           let index = leaderboards[leaderboardId]?.players.firstIndex(where: { $0.id == userId }) {
            leaderboards[leaderboardId]?.players[index].name = newName
        }
    }
    
    func updateLeaderboardName(leaderboardId: String, newName: String) async {
        print("📡 Server: Updating leaderboard \(leaderboardId) name to \(newName)")
        leaderboards[leaderboardId]?.name = newName
    }
    
    func getLeaderboard(id: String) async -> LeaderboardData? {
        print("📡 Server: Fetching leaderboard \(id)")
        return leaderboards[id]
    }
} 