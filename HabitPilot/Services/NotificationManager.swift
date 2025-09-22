import Foundation
import UserNotifications

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    private init() {}
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
        }
    }
    
    func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
        }
    }
    
    func scheduleNotification(for habit: Habit) {
        guard habit.isEnabled else { 
            return 
        }
        
        // Remove existing notifications for this habit
        removeNotification(for: habit)
        
        // Schedule notifications for all reminder times
        for (index, reminderTime) in habit.multipleReminders.enumerated() {
            scheduleSingleNotification(for: habit, at: reminderTime, identifier: "habit-\(habit.id.uuidString)-\(index)")
        }
    }
    
    private func scheduleSingleNotification(for habit: Habit, at time: Date, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = "🌟 \(habit.name)"
        content.body = createNotificationBody(for: habit)
        content.sound = .default
        content.badge = 1
        
        // Create date components for the notification time using user's local timezone
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        
        // Ensure we're using the user's local timezone for consistent scheduling
        var localComponents = DateComponents()
        localComponents.hour = components.hour
        localComponents.minute = components.minute
        
        // Check if the time has already passed today
        let now = Date()
        let _ = calendar.date(bySettingHour: components.hour ?? 0, minute: components.minute ?? 0, second: 0, of: now) ?? now
        
        // Create trigger that repeats daily (or based on frequency for premium users)
        let trigger: UNNotificationTrigger
        
        if habit.frequency == .daily {
            // Daily notification - will start from the next occurrence of this time
            trigger = UNCalendarNotificationTrigger(dateMatching: localComponents, repeats: true)
        } else {
            // For non-daily frequencies, we need to create custom triggers
            // This is a simplified implementation - in a real app, you'd create more sophisticated triggers
            trigger = UNCalendarNotificationTrigger(dateMatching: localComponents, repeats: true)
        }
        
        // Create request with unique identifier
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        // Schedule the notification
        UNUserNotificationCenter.current().add(request) { error in
        }
    }
    
    func removeNotification(for habit: Habit) {
        // Remove all notifications for this habit (including multiple reminders)
        let identifiers = habit.multipleReminders.indices.map { "habit-\(habit.id.uuidString)-\($0)" }
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    func updateNotification(for habit: Habit) {
        removeNotification(for: habit)
        scheduleNotification(for: habit)
        
        // Verify the notification was scheduled correctly
        verifyNotificationScheduling(for: habit)
    }
    
    func removeAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    func rescheduleNotifications() async {
        // Get all habits from HabitStore and reschedule their notifications
        await MainActor.run {
            let habitStore = HabitStore()
            for habit in habitStore.habits {
                if habit.isEnabled && habit.notificationTime != nil {
                    scheduleNotification(for: habit)
                }
            }
        }
    }
    
    // MARK: - Notification Content Helpers
    
    private func createNotificationBody(for habit: Habit) -> String {
        let customMessage = habit.reminderMessage.isEmpty ? nil : habit.reminderMessage
        
        // Get streak info for motivation
        let streakText = habit.streak > 0 ? "🔥 \(habit.streak) day streak!" : ""
        
        // Create motivational messages based on habit category
        let motivationalMessage = getMotivationalMessage(for: habit)
        
        // Build the notification body
        var body = ""
        
        if let custom = customMessage {
            body = custom
        } else {
            body = "Time to complete your habit!"
        }
        
        // Add streak if available
        if !streakText.isEmpty {
            body += "\n\(streakText)"
        }
        
        // Add motivational message
        if !motivationalMessage.isEmpty {
            body += "\n\(motivationalMessage)"
        }
        
        return body
    }
    
    private func getMotivationalMessage(for habit: Habit) -> String {
        // Get category from habit name or description to provide relevant motivation
        let name = habit.name.lowercased()
        let _ = habit.description.lowercased()
        
        // Morning routine habits
        if name.contains("water") || name.contains("drink") {
            return "💧 Stay hydrated and energized!"
        } else if name.contains("bed") || name.contains("make") {
            return "🛏️ Start your day with a win!"
        } else if name.contains("exercise") || name.contains("workout") || name.contains("run") {
            return "💪 Get your body moving!"
        } else if name.contains("meditate") || name.contains("mindfulness") {
            return "🧘 Find your inner peace!"
        }
        
        // Health & wellness habits
        else if name.contains("walk") || name.contains("steps") {
            return "🚶‍♂️ Keep moving, stay healthy!"
        } else if name.contains("vitamin") || name.contains("pill") {
            return "💊 Supporting your health daily!"
        } else if name.contains("stretch") || name.contains("flexibility") {
            return "🤸‍♀️ Keep your body flexible!"
        }
        
        // Productivity habits
        else if name.contains("read") || name.contains("book") {
            return "📚 Expand your knowledge!"
        } else if name.contains("plan") || name.contains("organize") {
            return "📋 Set yourself up for success!"
        } else if name.contains("phone") || name.contains("screen") {
            return "📱 Better sleep starts now!"
        }
        
        // Learning habits
        else if name.contains("learn") || name.contains("study") || name.contains("skill") {
            return "🎓 Invest in your growth!"
        } else if name.contains("language") || name.contains("practice") {
            return "🗣️ Build your fluency!"
        }
        
        // Mindfulness habits
        else if name.contains("journal") || name.contains("write") {
            return "✍️ Reflect on your journey!"
        } else if name.contains("gratitude") || name.contains("thankful") {
            return "🙏 Focus on the positive!"
        }
        
        // Default motivational messages
        let defaultMessages = [
            "✨ You've got this!",
            "🚀 Small steps, big results!",
            "💫 Consistency is key!",
            "🌟 Building better habits!",
            "🎯 Stay focused, stay motivated!"
        ]
        
        return defaultMessages.randomElement() ?? "✨ You've got this!"
    }
    
    // MARK: - Premium Features
    
    func scheduleFlexibleNotification(for habit: Habit) {
        guard habit.isEnabled else { return }
        
        // Remove existing notifications
        removeNotification(for: habit)
        
        // Schedule based on frequency
        switch habit.frequency {
        case .daily:
            scheduleDailyNotifications(for: habit)
        case .everyOtherDay:
            scheduleEveryOtherDayNotifications(for: habit)
        case .threeTimesWeek:
            scheduleThreeTimesWeekNotifications(for: habit)
        case .twiceWeek:
            scheduleTwiceWeekNotifications(for: habit)
        case .onceWeek:
            scheduleOnceWeekNotifications(for: habit)
        case .custom:
            scheduleCustomFrequencyNotifications(for: habit)
        }
    }
    
    private func scheduleDailyNotifications(for habit: Habit) {
        for (index, reminderTime) in habit.multipleReminders.enumerated() {
            scheduleSingleNotification(for: habit, at: reminderTime, identifier: "habit-\(habit.id.uuidString)-\(index)")
        }
    }
    
    private func scheduleEveryOtherDayNotifications(for habit: Habit) {
        // Simplified implementation - in a real app, you'd create more sophisticated triggers
        for (index, reminderTime) in habit.multipleReminders.enumerated() {
            scheduleSingleNotification(for: habit, at: reminderTime, identifier: "habit-\(habit.id.uuidString)-\(index)")
        }
    }
    
    private func scheduleThreeTimesWeekNotifications(for habit: Habit) {
        // Schedule for Monday, Wednesday, Friday
        let weekdays: [Int] = [2, 4, 6] // Monday, Wednesday, Friday
        
        for weekday in weekdays {
            for (index, reminderTime) in habit.multipleReminders.enumerated() {
                scheduleWeeklyNotification(for: habit, at: reminderTime, weekday: weekday, identifier: "habit-\(habit.id.uuidString)-\(weekday)-\(index)")
            }
        }
    }
    
    private func scheduleTwiceWeekNotifications(for habit: Habit) {
        // Schedule for Monday and Thursday
        let weekdays: [Int] = [2, 5] // Monday, Thursday
        
        for weekday in weekdays {
            for (index, reminderTime) in habit.multipleReminders.enumerated() {
                scheduleWeeklyNotification(for: habit, at: reminderTime, weekday: weekday, identifier: "habit-\(habit.id.uuidString)-\(weekday)-\(index)")
            }
        }
    }
    
    private func scheduleOnceWeekNotifications(for habit: Habit) {
        // Schedule for Monday
        for (index, reminderTime) in habit.multipleReminders.enumerated() {
            scheduleWeeklyNotification(for: habit, at: reminderTime, weekday: 2, identifier: "habit-\(habit.id.uuidString)-2-\(index)")
        }
    }
    
    private func scheduleCustomFrequencyNotifications(for habit: Habit) {
        guard habit.customFrequency != nil else { return }
        
        // Simplified implementation - schedule daily but the habit logic will handle frequency
        for (index, reminderTime) in habit.multipleReminders.enumerated() {
            scheduleSingleNotification(for: habit, at: reminderTime, identifier: "habit-\(habit.id.uuidString)-\(index)")
        }
    }
    
    private func scheduleWeeklyNotification(for habit: Habit, at time: Date, weekday: Int, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = "🌟 \(habit.name)"
        content.body = createNotificationBody(for: habit)
        content.sound = .default
        content.badge = 1
        
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        
        // Ensure we're using the user's local timezone for consistent scheduling
        var localComponents = DateComponents()
        localComponents.hour = timeComponents.hour
        localComponents.minute = timeComponents.minute
        localComponents.weekday = weekday
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: localComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
        }
    }
    
    // MARK: - Verification Methods
    
    private func verifyNotificationScheduling(for habit: Habit) {
        let identifiers = habit.multipleReminders.indices.map { "habit-\(habit.id.uuidString)-\($0)" }
        
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let habitNotifications = requests.filter { identifiers.contains($0.identifier) }
            
            for notification in habitNotifications {
                if let trigger = notification.trigger as? UNCalendarNotificationTrigger {
                    let _ = trigger.nextTriggerDate()
                }
            }
            
            if habitNotifications.count != identifiers.count {
            } else {
            }
        }
    }
    
    // MARK: - Debug Methods
    
    func listAllScheduledNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
        }
    }
    
    // MARK: - Test Methods
    
    func sendTestNotification() {
        
        let content = UNMutableNotificationContent()
        content.title = "🦪 Test Notification"
        content.body = "This is a test notification from HabitPilot!"
        content.sound = .default
        content.badge = 1
        
        // Schedule for 5 seconds from now
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "test-notification",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
        }
    }
    
    func scheduleNotificationForTomorrow(for habit: Habit) {
        
        let content = UNMutableNotificationContent()
        content.title = "🌟 \(habit.name)"
        content.body = createNotificationBody(for: habit)
        content.sound = .default
        content.badge = 1
        
        // Schedule for tomorrow at the habit's time
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        guard let notificationTime = habit.notificationTime else {
            return
        }
        let components = calendar.dateComponents([.hour, .minute], from: notificationTime)
        
        var tomorrowComponents = DateComponents()
        tomorrowComponents.year = calendar.component(.year, from: tomorrow)
        tomorrowComponents.month = calendar.component(.month, from: tomorrow)
        tomorrowComponents.day = calendar.component(.day, from: tomorrow)
        tomorrowComponents.hour = components.hour
        tomorrowComponents.minute = components.minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: tomorrowComponents, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "habit-\(habit.id.uuidString)-tomorrow",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
        }
    }
} 