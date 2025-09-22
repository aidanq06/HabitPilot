import Foundation
import SwiftUI

@MainActor
class HabitStore: ObservableObject {
    @Published var habits: [Habit] = []
    var goalStore: GoalStore?
    private let notificationManager = NotificationManager.shared
    private let purchaseManager = PurchaseService.shared
    private let activityService = ActivityService.shared
    
    private let userDefaults = UserDefaults.standard
    private let habitsKey = "SavedHabits"
    
    // Free version limit
    private let freeHabitLimit = 5
    
    init(shouldLoadData: Bool = true) {
        // Don't load habits on init - wait for user authentication
        notificationManager.requestPermission()
        
        // Listen for user login/logout notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleUserLogin),
            name: .userDidLogin,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleUserLogout),
            name: .userDidLogout,
            object: nil
        )
        
        // Listen for habit refresh requests (e.g., after joining challenges)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleHabitRefreshRequest),
            name: .shouldRefreshHabits,
            object: nil
        )
        
        // Check if user is already authenticated and load habits (only if shouldLoadData is true)
        if shouldLoadData, case .authenticated = AuthManager.shared.authState {
            Task {
                await loadHabitsFromAPI()
            }
        } else if !shouldLoadData {
        }
    }
    
    var canAddMoreHabits: Bool {
        return purchaseManager.isUnlimitedPurchased || habits.count < freeHabitLimit
    }
    
    var remainingFreeHabits: Int {
        return max(0, freeHabitLimit - habits.count)
    }
    
    // Computed properties for better performance
    var enabledHabits: [Habit] {
        habits.filter { $0.isEnabled }
    }
    
    var completedTodayCount: Int {
        habits.filter { $0.isCompletedToday() }.count
    }
    
    var incrementalHabits: [Habit] {
        habits.filter { $0.type == .incremental }
    }
    
    var simpleHabits: [Habit] {
        habits.filter { $0.type == .simple }
    }
    
    // MARK: - API Methods
    
    func loadHabitsFromAPI() async {
        
        do {
            let apiHabits = try await APIClient.shared.getHabits()
            
            await MainActor.run {
                
                if apiHabits.isEmpty {
                } else {
                }
                
                self.habits = apiHabits
                
                self.saveHabitsLocally() // Cache for offline access
            }
        } catch {
            
            if let apiError = error as? APIError {
                
                switch apiError {
                case .unauthorized:
                    AuthManager.shared.signOut()
                case .networkError(let message):
                    break
                case .serverError(let message):
                    break
                case .invalidResponse:
                    break
                case .decodingError:
                    break
                }
            }
            
            await MainActor.run {
                self.habits = []
                self.userDefaults.removeObject(forKey: self.habitsKey)
            }
        }
    }
    
    func addHabit(_ habit: Habit) {
        guard canAddMoreHabits else {
            return
        }
        
        Task {
            do {
                let newHabit = try await APIClient.shared.createHabit(
                    name: habit.name,
                    description: habit.description,
                    type: habit.type,
                    frequency: habit.frequency,
                    dailyTarget: habit.dailyTarget,
                    notificationTime: habit.notificationTime ?? Date(),
                    colorHex: habit.colorHex,
                    isEnabled: habit.isEnabled
                )
                
                await MainActor.run {
                    self.habits.append(newHabit)
                    self.saveHabitsLocally()
                    
                    // Use flexible scheduling for premium users
                    if self.purchaseManager.isUnlimitedPurchased {
                        self.notificationManager.scheduleFlexibleNotification(for: newHabit)
                    } else {
                        self.notificationManager.scheduleNotification(for: newHabit)
                    }
                    
                    // Generate activity for habit creation
                    self.activityService.generateHabitCreatedActivity(habit: newHabit)
                    
                    // Force UI update
                    self.objectWillChange.send()
                }
            } catch {
                // Fall back to local storage
                await MainActor.run {
                    self.habits.append(habit)
                    self.saveHabitsLocally()
                    
                    // Generate activity for habit creation
                    self.activityService.generateHabitCreatedActivity(habit: habit)
                }
            }
        }
    }
    
    func updateHabit(_ habit: Habit) {
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            if let oldTime = habits[index].notificationTime {
                // Old notification time: \(oldTime.formatted(date: .omitted, time: .shortened))")
            } else {
                // Old notification time: None")
            }
            if let newTime = habit.notificationTime {
                // New notification time: \(newTime.formatted(date: .omitted, time: .shortened))")
            } else {
                // New notification time: None")
            }
            // Old enabled: \(habits[index].isEnabled)")
            // New enabled: \(habit.isEnabled)")
            
            Task {
                do {
                    let updatedHabit = try await APIClient.shared.updateHabit(habit)
                    await MainActor.run {
                        self.habits[index] = updatedHabit
                        self.saveHabitsLocally()
                        
                        // Use flexible scheduling for premium users
                        if self.purchaseManager.isUnlimitedPurchased {
                            self.notificationManager.scheduleFlexibleNotification(for: updatedHabit)
                        } else {
                            self.notificationManager.updateNotification(for: updatedHabit)
                        }
                        
                        // List all notifications for debugging
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self.notificationManager.listAllScheduledNotifications()
                        }
                    }
                } catch {
                    // Fall back to local update
                    await MainActor.run {
                        self.habits[index] = habit
                        self.saveHabitsLocally()
                    }
                }
            }
        }
    }
    
    func deleteHabit(_ habit: Habit) {
        habits.removeAll { $0.id == habit.id }
        saveHabitsLocally()
        notificationManager.removeNotification(for: habit)
        
        Task {
            do {
                try await APIClient.shared.deleteHabit(habit)
            } catch {
                // Habit was already removed locally, so we're good
            }
        }
    }
    
    func toggleHabitCompletion(_ habit: Habit) {
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            let wasCompleted = habits[index].isCompletedToday()
            
            if wasCompleted {
                // Undo completion - properly handle streak
                habits[index].undoCompletedToday()
                saveHabitsLocally()
                
                // Call backend API to undo completion
                Task {
                    do {
                        let undoResponse = try await APIClient.shared.undoHabit(habit)
                        
                        // Update local habit with server response
                        await MainActor.run {
                            if let index = self.habits.firstIndex(where: { $0.id == habit.id }) {
                                // For undo, trust our local calculation more than backend
                                let localStreak = self.habits[index].streak
                                let serverStreak = undoResponse.streak
                                
                                // Only update if there's a significant discrepancy (more than 1 difference)
                                if abs(serverStreak - localStreak) > 1 {
                                    self.habits[index].streak = serverStreak
                                }
                                
                                self.habits[index].todayProgress = undoResponse.progress
                                self.saveHabitsLocally()
                            }
                        }
                    } catch {
                    }
                }
            } else {
                // Complete habit
                habits[index].markCompleted()
                
                // Generate activity for habit completion/streak
                let completedHabit = habits[index]
                
                // Generate activity for habit completion
                activityService.generateHabitStreakActivity(habit: completedHabit)
                
                // Increment progress on any linked goal
                if let goalStore = goalStore {
                    for goal in goalStore.goals where goal.linkedHabitID == habit.id && !goal.isCompleted {
                        goalStore.incrementGoalProgress(goal)
                    }
                }
                
                saveHabitsLocally()
                
                // Call backend API to complete habit (this will also update challenge progress)
                Task {
                    do {
                        let completionResponse = try await APIClient.shared.completeHabit(habit)
                        
                        // Update local habit with server response
                        await MainActor.run {
                            if let index = self.habits.firstIndex(where: { $0.id == habit.id }) {
                                // For completion, trust our local calculation more than backend
                                // Only update if backend streak is significantly different (indicating an error)
                                let localStreak = self.habits[index].streak
                                let serverStreak = completionResponse.streak
                                
                                // Only update if there's a significant discrepancy (more than 1 difference)
                                if abs(serverStreak - localStreak) > 1 {
                                    self.habits[index].streak = serverStreak
                                }
                                
                                self.habits[index].todayProgress = completionResponse.progress
                                self.saveHabitsLocally()
                            }
                        }
                        
                        // Create an activity for habit completion
                        let metadata: [String: Any] = [
                            "habitId": habit.id.uuidString,
                            "habitName": habit.name,
                            "streak": completionResponse.streak
                        ]
                        
                        try await APIClient.shared.createActivity(
                            type: "habit_completed",
                            description: "Completed \(habit.name)",
                            metadata: metadata
                        )
                    } catch {
                        // Local completion already done, so don't fail entirely
                    }
                }
            }
        }
    }
    
    func toggleHabitEnabled(_ habit: Habit) {
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            habits[index].isEnabled.toggle()
            saveHabitsLocally()
            
            if habits[index].isEnabled {
                notificationManager.scheduleNotification(for: habits[index])
            } else {
                notificationManager.removeNotification(for: habit)
            }
        }
    }
    
    func incrementHabitProgress(_ habit: Habit) {
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            var updatedHabit = habits[index]
            updatedHabit.incrementProgress()
            
            habits[index] = updatedHabit
            saveHabitsLocally()
        }
    }
    
    // MARK: - User Authentication Methods
    
    @objc private func handleUserLogin() {
        
        // Clear any existing habits when user logs in
        habits = []
        userDefaults.removeObject(forKey: habitsKey)
        
        // Data is now loaded by DataCoordinator
    }
    
    @objc private func handleUserLogout() {
        // Clear habits when user logs out
        habits = []
        userDefaults.removeObject(forKey: habitsKey)
    }
    
    @objc private func handleHabitRefreshRequest() {
        Task {
            await loadHabitsFromAPI()
        }
    }
    
    func onUserLogin() {
        handleUserLogin()
    }
    
    func onUserLogout() {
        handleUserLogout()
    }
    
    // MARK: - Private Methods
    
    private func saveHabitsLocally() {
        
        if let encoded = try? JSONEncoder().encode(habits) {
            userDefaults.set(encoded, forKey: habitsKey)
        } else {
        }
    }
    
    private func loadHabitsLocally() {
        if let data = userDefaults.data(forKey: habitsKey),
           let decoded = try? JSONDecoder().decode([Habit].self, from: data) {
            habits = decoded
        }
    }
} 