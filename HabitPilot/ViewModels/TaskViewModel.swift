import Foundation
import SwiftUI

@MainActor
class TaskStore: ObservableObject {
    @Published var tasks: [TaskItem] = []
    @Published var isLoading: Bool = false
    
    private let userDefaults = UserDefaults.standard
    private let tasksKey = "SavedTasks"
    private let purchaseManager = PurchaseService.shared
    private let activityService = ActivityService.shared
    
    // Free version limit
    private let freeTaskLimit = 5
    
    var canAddMoreTasks: Bool {
        return purchaseManager.isUnlimitedPurchased || tasks.count < freeTaskLimit
    }
    
    var remainingFreeTasks: Int {
        return max(0, freeTaskLimit - tasks.count)
    }
    
    init(shouldLoadData: Bool = true) {
        // Don't load tasks on init - wait for user authentication
        
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
        
        // Check if user is already authenticated and load tasks (only if shouldLoadData is true)
        if shouldLoadData, case .authenticated = AuthManager.shared.authState {
            Task {
                await loadTasksFromAPI()
            }
        } else if !shouldLoadData {
        }
    }
    
    @objc private func handleUserLogin() {
        // Clear any existing tasks when user logs in
        tasks = []
        userDefaults.removeObject(forKey: tasksKey)
        
        // Data is now loaded by DataCoordinator
    }
    
    @objc private func handleUserLogout() {
        // Clear tasks when user logs out
        tasks = []
        userDefaults.removeObject(forKey: tasksKey)
    }
    
    // MARK: - API Sync Methods
    func loadTasksFromAPI() async {
        await MainActor.run {
            self.isLoading = true
        }
        
        do {
            let apiTasks = try await APIClient.shared.getTasks()
            await MainActor.run {
                self.tasks = apiTasks
                self.isLoading = false
                self.saveTasks() // Cache for offline
            }
        } catch {
            if let apiError = error as? APIError, case .unauthorized = apiError {
                AuthManager.shared.signOut()
            }
            // Clear local tasks on API failure to avoid showing old user's data
            await MainActor.run {
                self.tasks = []
                self.isLoading = false
                self.userDefaults.removeObject(forKey: self.tasksKey)
            }
        }
    }

    func addTask(title: String, category: TaskItem.TaskCategory = .today, colorHex: String = "#007AFF", priority: TaskItem.TaskPriority = .medium) async {
        guard canAddMoreTasks else {
            return
        }
        let newTask = TaskItem(title: title, category: category, colorHex: colorHex, priority: priority)
        do {
            let created = try await APIClient.shared.createTask(newTask)
            await MainActor.run {
                self.tasks.append(created)
                self.saveTasks()
                
                // Generate activity for task creation
                self.activityService.generateTaskCreatedActivity(task: created)
            }
        } catch {
        }
    }

    func addTask(_ task: TaskItem) async {
        guard canAddMoreTasks else {
            return
        }
        do {
            let created = try await APIClient.shared.createTask(task)
            await MainActor.run {
                self.tasks.append(created)
                self.saveTasks()
                
                // Generate activity for task creation
                self.activityService.generateTaskCreatedActivity(task: created)
            }
        } catch {
        }
    }

    func toggleTaskCompletion(_ task: TaskItem) async {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            var updatedTask = tasks[index]
            updatedTask.isCompleted.toggle()
            do {
                let updated = try await APIClient.shared.updateTask(updatedTask)
                await MainActor.run {
                    self.tasks[index] = updated
                    self.saveTasks()
                }
                
                // Generate activity for task completion
                if updatedTask.isCompleted {
                    print("✅ TaskStore: Task completed - \(updated.title), generating activity")
                    activityService.generateTaskCompletedActivity(task: updated)
                } else {
                    print("🔄 TaskStore: Task uncompleted - \(updated.title), no activity generated")
                }
            } catch {
            }
        }
    }

    func deleteTask(_ task: TaskItem) async {
        do {
            try await APIClient.shared.deleteTask(id: task.id)
            await MainActor.run {
                self.tasks.removeAll { $0.id == task.id }
                self.saveTasks()
            }
        } catch {
        }
    }

    func updateTaskCategory(_ task: TaskItem, newCategory: TaskItem.TaskCategory) async {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            var updatedTask = tasks[index]
            updatedTask.category = newCategory
            do {
                let updated = try await APIClient.shared.updateTask(updatedTask)
                await MainActor.run {
                    self.tasks[index] = updated
                    self.saveTasks()
                }
            } catch {
            }
        }
    }

    func updateTask(_ task: TaskItem, title: String, category: TaskItem.TaskCategory, colorHex: String, priority: TaskItem.TaskPriority) async {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            var updatedTask = tasks[index]
            updatedTask.title = title
            updatedTask.category = category
            updatedTask.colorHex = colorHex
            updatedTask.priority = priority
            do {
                let updated = try await APIClient.shared.updateTask(updatedTask)
                await MainActor.run {
                    self.tasks[index] = updated
                    self.saveTasks()
                }
            } catch {
            }
        }
    }

    private func saveTasks() {
        if let encoded = try? JSONEncoder().encode(tasks) {
            userDefaults.set(encoded, forKey: tasksKey)
        }
    }

    private func loadTasks() {
        if let data = userDefaults.data(forKey: tasksKey),
           let decoded = try? JSONDecoder().decode([TaskItem].self, from: data) {
            tasks = decoded
        }
    }
} 