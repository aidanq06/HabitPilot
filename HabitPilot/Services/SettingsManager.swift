import Foundation
import SwiftUI

@MainActor
class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    // Published properties for reactive UI updates
    @Published var userPreferences: UserPreferences = UserPreferences()
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // AppStorage properties for local persistence
    @AppStorage("theme") private var storedTheme = "system"
    @AppStorage("soundEffects") private var storedSoundEffects = true
    @AppStorage("hapticFeedback") private var storedHapticFeedback = true
    @AppStorage("showStreaks") private var storedShowStreaks = true
    @AppStorage("showBadges") private var storedShowBadges = true
    @AppStorage("autoBackup") private var storedAutoBackup = true
    @AppStorage("analyticsEnabled") private var storedAnalyticsEnabled = true
    @AppStorage("weekStartsOn") private var storedWeekStartsOn = 1
    @AppStorage("use24HourTime") private var storedUse24HourTime = false
    @AppStorage("notificationsEnabled") private var storedNotificationsEnabled = true
    @AppStorage("habitReminders") private var storedHabitReminders = true
    @AppStorage("challengeUpdates") private var storedChallengeUpdates = true
    @AppStorage("friendActivity") private var storedFriendActivity = true
    @AppStorage("dailyDigest") private var storedDailyDigest = false
    @AppStorage("notificationTime") private var storedNotificationTime = "20:00"
    @AppStorage("isProfilePrivate") private var storedIsProfilePrivate = false
    @AppStorage("showActivity") private var storedShowActivity = true
    @AppStorage("showStatistics") private var storedShowStatistics = true
    
    private init() {
        loadLocalPreferences()
    }
    
    // MARK: - Load Preferences
    
    func loadPreferences() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Fetch preferences from backend
            userPreferences = try await APIClient.shared.getUserPreferences()
            
            // Update local storage with backend values
            updateLocalStorage(from: userPreferences)
            
        } catch {
            errorMessage = error.localizedDescription
            // Fall back to local preferences
            loadLocalPreferences()
        }
        
        isLoading = false
    }
    
    // MARK: - Save Preferences
    
    func savePreferences() async {
        isLoading = true
        errorMessage = nil
        
        // Update preferences object from local storage
        updatePreferencesFromLocal()
        
        do {
            // Save to backend
            let savedPreferences = try await APIClient.shared.updateUserPreferences(userPreferences)
            userPreferences = savedPreferences
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Theme Settings
    
    func updateTheme(_ theme: String) async {
        storedTheme = theme
        userPreferences.theme = theme
        await savePreferences()
    }
    
    // MARK: - App Settings
    
    func updateAppSetting<T>(_ keyPath: WritableKeyPath<AppSettingsPreferences, T>, value: T) async {
        userPreferences.appSettings?[keyPath: keyPath] = value
        
        // Update local storage based on the keyPath
        switch keyPath {
        case \.soundEffects:
            storedSoundEffects = value as? Bool ?? true
        case \.hapticFeedback:
            storedHapticFeedback = value as? Bool ?? true
        case \.showStreaks:
            storedShowStreaks = value as? Bool ?? true
        case \.showBadges:
            storedShowBadges = value as? Bool ?? true
        case \.autoBackup:
            storedAutoBackup = value as? Bool ?? true
        case \.analyticsEnabled:
            storedAnalyticsEnabled = value as? Bool ?? true
        case \.weekStartsOn:
            storedWeekStartsOn = value as? Int ?? 1
        case \.use24HourTime:
            storedUse24HourTime = value as? Bool ?? false
        default:
            break
        }
        
        await savePreferences()
    }
    
    // MARK: - Notification Settings
    
    func updateNotificationSetting<T>(_ keyPath: WritableKeyPath<NotificationPreferences, T>, value: T) async {
        userPreferences.notifications?[keyPath: keyPath] = value
        
        // Update local storage based on the keyPath
        switch keyPath {
        case \.enabled:
            storedNotificationsEnabled = value as? Bool ?? true
        case \.habitReminders:
            storedHabitReminders = value as? Bool ?? true
        case \.challengeUpdates:
            storedChallengeUpdates = value as? Bool ?? true
        case \.friendActivity:
            storedFriendActivity = value as? Bool ?? true
        case \.dailyDigest:
            storedDailyDigest = value as? Bool ?? false
        case \.defaultTime:
            storedNotificationTime = value as? String ?? "20:00"
        default:
            break
        }
        
        await savePreferences()
        
        // Update notification schedules
        if keyPath == \.enabled || keyPath == \.habitReminders || keyPath == \.defaultTime {
            await NotificationManager.shared.rescheduleNotifications()
        }
    }
    
    // MARK: - Privacy Settings
    
    func updatePrivacySetting<T>(_ keyPath: WritableKeyPath<PrivacyPreferences, T>, value: T) async {
        userPreferences.privacy?[keyPath: keyPath] = value
        
        // Update local storage based on the keyPath
        switch keyPath {
        case \.isProfilePrivate:
            storedIsProfilePrivate = value as? Bool ?? false
        case \.showActivity:
            storedShowActivity = value as? Bool ?? true
        case \.showStatistics:
            storedShowStatistics = value as? Bool ?? true
        default:
            break
        }
        
        await savePreferences()
    }
    
    // MARK: - Helper Methods
    
    private func loadLocalPreferences() {
        userPreferences = UserPreferences()
        
        userPreferences.theme = storedTheme
        
        userPreferences.appSettings = AppSettingsPreferences(
            soundEffects: storedSoundEffects,
            hapticFeedback: storedHapticFeedback,
            showStreaks: storedShowStreaks,
            showBadges: storedShowBadges,
            autoBackup: storedAutoBackup,
            analyticsEnabled: storedAnalyticsEnabled,
            weekStartsOn: storedWeekStartsOn,
            use24HourTime: storedUse24HourTime
        )
        
        userPreferences.notifications = NotificationPreferences(
            enabled: storedNotificationsEnabled,
            habitReminders: storedHabitReminders,
            challengeUpdates: storedChallengeUpdates,
            friendActivity: storedFriendActivity,
            dailyDigest: storedDailyDigest,
            defaultTime: storedNotificationTime
        )
        
        userPreferences.privacy = PrivacyPreferences(
            isProfilePrivate: storedIsProfilePrivate,
            showActivity: storedShowActivity,
            showStatistics: storedShowStatistics
        )
    }
    
    private func updateLocalStorage(from preferences: UserPreferences) {
        storedTheme = preferences.theme ?? "system"
        
        if let appSettings = preferences.appSettings {
            storedSoundEffects = appSettings.soundEffects
            storedHapticFeedback = appSettings.hapticFeedback
            storedShowStreaks = appSettings.showStreaks
            storedShowBadges = appSettings.showBadges
            storedAutoBackup = appSettings.autoBackup
            storedAnalyticsEnabled = appSettings.analyticsEnabled
            storedWeekStartsOn = appSettings.weekStartsOn
            storedUse24HourTime = appSettings.use24HourTime
        }
        
        if let notifications = preferences.notifications {
            storedNotificationsEnabled = notifications.enabled
            storedHabitReminders = notifications.habitReminders
            storedChallengeUpdates = notifications.challengeUpdates
            storedFriendActivity = notifications.friendActivity
            storedDailyDigest = notifications.dailyDigest
            storedNotificationTime = notifications.defaultTime ?? "20:00"
        }
        
        if let privacy = preferences.privacy {
            storedIsProfilePrivate = privacy.isProfilePrivate
            storedShowActivity = privacy.showActivity
            storedShowStatistics = privacy.showStatistics
        }
    }
    
    private func updatePreferencesFromLocal() {
        loadLocalPreferences()
    }
    
    // MARK: - Export/Import Settings
    
    func exportSettings() -> Data? {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            return try encoder.encode(userPreferences)
        } catch {
            errorMessage = "Failed to export settings: \(error.localizedDescription)"
            return nil
        }
    }
    
    func importSettings(from data: Data) async {
        do {
            let decoder = JSONDecoder()
            let importedPreferences = try decoder.decode(UserPreferences.self, from: data)
            
            // Update local preferences
            userPreferences = importedPreferences
            updateLocalStorage(from: importedPreferences)
            
            // Save to backend
            await savePreferences()
            
        } catch {
            errorMessage = "Failed to import settings: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Reset Settings
    
    func resetToDefaults() async {
        userPreferences = UserPreferences()
        updateLocalStorage(from: userPreferences)
        await savePreferences()
    }
}

// MARK: - Convenience Extensions

extension SettingsManager {
    var theme: String { storedTheme }
    var soundEffects: Bool { storedSoundEffects }
    var hapticFeedback: Bool { storedHapticFeedback }
    var showStreaks: Bool { storedShowStreaks }
    var showBadges: Bool { storedShowBadges }
    var autoBackup: Bool { storedAutoBackup }
    var analyticsEnabled: Bool { storedAnalyticsEnabled }
    var weekStartsOn: Int { storedWeekStartsOn }
    var use24HourTime: Bool { storedUse24HourTime }
    var notificationsEnabled: Bool { storedNotificationsEnabled }
    var habitReminders: Bool { storedHabitReminders }
    var challengeUpdates: Bool { storedChallengeUpdates }
    var friendActivity: Bool { storedFriendActivity }
    var dailyDigest: Bool { storedDailyDigest }
    var notificationTime: String { storedNotificationTime }
    var isProfilePrivate: Bool { storedIsProfilePrivate }
    var showActivity: Bool { storedShowActivity }
    var showStatistics: Bool { storedShowStatistics }
} 