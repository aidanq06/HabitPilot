import SwiftUI

struct AppSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var settingsManager = SettingsManager.shared
    @State private var showingResetAlert = false
    @State private var isSaving = false
    @State private var showingUpgrade = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Premium Section
                    if !PurchaseService.shared.isUnlimitedPurchased {
                        VStack(spacing: 16) {
                            Text("Premium Features")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primaryText)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)
                            
                            Button(action: {
                                showingUpgrade = true
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "crown.fill")
                                        .font(.title2)
                                        .foregroundColor(.yellow)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Upgrade to Premium")
                                            .font(.headline)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                        
                                        Text("Unlock unlimited habits, AI features, and advanced analytics")
                                            .font(.subheadline)
                                            .foregroundColor(.white.opacity(0.9))
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.7))
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
                            .padding(.horizontal, 16)
                        }
                    }
                    
                    // General Settings
                    VStack(alignment: .leading, spacing: 16) {
                        Text("General")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primaryText)
                            .padding(.horizontal, 16)
                        
                        VStack(spacing: 0) {
                            // Sound Effects
                            ToggleSettingRow(
                                icon: "speaker.wave.2.fill",
                                title: "Sound Effects",
                                subtitle: "Play sounds for actions",
                                isOn: Binding(
                                    get: { settingsManager.soundEffects },
                                    set: { newValue in
                                        Task {
                                            await settingsManager.updateAppSetting(\.soundEffects, value: newValue)
                                        }
                                    }
                                ),
                                iconColor: .orange
                            )
                            
                            Divider()
                                .padding(.leading, 60)
                            
                            // Haptic Feedback
                            ToggleSettingRow(
                                icon: "iphone.radiowaves.left.and.right",
                                title: "Haptic Feedback",
                                subtitle: "Vibrate on actions",
                                isOn: Binding(
                                    get: { settingsManager.hapticFeedback },
                                    set: { newValue in
                                        Task {
                                            await settingsManager.updateAppSetting(\.hapticFeedback, value: newValue)
                                        }
                                    }
                                ),
                                iconColor: .blue
                            )
                        }
                        .background(Color.secondaryBackground)
                        .cornerRadius(16)
                        .padding(.horizontal, 16)
                    }
                    
                    // Display Settings
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Display")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primaryText)
                            .padding(.horizontal, 16)
                        
                        VStack(spacing: 0) {
                            // Show Streaks
                            ToggleSettingRow(
                                icon: "flame.fill",
                                title: "Show Streaks",
                                subtitle: "Display habit streaks",
                                isOn: Binding(
                                    get: { settingsManager.showStreaks },
                                    set: { newValue in
                                        Task {
                                            await settingsManager.updateAppSetting(\.showStreaks, value: newValue)
                                        }
                                    }
                                ),
                                iconColor: .orange
                            )
                            
                            Divider()
                                .padding(.leading, 60)
                            
                            // Show Badges
                            ToggleSettingRow(
                                icon: "star.circle.fill",
                                title: "Show Badges",
                                subtitle: "Display achievement badges",
                                isOn: Binding(
                                    get: { settingsManager.showBadges },
                                    set: { newValue in
                                        Task {
                                            await settingsManager.updateAppSetting(\.showBadges, value: newValue)
                                        }
                                    }
                                ),
                                iconColor: .yellow
                            )
                            
                            Divider()
                                .padding(.leading, 60)
                            
                            // 24-Hour Time
                            ToggleSettingRow(
                                icon: "clock.fill",
                                title: "24-Hour Time",
                                subtitle: "Use 24-hour time format",
                                isOn: Binding(
                                    get: { settingsManager.use24HourTime },
                                    set: { newValue in
                                        Task {
                                            await settingsManager.updateAppSetting(\.use24HourTime, value: newValue)
                                        }
                                    }
                                ),
                                iconColor: .green
                            )
                        }
                        .background(Color.secondaryBackground)
                        .cornerRadius(16)
                        .padding(.horizontal, 16)
                    }
                    
                    // Default Settings
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Defaults")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primaryText)
                            .padding(.horizontal, 16)
                        
                        VStack(spacing: 0) {
                            // Week Starts On
                            HStack {
                                Image(systemName: "calendar.badge.clock")
                                    .font(.system(size: 22))
                                    .foregroundColor(.blue)
                                    .frame(width: 30)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Week Starts On")
                                        .font(.body)
                                        .foregroundColor(.primaryText)
                                    
                                    Text(settingsManager.weekStartsOn == 0 ? "Sunday" : "Monday")
                                        .font(.caption)
                                        .foregroundColor(.secondaryText)
                                }
                                
                                Spacer()
                                
                                Picker("", selection: Binding(
                                    get: { settingsManager.weekStartsOn },
                                    set: { newValue in
                                        Task {
                                            await settingsManager.updateAppSetting(\.weekStartsOn, value: newValue)
                                        }
                                    }
                                )) {
                                    Text("Sunday").tag(0)
                                    Text("Monday").tag(1)
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                .frame(width: 150)
                            }
                            .padding()
                        }
                        .background(Color.secondaryBackground)
                        .cornerRadius(16)
                        .padding(.horizontal, 16)
                    }
                    
                    // Data & Privacy
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Data & Privacy")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primaryText)
                            .padding(.horizontal, 16)
                        
                        VStack(spacing: 0) {
                            // Auto Backup
                            ToggleSettingRow(
                                icon: "icloud.and.arrow.up",
                                title: "Auto Backup",
                                subtitle: "Automatically backup data",
                                isOn: Binding(
                                    get: { settingsManager.autoBackup },
                                    set: { newValue in
                                        Task {
                                            await settingsManager.updateAppSetting(\.autoBackup, value: newValue)
                                        }
                                    }
                                ),
                                iconColor: .blue
                            )
                            
                            Divider()
                                .padding(.leading, 60)
                            
                            // Analytics
                            ToggleSettingRow(
                                icon: "chart.bar.xaxis",
                                title: "Analytics",
                                subtitle: "Help improve the app",
                                isOn: Binding(
                                    get: { settingsManager.analyticsEnabled },
                                    set: { newValue in
                                        Task {
                                            await settingsManager.updateAppSetting(\.analyticsEnabled, value: newValue)
                                        }
                                    }
                                ),
                                iconColor: .green
                            )
                        }
                        .background(Color.secondaryBackground)
                        .cornerRadius(16)
                        .padding(.horizontal, 16)
                    }
                    
                    // Reset Section
                    VStack(spacing: 16) {
                        Button(action: {
                            showingResetAlert = true
                        }) {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 16, weight: .medium))
                                Text("Reset to Default Settings")
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.errorRed)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.errorRed.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.errorRed.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                        .padding(.horizontal, 16)
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding(.top, 20)
            }
            .background(Color.primaryBackground.ignoresSafeArea())
            .navigationTitle("App Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                Task {
                    await settingsManager.loadPreferences()
                }
            }
        }
        .alert("Reset Settings", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                Task {
                    await settingsManager.resetToDefaults()
                }
            }
        } message: {
            Text("This will reset all app settings to their default values. This action cannot be undone.")
        }
        .overlay {
            if settingsManager.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.2))
            }
        }
        .sheet(isPresented: $showingUpgrade) {
            UpgradeView(purchaseManager: PurchaseService.shared, habitStore: HabitStore())
        }
    }
}

struct ToggleSettingRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    let iconColor: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(iconColor)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .foregroundColor(.primaryText)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondaryText)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding()
    }
}

#Preview {
    AppSettingsView()
        .environmentObject(ThemeManager.shared)
} 