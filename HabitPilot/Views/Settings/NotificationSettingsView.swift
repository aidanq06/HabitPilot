import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var settingsManager = SettingsManager.shared
    @State private var showingPermissionAlert = false
    @State private var showingTimePicker = false
    @State private var defaultNotificationTime = Date()
    @State private var systemNotificationsEnabled = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.secondaryBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 16) {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 50, weight: .light))
                                .foregroundColor(.orange)
                                .padding(.top, 20)
                            
                            Text("Notifications")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.primaryText)
                            
                            Text("Manage how and when you receive notifications")
                                .font(.subheadline)
                                .foregroundColor(.secondaryText)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 20)
                        
                        // Notification Status
                        VStack(spacing: 16) {
                            HStack {
                                Text("Notification Status")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primaryText)
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text(systemNotificationsEnabled ? "System: Enabled" : "System: Disabled")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(systemNotificationsEnabled ? .green : .red)
                                    
                                    Text(settingsManager.notificationsEnabled ? "App: Enabled" : "App: Disabled")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(settingsManager.notificationsEnabled ? .green : .red)
                                }
                            }
                            
                            // App Notification Toggle
                            ToggleSettingRow(
                                icon: "bell.fill",
                                title: "App Notifications",
                                subtitle: "Enable notifications within the app",
                                isOn: Binding(
                                    get: { settingsManager.notificationsEnabled },
                                    set: { newValue in
                                        Task {
                                            await settingsManager.updateNotificationSetting(\.enabled, value: newValue)
                                        }
                                    }
                                ),
                                iconColor: .orange
                            )
                            
                            if !systemNotificationsEnabled {
                                Button(action: {
                                    requestNotificationPermission()
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "bell.badge")
                                        Text("Enable System Notifications")
                                    }
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        LinearGradient(
                                            colors: [Color.orange, Color.orange.opacity(0.8)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .cornerRadius(12)
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
                        
                        // Notification Types
                        VStack(spacing: 16) {
                            HStack {
                                Text("Notification Types")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primaryText)
                                
                                Spacer()
                            }
                            
                            VStack(spacing: 0) {
                                ToggleSettingRow(
                                    icon: "flame.fill",
                                    title: "Habit Reminders",
                                    subtitle: "Get reminded about your habits",
                                    isOn: Binding(
                                        get: { settingsManager.userPreferences.notifications?.habitReminders ?? true },
                                        set: { newValue in
                                            Task {
                                                await settingsManager.updateNotificationSetting(\.habitReminders, value: newValue)
                                            }
                                        }
                                    ),
                                    iconColor: .orange
                                )
                                
                                Divider()
                                    .padding(.leading, 60)
                                
                                ToggleSettingRow(
                                    icon: "trophy.fill",
                                    title: "Challenge Updates",
                                    subtitle: "Updates about group challenges",
                                    isOn: Binding(
                                        get: { settingsManager.userPreferences.notifications?.challengeUpdates ?? true },
                                        set: { newValue in
                                            Task {
                                                await settingsManager.updateNotificationSetting(\.challengeUpdates, value: newValue)
                                            }
                                        }
                                    ),
                                    iconColor: .yellow
                                )
                                
                                Divider()
                                    .padding(.leading, 60)
                                
                                ToggleSettingRow(
                                    icon: "person.2.fill",
                                    title: "Friend Activity",
                                    subtitle: "Updates from your friends",
                                    isOn: Binding(
                                        get: { settingsManager.userPreferences.notifications?.friendActivity ?? true },
                                        set: { newValue in
                                            Task {
                                                await settingsManager.updateNotificationSetting(\.friendActivity, value: newValue)
                                            }
                                        }
                                    ),
                                    iconColor: .blue
                                )
                                
                                Divider()
                                    .padding(.leading, 60)
                                
                                ToggleSettingRow(
                                    icon: "doc.text.fill",
                                    title: "Daily Digest",
                                    subtitle: "Daily summary of your progress",
                                    isOn: Binding(
                                        get: { settingsManager.userPreferences.notifications?.dailyDigest ?? false },
                                        set: { newValue in
                                            Task {
                                                await settingsManager.updateNotificationSetting(\.dailyDigest, value: newValue)
                                            }
                                        }
                                    ),
                                    iconColor: .green
                                )
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
                        
                        // Default Time
                        VStack(spacing: 16) {
                            HStack {
                                Text("Default Reminder Time")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primaryText)
                                
                                Spacer()
                            }
                            
                            Button(action: {
                                showingTimePicker = true
                            }) {
                                HStack {
                                    Image(systemName: "clock.fill")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.orange)
                                        .frame(width: 24)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Daily Reminder Time")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.primaryText)
                                        
                                        Text(settingsManager.userPreferences.notifications?.defaultTime ?? "20:00")
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
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            checkNotificationStatus()
            
            // Load settings
            Task {
                await settingsManager.loadPreferences()
            }
            
            // Initialize time picker with current default time
            if let defaultTimeString = settingsManager.userPreferences.notifications?.defaultTime {
                let formatter = DateFormatter()
                formatter.timeStyle = .short
                if let time = formatter.date(from: defaultTimeString) {
                    defaultNotificationTime = time
                }
            }
        }
        .alert("Enable Notifications", isPresented: $showingPermissionAlert) {
            Button("Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please enable notifications in Settings to receive reminders about your habits.")
        }
        .sheet(isPresented: $showingTimePicker) {
            NavigationView {
                VStack {
                    DatePicker("Default Time", selection: $defaultNotificationTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(WheelDatePickerStyle())
                        .labelsHidden()
                        .padding()
                    
                    Button("Save Time") {
                        // Convert Date to time string
                        let formatter = DateFormatter()
                        formatter.timeStyle = .short
                        let timeString = formatter.string(from: defaultNotificationTime)
                        
                        // Save to settings
                        Task {
                            await settingsManager.updateNotificationSetting(\.defaultTime, value: timeString)
                        }
                        
                        showingTimePicker = false
                    }
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color.orange, Color.orange.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .navigationTitle("Set Default Time")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Cancel") {
                            showingTimePicker = false
                        }
                    }
                }
            }
        }
    }
    
    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.systemNotificationsEnabled = settings.authorizationStatus == .authorized
            }
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    self.systemNotificationsEnabled = true
                } else {
                    self.showingPermissionAlert = true
                }
            }
        }
    }
}

#Preview {
    NotificationSettingsView()
} 