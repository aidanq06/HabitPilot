import Foundation
import SwiftUI

@MainActor
class GoalStore: ObservableObject {
    @Published var goals: [Goal] = []
    
    private let userDefaults = UserDefaults.standard
    private let goalsKey = "SavedGoals"
    private let purchaseManager = PurchaseService.shared
    private let activityService = ActivityService.shared
    
    // Free version limit
    private let freeGoalLimit = 5
    
    init(shouldLoadData: Bool = true) {
        // Don't load goals on init - wait for user authentication
        
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
        
        // Check if user is already authenticated and load goals (only if shouldLoadData is true)
        if shouldLoadData, case .authenticated = AuthManager.shared.authState {
            Task {
                await loadGoalsFromAPI()
            }
        } else if !shouldLoadData {
        }
    }
    
    @objc private func handleUserLogin() {
        // Clear any existing goals when user logs in
        goals = []
        userDefaults.removeObject(forKey: goalsKey)
        
        // Data is now loaded by DataCoordinator
    }
    
    @objc private func handleUserLogout() {
        // Clear goals when user logs out
        goals = []
        userDefaults.removeObject(forKey: goalsKey)
    }
    
    var activeGoals: [Goal] {
        return goals.filter { !$0.isCompleted }
    }
    
    var completedGoals: [Goal] {
        return goals.filter { $0.isCompleted }
    }
    
    var canAddMoreGoals: Bool {
        return purchaseManager.isUnlimitedPurchased || goals.count < freeGoalLimit
    }
    

    // MARK: - API Sync Methods
    func loadGoalsFromAPI() async {
        do {
            let apiGoals = try await APIClient.shared.getGoals()
            await MainActor.run {
                self.goals = apiGoals
                self.saveGoals() // Cache for offline
            }
        } catch {
            if let apiError = error as? APIError, case .unauthorized = apiError {
                AuthManager.shared.signOut()
            }
            // Clear local goals on API failure to avoid showing old user's data
            await MainActor.run {
                self.goals = []
                self.userDefaults.removeObject(forKey: self.goalsKey)
            }
        }
    }

    func addGoal(_ goal: Goal) async {
        guard canAddMoreGoals else {
            return
        }
        do {
            let created = try await APIClient.shared.createGoal(goal)
            await MainActor.run {
                self.goals.append(created)
                self.saveGoals()
                
                // Generate activity for goal creation
                self.activityService.generateGoalCreatedActivity(goal: created)
            }
        } catch {
        }
    }

    func updateGoal(_ goal: Goal) async {
        do {
            let updated = try await APIClient.shared.updateGoal(goal)
            await MainActor.run {
                if let index = self.goals.firstIndex(where: { $0.id == updated.id }) {
                    let oldGoal = self.goals[index]
                    self.goals[index] = updated
                    self.saveGoals()
                    
                    // Generate activity for significant goal progress or completion
                    if updated.isCompleted && !oldGoal.isCompleted {
                        // Goal was just completed
                        self.activityService.generateGoalProgressActivity(goal: updated)
                    } else if updated.currentProgress > oldGoal.currentProgress {
                        // Progress was made (generate activity for milestones)
                        let progressPercentage = updated.progressPercentage
                        let oldProgressPercentage = oldGoal.progressPercentage
                        
                        // Generate activity for 25%, 50%, 75%, and 100% milestones
                        let milestones: [Double] = [0.25, 0.5, 0.75, 1.0]
                        for milestone in milestones {
                            if oldProgressPercentage < milestone && progressPercentage >= milestone {
                                self.activityService.generateGoalProgressActivity(goal: updated)
                                break
                            }
                        }
                    }
                }
            }
        } catch {
        }
    }

    func deleteGoal(_ goal: Goal) async {
        do {
            try await APIClient.shared.deleteGoal(id: goal.id)
            await MainActor.run {
                self.goals.removeAll { $0.id == goal.id }
                self.saveGoals()
            }
        } catch {
        }
    }
    
    func toggleGoalCompletion(_ goal: Goal) {
        if let index = goals.firstIndex(where: { $0.id == goal.id }) {
            goals[index].toggleCompletion()
            saveGoals()
        }
    }
    
    func updateGoalProgress(_ goal: Goal, progress: Int) {
        if let index = goals.firstIndex(where: { $0.id == goal.id }) {
            goals[index].updateProgress(progress)
            saveGoals()
        }
    }
    
    func incrementGoalProgress(_ goal: Goal) {
        if let index = goals.firstIndex(where: { $0.id == goal.id }) {
            goals[index].incrementProgress()
            saveGoals()
            
            // Create an activity for goal progress
            print("🎯 GoalStore: Goal progress - \(goal.title): \(goals[index].currentProgress)/\(goal.targetValue)")
            Task {
                do {
                    print("🌐 GoalStore: Creating goal progress activity via API...")
                    let metadata: [String: Any] = [
                        "goalId": goal.id.uuidString,
                        "goalName": goal.title,
                        "progress": goals[index].currentProgress,
                        "target": goal.targetValue
                    ]
                    
                    try await APIClient.shared.createActivity(
                        type: "goal_progress",
                        description: "Made progress on \(goal.title): \(goals[index].currentProgress)/\(goal.targetValue)",
                        metadata: metadata
                    )
                    print("✅ GoalStore: Goal progress activity sent to API successfully")
                } catch {
                    print("❌ GoalStore: Failed to send goal progress activity to API: \(error)")
                }
            }
        }
    }
    
    private func saveGoals() {
        if let encoded = try? JSONEncoder().encode(goals) {
            userDefaults.set(encoded, forKey: goalsKey)
        }
    }
    
    private func loadGoals() {
        if let data = userDefaults.data(forKey: goalsKey),
           let decoded = try? JSONDecoder().decode([Goal].self, from: data) {
            goals = decoded
        }
    }
} 