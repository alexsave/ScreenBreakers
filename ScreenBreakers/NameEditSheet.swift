import SwiftUI

struct NameEditSheet: View {
    @Binding var isPresented: Bool
    @Binding var name: String
    let title: String
    
    var body: some View {
        VStack(spacing: 16) {
            Text(title)
                .font(.headline)
            
            TextField("Enter name", text: $name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            Button("Done") {
                isPresented = false
            }
            .padding(.bottom)
        }
        .padding()
        .presentationDetents([.height(180)])
        .presentationDragIndicator(.visible)
    }
} 