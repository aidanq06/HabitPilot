import SwiftUI

struct MessageView: View {
    let recipient: User
    @Environment(\.dismiss) private var dismiss
    @State private var messageText = ""
    @State private var isSending = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    // Diagnostic logging
    init(recipient: User) {
        self.recipient = recipient
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("New Message")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Cancel") {
                    dismiss()
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            .padding(.horizontal)
            .padding(.top)
            
            Text("Send message to \(recipient.username)")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            TextEditor(text: $messageText)
                .frame(minHeight: 100)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .padding(.horizontal)
            
            Button(action: sendMessage) {
                if isSending {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(0.8)
                        .foregroundColor(.white)
                } else {
                    Text("Send Message")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
            }
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [Color.blue, Color.blue.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(12)
            .padding(.horizontal)
            .disabled(messageText.isEmpty || isSending)
            .opacity(messageText.isEmpty || isSending ? 0.5 : 1.0)
            
            Spacer()
        }
        .onAppear {
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isSending = true
        
        Task {
            do {
                try await APIClient.shared.sendMessage(
                    recipientId: recipient.id,
                    content: messageText.trimmingCharacters(in: .whitespacesAndNewlines)
                )
                
                await MainActor.run {
                    HapticFeedback.shared.successNotification()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSending = false
                    errorMessage = "Failed to send message. Please try again."
                    showError = true
                    HapticFeedback.shared.errorOccurred()
                }
            }
        }
    }
} 