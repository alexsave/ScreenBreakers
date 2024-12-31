import SwiftUI

struct PlayerNameEditor: View {
    @Binding var isEditingPlayerName: Bool
    @Binding var playerName: String
    
    var body: some View {
        if isEditingPlayerName {
            TextField("Your Name", text: $playerName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 120)
                .onSubmit { isEditingPlayerName = false }
        } else {
            Button(playerName) {
                isEditingPlayerName = true
            }
        }
    }
} 