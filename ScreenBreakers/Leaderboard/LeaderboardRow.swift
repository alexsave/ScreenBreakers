import SwiftUI

struct LeaderboardRow: View {
    let rank: Int
    let playerName: String
    let minutes: Int
    let isAlternate: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Text("#\(rank)")
                .font(.headline)
                .foregroundColor(.gray)
                .frame(width: 40, alignment: .center)
            
            Text(playerName)
                .font(.headline)
            
            Spacer()
            
            Text("\(minutes)m")
                .font(.headline)
                .foregroundColor(.blue)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(isAlternate ? Color(.secondarySystemBackground) : Color(.systemBackground))
    }
} 