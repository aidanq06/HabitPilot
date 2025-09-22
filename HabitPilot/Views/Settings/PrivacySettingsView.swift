import SwiftUI

struct PrivacySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingPrivacyPolicy = false
    @State private var showingTermsOfService = false
    @State private var showingDataExport = false
    @State private var showingDeleteData = false
    @State private var isProfilePrivate = UserDefaults.standard.bool(forKey: "isProfilePrivate")
    @State private var isProcessing = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    @State private var successMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.primaryBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Profile Privacy
                        VStack(spacing: 16) {
                            HStack {
                                Text("Profile Privacy")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primaryText)
                                
                                Spacer()
                            }
                            
                            VStack(spacing: 12) {
                                PrivacyRow(
                                    icon: "eye.slash.fill",
                                    title: "Private Profile",
                                    subtitle: isProfilePrivate ? "Your profile is private" : "Your profile is public",
                                    color: isProfilePrivate ? .successGreen : .warningOrange
                                ) {
                                    togglePrivacy()
                                }
                                
                                if !isProfilePrivate {
                                    HStack {
                                        Image(systemName: "info.circle")
                                            .foregroundColor(.infoBlue)
                                            .font(.caption)
                                        
                                        Text("Public profiles allow friends to see your habits and progress")
                                            .font(.caption)
                                            .foregroundColor(.secondaryText)
                                        
                                        Spacer()
                                    }
                                    .padding(.horizontal, 16)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.cardBackground)
                                .shadow(color: .cardShadow, radius: 8, x: 0, y: 2)
                        )
                        .padding(.horizontal, 20)
                        
                        // Legal & Terms
                        VStack(spacing: 16) {
                            HStack {
                                Text("Legal & Terms")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primaryText)
                                
                                Spacer()
                            }
                            
                            VStack(spacing: 8) {
                                PrivacyRow(
                                    icon: "doc.text",
                                    title: "Privacy Policy",
                                    subtitle: "Read our privacy policy",
                                    color: .gray
                                ) {
                                    showingPrivacyPolicy = true
                                }
                                
                                PrivacyRow(
                                    icon: "doc.text.fill",
                                    title: "Terms of Service",
                                    subtitle: "Read our terms of service",
                                    color: .gray
                                ) {
                                    showingTermsOfService = true
                                }
                                
                                PrivacyRow(
                                    icon: "square.and.arrow.up",
                                    title: "Export Data",
                                    subtitle: "Download your habits and progress",
                                    color: .infoBlue
                                ) {
                                    showingDataExport = true
                                }
                                
                                PrivacyRow(
                                    icon: "trash.fill",
                                    title: "Delete Account",
                                    subtitle: "Permanently delete all your data",
                                    color: .errorRed
                                ) {
                                    showingDeleteData = true
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.cardBackground)
                                .shadow(color: .cardShadow, radius: 8, x: 0, y: 2)
                        )
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Privacy & Security")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Export Data", isPresented: $showingDataExport) {
            Button("Export") {
                exportData()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will export all your habit data, goals, and statistics to a file.")
        }
        .alert("Delete All Data", isPresented: $showingDeleteData) {
            Button("Delete", role: .destructive) {
                deleteAccount()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This action cannot be undone. All your data will be permanently deleted.")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .alert("Success", isPresented: $showSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(successMessage)
        }
        .sheet(isPresented: $showingPrivacyPolicy) {
            SimplePrivacyPolicyView()
        }
        .sheet(isPresented: $showingTermsOfService) {
            SimpleTermsOfServiceView()
        }
    }
    
    private func togglePrivacy() {
        isProcessing = true
        let newPrivacyState = !isProfilePrivate
        
        Task {
            do {
                try await APIClient.shared.togglePrivacy(isPrivate: newPrivacyState)
                
                await MainActor.run {
                    isProfilePrivate = newPrivacyState
                    UserDefaults.standard.set(isProfilePrivate, forKey: "isProfilePrivate")
                    successMessage = isProfilePrivate ? "Your profile is now private" : "Your profile is now public"
                    showSuccess = true
                    isProcessing = false
                    HapticFeedback.shared.successNotification()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to update privacy settings. Please try again."
                    showError = true
                    isProcessing = false
                    HapticFeedback.shared.errorOccurred()
                }
            }
        }
    }
    
    private func exportData() {
        isProcessing = true
        
        Task {
            do {
                let exportData = try await APIClient.shared.exportUserData()
                
                // Convert to JSON string
                let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
                let jsonString = String(data: jsonData, encoding: .utf8) ?? ""
                
                // Create temporary file
                let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                let filePath = documentsPath.appendingPathComponent("habitpilot_data_export.json")
                
                try jsonString.write(to: filePath, atomically: true, encoding: .utf8)
                
                await MainActor.run {
                    successMessage = "Data exported successfully to Documents folder"
                    showSuccess = true
                    isProcessing = false
                    HapticFeedback.shared.successNotification()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to export data. Please try again."
                    showError = true
                    isProcessing = false
                    HapticFeedback.shared.errorOccurred()
                }
            }
        }
    }
    
    private func deleteAccount() {
        isProcessing = true
        
        Task {
            do {
                try await APIClient.shared.deleteAccount()
                
                await MainActor.run {
                    // Clear all local data and logout
                    UserDefaults.standard.removeObject(forKey: "authToken")
                    UserDefaults.standard.removeObject(forKey: "userId")
                    UserDefaults.standard.removeObject(forKey: "username")
                    UserDefaults.standard.removeObject(forKey: "isProfilePrivate")
                    
                    // Navigate to login screen
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first {
                        window.rootViewController = UIHostingController(rootView: LoginView())
                    }
                    
                    HapticFeedback.shared.successNotification()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to delete account. Please try again."
                    showError = true
                    isProcessing = false
                    HapticFeedback.shared.errorOccurred()
                }
            }
        }
    }
}

struct PrivacyRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(color)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primaryText)
                    
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(.secondaryText)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondaryText)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.tertiaryBackground)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Simplified Privacy Policy View
struct SimplePrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Privacy Policy")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primaryText)
                    
                    Text("Last updated: January 2025")
                        .font(.subheadline)
                        .foregroundColor(.secondaryText)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Information We Collect")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primaryText)
                        
                        Text("We collect information you provide when creating an account, using our AI features, and interacting with other users through our social features. This includes your habits, goals, tasks, and progress data.")
                            .font(.body)
                            .foregroundColor(.primaryText)
                        
                        Text("AI Data Processing")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primaryText)
                        
                        Text("Our AI features use OpenAI's technology. When you interact with our AI assistant, your productivity data and messages are sent to OpenAI for processing according to their privacy policy.")
                            .font(.body)
                            .foregroundColor(.primaryText)
                        
                        Text("Social Features")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primaryText)
                        
                        Text("You control what productivity data to share with friends and groups. We collect friend connections, group memberships, and shared activities based on your choices.")
                            .font(.body)
                            .foregroundColor(.primaryText)
                        
                        Text("Your Rights")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primaryText)
                        
                        Text("You have the right to access, correct, delete, and export your personal data. Contact us through the app settings to exercise these rights.")
                            .font(.body)
                            .foregroundColor(.primaryText)
                        
                        Text("Contact")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primaryText)
                        
                        Text("For privacy questions, contact us at habitpilotai@gmail.com or through the app settings. We'll respond within 30 days.")
                            .font(.body)
                            .foregroundColor(.primaryText)
                    }
                }
                .padding()
            }
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Simplified Terms of Service View
struct SimpleTermsOfServiceView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Terms of Service")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primaryText)
                    
                    Text("Last updated: January 2025")
                        .font(.subheadline)
                        .foregroundColor(.secondaryText)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Acceptance")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primaryText)
                        
                        Text("By using HabitPilot AI, you agree to these terms. If you don't agree, please don't use our service.")
                            .font(.body)
                            .foregroundColor(.primaryText)
                        
                        Text("Service Description")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primaryText)
                        
                        Text("HabitPilot AI provides habit tracking, goal management, AI coaching, and social features to help you build better habits.")
                            .font(.body)
                            .foregroundColor(.primaryText)
                        
                        Text("AI Features")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primaryText)
                        
                        Text("Our AI features use OpenAI technology. AI responses are for informational purposes only and do not constitute professional advice.")
                            .font(.body)
                            .foregroundColor(.primaryText)
                        
                        Text("User Conduct")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primaryText)
                        
                        Text("You agree to use our service responsibly and not to harass other users or misuse our features.")
                            .font(.body)
                            .foregroundColor(.primaryText)
                        
                        Text("Contact")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primaryText)
                        
                        Text("For questions about these terms, contact us at habitpilotai@gmail.com or through the app settings.")
                            .font(.body)
                            .foregroundColor(.primaryText)
                    }
                }
                .padding()
            }
            .navigationTitle("Terms of Service")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    PrivacySettingsView()
} 