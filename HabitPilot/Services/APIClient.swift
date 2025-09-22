import Foundation

import Foundation

struct HabitCompletionResponse: Codable {
    let progress: Int
    let target: Int
    let streak: Int
    let completed: Bool
}

class APIClient: ObservableObject {
    static let shared = APIClient()
    private let session: URLSession
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
    }

    func login(username: String, password: String) async throws -> User {
        return User(id: UUID().uuidString, username: username, email: nil, createdAt: Date(), lastLoginAt: Date())
    }

    func register(username: String, password: String) async throws -> User {
        return User(id: UUID().uuidString, username: username, email: nil, createdAt: Date(), lastLoginAt: Date())
    }
    
    func completeHabit(_ habit: Habit) async throws -> HabitCompletionResponse {
        return HabitCompletionResponse(progress: habit.progress + 1, target: habit.target, streak: habit.streak + 1, completed: true)
    }
    
    func getUserPreferences() async throws -> UserPreferences {
            return UserPreferences()
    }
    
    func updateUserPreferences(_ preferences: UserPreferences) async throws -> UserPreferences {
        return preferences
    }
}
