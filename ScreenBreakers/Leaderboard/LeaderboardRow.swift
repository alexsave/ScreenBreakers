import SwiftUI

struct LeaderboardRow: View {
    let rank: Int
    let playerName: String
    let minutes: Int
    let isAlternate: Bool
    var isCurrentUser: Bool = false
    var onEdit: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 16) {
            Text("#\(rank)")
                .font(.headline)
                .foregroundColor(.gray)
                .frame(width: 40, alignment: .center)
            
            HStack(spacing: 4) {
                Text(playerName)
                    .font(.headline)
                    .lineLimit(1)
                    
                if isCurrentUser {
                    Button(action: {
                        onEdit?()
                    }) {
                        Image(systemName: "pencil")
                            .foregroundColor(.blue)
                    }
                }
            }
            
            Spacer()
            
            Text("\(minutes)m")
                .font(.headline)
                .foregroundColor(.blue)
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .frame(height: 44)
        .background(isAlternate ? Color(.secondarySystemBackground) : Color(.systemBackground))
    }
} 
