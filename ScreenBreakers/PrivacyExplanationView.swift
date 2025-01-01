import SwiftUI
import FamilyControls

struct PrivacyBulletPoint: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.gray)
            Text(text)
                .foregroundColor(.gray)
        }
    }
}

struct PrivacyExplanationView: View {
    @ObservedObject var manager: ScreenTimeManager
    
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
                .frame(height: 40)
            
            Image(systemName: "timer")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("Enable Screen Time Tracking")
                .font(.title2)
                .foregroundColor(.gray)
            
            Text("To participate in the leaderboard, we need to track your screen time.")
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
            
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
            
            Button(action: {
                Task {
                    await manager.requestAuthorization()
                }
            }) {
                HStack {
                    Image(systemName: "timer")
                    Text("Enable Tracking")
                }
                .font(.title2)
                .foregroundColor(.blue)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemBackground))
                .cornerRadius(10)
            }
            .padding(.top, 8)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .sheet(isPresented: $manager.isPickerPresented) {
            NavigationView {
                FamilyActivityPicker(selection: $manager.activitySelection)
                    .navigationTitle("Select Apps to Track")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                manager.isPickerPresented = false
                                manager.selectionDidComplete(manager.activitySelection)
                            }
                        }
                    }
            }
        }
    }
} 