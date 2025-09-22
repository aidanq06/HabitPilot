import SwiftUI

// MARK: - Simple Text Field
struct SimpleTextField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
            
            TextField(placeholder, text: $text)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Simple Text Area
struct SimpleTextArea: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        TextField(placeholder, text: $text, axis: .vertical)
            .lineLimit(3...6)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
    }
}

// MARK: - Success Toast
struct SuccessToast: View {
    let message: String
    
    var body: some View {
        Text(message)
            .foregroundColor(.white)
            .padding()
            .background(Color.green)
            .cornerRadius(8)
    }
} 