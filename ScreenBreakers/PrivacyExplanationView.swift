import SwiftUI

struct PrivacyExplanationView: View {
    @Binding var isMonitoring: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "timer")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Enable Screen Time Tracking")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 16) {
                Text("To participate in the leaderboard, we need to track your screen time.")
                    .multilineTextAlignment(.center)
                
                VStack(alignment: .leading, spacing: 12) {
                    PrivacyBulletPoint(
                        icon: "eye.fill",
                        text: "We only track total time spent on selected apps"
                    )
                    PrivacyBulletPoint(
                        icon: "hand.raised.fill",
                        text: "You control which apps to include"
                    )
                    PrivacyBulletPoint(
                        icon: "clock.fill",
                        text: "Only daily totals are stored, no detailed history"
                    )
                    PrivacyBulletPoint(
                        icon: "person.fill.checkmark",
                        text: "You can stop tracking at any time"
                    )
                }
                .padding(.vertical)
            }
            .foregroundColor(.gray)
            
            Button(action: {
                isMonitoring.toggle()
            }) {
                HStack {
                    Image(systemName: isMonitoring ? "record.circle.fill" : "record.circle")
                        .foregroundColor(.red)
                    Text("Start Tracking")
                        .foregroundColor(.red)
                }
                .font(.title2)
            }
            .padding(.top)
            
            Spacer()
        }
        .padding()
    }
}

struct PrivacyBulletPoint: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 24)
            Text(text)
        }
    }
} 