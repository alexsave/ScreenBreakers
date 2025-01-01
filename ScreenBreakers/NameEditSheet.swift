import SwiftUI

struct NameEditSheet: View {
    @Binding var isPresented: Bool
    @Binding var name: String
    let title: String
    @State private var tempName: String
    
    init(isPresented: Binding<Bool>, name: Binding<String>, title: String) {
        _isPresented = isPresented
        _name = name
        self.title = title
        _tempName = State(initialValue: name.wrappedValue)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text(title)
                .font(.headline)
            
            TextField("Enter name", text: $tempName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            Button("Done") {
                name = tempName
                isPresented = false
            }
            .padding(.bottom)
        }
        .padding()
        .presentationDetents([.height(180)])
        .presentationDragIndicator(.visible)
    }
} 