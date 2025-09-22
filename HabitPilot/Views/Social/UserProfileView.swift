import SwiftUI
import UIKit

// MARK: - Supporting Views

struct PremiumFeatureBadge: View {
    let icon: String
    let text: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.white)
            
            Text(text)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.9))
        }
    }
}

struct SettingsRow: View {
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

struct AccountInfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondaryText)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primaryText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.tertiaryBackground)
        )
    }
}

// MARK: - Main View

struct UserProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var habitStore: HabitStore
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var goalStore: GoalStore
    @Environment(\.dismiss) private var dismiss
    @State private var showingThemeSettings = false
    @State private var showingNotificationSettings = false
    @State private var showingPrivacySettings = false
    @State private var showingHelpSupport = false
    @State private var showingAbout = false
    @State private var showingDeleteAccount = false
    @State private var showingEditProfile = false
    @State private var showingProfileStats = false
    @State private var showingAppSettings = false
    @State private var showingDataStorage = false
    @State private var isDeletingAccount = false
    @State private var deleteAccountPassword = ""
    @State private var showingDeleteAccountPasswordAlert = false
    @State private var showingUpgrade = false
    @State private var showingSaveAlert = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @State private var isSaving = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    userProfileSection
                    premiumSection
                    accountInfoSection
                    quickActionsSection
                    preferencesSection
                    supportSection
                    accountActionsSection
                    
                    Spacer(minLength: 20)
                }
            }
            .background(Color.primaryBackground.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingThemeSettings) {
            ThemeSettingsView()
        }
        .sheet(isPresented: $showingNotificationSettings) {
            NotificationSettingsView()
        }
        .sheet(isPresented: $showingPrivacySettings) {
            PrivacySettingsView()
        }
        .sheet(isPresented: $showingHelpSupport) {
            HelpSupportView()
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView()
        }
        .sheet(isPresented: $showingProfileStats) {
            if case .authenticated(let user) = authManager.authState {
                UserProfileDetailView(
                    user: user,
                    habitStore: habitStore,
                    taskStore: taskStore,
                    goalStore: goalStore
                )

            }
        }
        .sheet(isPresented: $showingAppSettings) {
            AppSettingsView()
        }
        .sheet(isPresented: $showingDataStorage) {
            DataStorageView()
        }
        .sheet(isPresented: $showingUpgrade) {
            UpgradeView(purchaseManager: PurchaseService.shared, habitStore: habitStore)
        }
        .alert("Delete Account", isPresented: $showingDeleteAccount) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                showingDeleteAccountPasswordAlert = true
            }
        } message: {
            Text("This action cannot be undone. All your data will be permanently deleted.")
        }
        .alert("Enter Password", isPresented: $showingDeleteAccountPasswordAlert) {
            TextField("Password", text: $deleteAccountPassword, prompt: Text("Enter your password"))
                .textContentType(.password)
            Button("Cancel", role: .cancel) {
                deleteAccountPassword = ""
            }
            Button("Delete Account", role: .destructive) {
                deleteAccount()
            }
        } message: {
            Text("Please enter your password to confirm account deletion.")
        }
        .onAppear {
        }
    }
    
    // MARK: - View Components
    
    private var userProfileSection: some View {
        VStack(spacing: 16) {
            ProfileImageView(
                username: authManager.currentUser?.username,
                size: 100
            )
            
            if case .authenticated(let user) = authManager.authState {
                VStack(spacing: 8) {
                    Text(user.username)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primaryText)
                    
                    if let email = user.email {
                        Text(email)
                            .font(.subheadline)
                            .foregroundColor(.secondaryText)
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: user.isAppleUser ? "applelogo" : "person.fill")
                            .font(.caption)
                            .foregroundColor(.secondaryText)
                        
                        Text(user.isAppleUser ? "Apple ID" : "Username")
                            .font(.caption)
                            .foregroundColor(.secondaryText)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.tertiaryBackground)
                    )
                }
            }
        }
        .padding(.top, 20)
    }
    
    private var accountInfoSection: some View {
        VStack(spacing: 16) {
            if case .authenticated(let user) = authManager.authState {
                AccountInfoRow(title: "Member Since", value: formatDate(user.createdAt))
                AccountInfoRow(title: "Last Login", value: formatDate(user.lastLoginAt))
            }
        }
        .padding(.horizontal, 24)
    }
    
    private var quickActionsSection: some View {
        VStack(spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
            
            VStack(spacing: 8) {
                SettingsRow(
                    icon: "person.circle",
                    title: "Edit Profile",
                    subtitle: "Update your information",
                    color: Color.blue
                ) {
                    showingEditProfile = true
                }
                
                SettingsRow(
                    icon: "paintbrush.fill",
                    title: "Appearance",
                    subtitle: "Customize app theme and colors",
                    color: Color.purple
                ) {
                    showingThemeSettings = true
                }
                
                SettingsRow(
                    icon: "bell.fill",
                    title: "Notifications",
                    subtitle: "Manage notification preferences",
                    color: Color.orange
                ) {
                    showingNotificationSettings = true
                }
                
                SettingsRow(
                    icon: "chart.bar.fill",
                    title: "Profile Stats",
                    subtitle: "View your habit statistics",
                    color: Color.green
                ) {
                    showingProfileStats = true
                }
            }
            .padding(.horizontal, 24)
        }
    }
    
    private var preferencesSection: some View {
        VStack(spacing: 16) {
            Text("Preferences")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
            
            VStack(spacing: 8) {
                SettingsRow(
                    icon: "lock.shield.fill",
                    title: "Privacy & Security",
                    subtitle: "Control your data and privacy",
                    color: Color.blue
                ) {
                    showingPrivacySettings = true
                }
                
                SettingsRow(
                    icon: "gear",
                    title: "App Settings",
                    subtitle: "General app configuration",
                    color: Color.gray
                ) {
                    showingAppSettings = true
                }
                
                SettingsRow(
                    icon: "icloud",
                    title: "Data & Storage",
                    subtitle: "Manage your data and storage",
                    color: Color.green
                ) {
                    showingDataStorage = true
                }
            }
            .padding(.horizontal, 24)
        }
    }
    
    private var supportSection: some View {
        VStack(spacing: 16) {
            Text("Support & Info")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
            
            VStack(spacing: 8) {
                SettingsRow(
                    icon: "questionmark.circle.fill",
                    title: "Help & Support",
                    subtitle: "Get help and contact support",
                    color: Color.green
                ) {
                    showingHelpSupport = true
                }
                
                SettingsRow(
                    icon: "info.circle.fill",
                    title: "About",
                    subtitle: "App version and information",
                    color: Color.gray
                ) {
                    showingAbout = true
                }
            }
            .padding(.horizontal, 24)
        }
    }
    
    private var accountActionsSection: some View {
        VStack(spacing: 16) {
            Text("Account")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
            
            VStack(spacing: 8) {
                SettingsRow(
                    icon: "trash.fill",
                    title: "Delete Account",
                    subtitle: "Permanently delete your account",
                    color: Color.red
                ) {
                    showingDeleteAccount = true
                }
                
                // Sign Out Button
                Button(action: {
                    authManager.signOut()
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 16, weight: .medium))
                        Text("Sign Out")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.errorRed)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color.errorRed.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(Color.errorRed.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                .padding(.horizontal, 24)
            }
        }
    }
    
    private var premiumSection: some View {
        VStack(spacing: 16) {
            // Premium banner
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "crown.fill")
                        .font(.title2)
                        .foregroundColor(.yellow)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Upgrade to Premium")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Unlock unlimited habits, advanced analytics, and AI features")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    Spacer()
                    
                    Button("Upgrade") {
                        showingUpgrade = true
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.2))
                    )
                }
                
                // Feature highlights
                HStack(spacing: 20) {
                    PremiumFeatureBadge(icon: "infinity", text: "Unlimited Habits")
                    PremiumFeatureBadge(icon: "brain.head.profile", text: "AI Assistant")
                    PremiumFeatureBadge(icon: "chart.line.uptrend.xyaxis", text: "Advanced Stats")
                }
            }
            .padding(20)
            .background(
                LinearGradient(
                    colors: [Color.orange, Color.yellow],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
            .shadow(color: Color.orange.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .padding(.horizontal, 24)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func deleteAccount() {
        guard !deleteAccountPassword.isEmpty else { return }
        
        isDeletingAccount = true
        
        Task {
            do {
                // Call API to delete account
                try await APIClient.shared.deleteAccount(password: deleteAccountPassword)
                
                await MainActor.run {
                    isDeletingAccount = false
                    deleteAccountPassword = ""
                    // Sign out after successful deletion
                    authManager.signOut()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isDeletingAccount = false
                    deleteAccountPassword = ""
                    // Show error alert
                }
            }
        }
    }
}

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthManager
    @State private var username = ""
    @State private var showingSaveAlert = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @State private var isSaving = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 50, weight: .light))
                            .foregroundColor(.blue)
                            .padding(.top, 20)
                        
                        Text("Edit Profile")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primaryText)
                        
                        Text("Update your profile information")
                            .font(.subheadline)
                            .foregroundColor(.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 20)
                    
                    // Form Fields
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Username")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primaryText)
                            
                            TextField("Enter username", text: $username)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .disabled(isSaving)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Save Button
                    Button(action: saveProfile) {
                        HStack(spacing: 8) {
                            if isSaving {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                            }
                            Text(isSaving ? "Saving..." : "Save Changes")
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
                        .opacity(isSaving ? 0.7 : 1.0)
                    }
                    .disabled(isSaving || username.isEmpty)
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 20)
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isSaving)
                }
            }
        }
        .onAppear {
            if case .authenticated(let user) = authManager.authState {
                username = user.username
            }
        }
        .alert("Profile Updated", isPresented: $showingSaveAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your profile has been updated successfully.")
        }
        .alert("Error", isPresented: $showingErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func saveProfile() {
        guard !username.isEmpty else { return }
        
        isSaving = true
        
        Task {
            do {
                // Get current profile picture URL to preserve it
                var profilePictureURL: String? = nil
                if case .authenticated(let user) = authManager.authState {
                    profilePictureURL = user.profilePicture
                }
                
                // Update profile via API
                let updatedUser = try await APIClient.shared.updateProfile(
                    username: username,
                    profilePicture: profilePictureURL
                )
                
                await MainActor.run {
                    // Update auth manager with new user data
                    authManager.updateCurrentUser(updatedUser)
                    
                    isSaving = false
                    showingSaveAlert = true
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = "Failed to update profile: \(error.localizedDescription)"
                    showingErrorAlert = true
                }
            }
        }
    }
} 