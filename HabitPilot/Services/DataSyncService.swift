import Foundation

@MainActor
class DataCoordinator: ObservableObject {
    
    private let habitStore: HabitStore
    private let goalStore: GoalStore
    private let taskStore: TaskStore
    // Add other stores/managers as needed

    init(habitStore: HabitStore, goalStore: GoalStore, taskStore: TaskStore) {
        self.habitStore = habitStore
        self.goalStore = goalStore
        self.taskStore = taskStore
    }
    
    func syncAllData() async {
        // Set loading states
        self.taskStore.isLoading = true
        
        do {
            // Fetch data concurrently for faster sync and reduced total timeout
            async let habitsTask = APIClient.shared.getHabits()
            async let goalsTask = APIClient.shared.getGoals()
            async let tasksTask = APIClient.shared.getTasks()
            
            // Wait for all requests to complete
            let (habits, goals, tasks) = try await (habitsTask, goalsTask, tasksTask)
            
            // Update stores with fetched data
            self.habitStore.habits = habits
            
            self.goalStore.goals = goals
            
            self.taskStore.tasks = tasks
            self.taskStore.isLoading = false
            
            // Add other data fetches here
            
            
        } catch {
            // Clear loading states on error
            self.taskStore.isLoading = false
            await handleSyncError(error)
        }
    }
    
    // MARK: - Error Handling with Recovery Options
    private func handleSyncError(_ error: Error) async {
        // Check if it's a network connectivity issue
        if let apiError = error as? APIError {
            switch apiError {
            case .networkError(let message):
                if message.contains("timed out") || message.contains("timeout") {
                    // Handle timeout errors
                    ()
                } else if message.contains("No internet connection") {
                    // Handle no internet connection
                    ()
                } else {
                    // Handle other network errors
                    ()
                }
                
                // Could add automatic retry after a delay for certain error types
                await scheduleRetryIfAppropriate(for: apiError)
                
            case .unauthorized:
                // Could trigger re-authentication flow
                ()
                
            case .serverError(let message):
                // Handle server errors
                ()
                
            default:
                // Handle other API errors
                ()
            }
        } else {
            // Handle non-API errors
            ()
        }
        
        // Log additional context for debugging
    }
    
    // MARK: - Automatic Retry Logic
    private func scheduleRetryIfAppropriate(for error: APIError) async {
        switch error {
        case .networkError(let message):
            // Only retry for timeout errors, not for connection issues
            if message.contains("timed out") || message.contains("timeout") {
                
                // Wait 30 seconds and try once more
                try? await Task.sleep(nanoseconds: 30_000_000_000)
                
                await syncAllData()
            }
        default:
            break
        }
    }
} 