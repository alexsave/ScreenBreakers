import Foundation
import Supabase

@MainActor
class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()
    private let client: SupabaseClient
    
    @Published var currentUserId: UUID?
    @Published var currentLeaderboardId: String?
    
    private init() {
        // Initialize Supabase client using config
        self.client = SupabaseClient(
            supabaseURL: URL(string: SupabaseConfig.url)!,
            supabaseKey: SupabaseConfig.anonKey
        )
    }
    
    // MARK: - User Management
    
    func createOrUpdateUser(name: String) async throws -> UUID {
        if let userId = currentUserId {
            // Update existing user
            try await client.database
                .from("users")
                .update(["name": name])
                .eq("id", value: userId)
                .execute()
            return userId
        } else {
            // Create new user
            let response: [User] = try await client.database
                .from("users")
                .insert(["name": name])
                .select()
                .execute()
                .value
            
            guard let newUser = response.first,
                  let userId = newUser.id else {
                throw NSError(domain: "SupabaseError", code: 500, userInfo: [
                    NSLocalizedDescriptionKey: "Failed to create user"
                ])
            }
            
            currentUserId = userId
            return userId
        }
    }
    
    func updateDailyUsage(minutes: Int) async throws {
        guard let userId = currentUserId else {
            throw NSError(domain: "SupabaseError", code: 400, userInfo: [
                NSLocalizedDescriptionKey: "No user ID available"
            ])
        }
        
        let calendar = Calendar.current
        let day = calendar.component(.day, from: Date())
        
        try await client.database.rpc(
            fn: "update_daily_usage",
            params: UpdateDailyUsageParams(
                p_user_id: userId,
                p_day: day,
                p_minutes: minutes
            )
        ).execute()
    }
    
    // MARK: - Leaderboard Management
    
    func createLeaderboard(name: String) async throws -> String {
        guard let userId = currentUserId else {
            throw NSError(domain: "SupabaseError", code: 400, userInfo: [
                NSLocalizedDescriptionKey: "No user ID available"
            ])
        }
        
        // Generate a short unique ID for the leaderboard
        let leaderboardId = String(UUID().uuidString.prefix(7))
        
        // Create leaderboard
        try await client.database
            .from("leaderboards")
            .insert(["id": leaderboardId, "name": name])
            .execute()
        
        // Update user's current leaderboard
        try await client.database
            .from("users")
            .update(["current_leaderboard_id": leaderboardId])
            .eq("id", value: userId)
            .execute()
        
        currentLeaderboardId = leaderboardId
        return leaderboardId
    }
    
    func joinLeaderboard(id: String) async throws {
        guard let userId = currentUserId else {
            throw NSError(domain: "SupabaseError", code: 400, userInfo: [
                NSLocalizedDescriptionKey: "No user ID available"
            ])
        }
        
        // Verify leaderboard exists
        let leaderboards: [Leaderboard] = try await client.database
            .from("leaderboards")
            .select()
            .eq("id", value: id)
            .execute()
            .value
        
        guard !leaderboards.isEmpty else {
            throw NSError(domain: "SupabaseError", code: 404, userInfo: [
                NSLocalizedDescriptionKey: "Leaderboard not found"
            ])
        }
        
        // Update user's current leaderboard
        try await client.database
            .from("users")
            .update(["current_leaderboard_id": id])
            .eq("id", value: userId)
            .execute()
        
        currentLeaderboardId = id
    }
    
    func getLeaderboardData() async throws -> [LeaderboardMember] {
        guard let leaderboardId = currentLeaderboardId else {
            throw NSError(domain: "SupabaseError", code: 400, userInfo: [
                NSLocalizedDescriptionKey: "No leaderboard ID available"
            ])
        }
        
        return try await client.database
            .rpc(
                fn: "get_leaderboard_data",
                params: GetLeaderboardDataParams(p_leaderboard_id: leaderboardId)
            )
            .execute()
            .value
    }
}

// MARK: - Models

struct User: Codable {
    let id: UUID?
    let name: String
    let currentLeaderboardId: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case currentLeaderboardId = "current_leaderboard_id"
    }
}

struct Leaderboard: Codable {
    let id: String
    let name: String
}

struct LeaderboardMember: Codable {
    let userId: UUID
    let userName: String
    let todayMinutes: Int
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case userName = "user_name"
        case todayMinutes = "today_minutes"
    }
}

struct UpdateDailyUsageParams: Codable {
    let p_user_id: UUID
    let p_day: Int
    let p_minutes: Int
}

struct GetLeaderboardDataParams: Codable {
    let p_leaderboard_id: String
} 