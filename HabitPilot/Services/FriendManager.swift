import Foundation
import SwiftUI

@MainActor
class FriendManager: ObservableObject {
    @Published var friends: [Friend] = []
    @Published var friendRequests: [FriendRequest] = []
    @Published var activities: [SocialActivity] = []
    @Published var analytics: [Analytics] = []
    @Published var isLoading = false
    @Published var searchResults: [User] = []
    @Published var errorMessage: String?
    @Published var outgoingRequests: [FriendRequest] = []
    @Published var friendStatistics: [String: UserStatistics] = [:] // userId -> UserStatistics
    
    private var refreshTimer: Timer?
    private let refreshInterval: TimeInterval = 300 // 5 minutes
    
    private let userDefaults = UserDefaults.standard
    private let friendsKey = "userFriends"
    private let requestsKey = "friendRequests"
    private let outgoingRequestsKey = "outgoingFriendRequests"
    private let activitiesKey = "userActivities"
    private let analyticsKey = "userAnalytics"
    private let apiClient = APIClient.shared
    
    // Toggle between local and API mode
    private let useAPI = APIConfig.useAPI
    
    static let shared = FriendManager()
    
    private init() {
        loadFriends()
        loadFriendRequests()
        loadOutgoingRequests()
        loadActivities()
        loadAnalytics()
        // Activities will be generated from real user actions via ActivityService
        
        // Listen for user login/logout events
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
        
        // Sync with API if user is already logged in
        if getCurrentUser() != nil && useAPI {
            Task {
                await syncWithAPI()
                await loadFriendStatistics()
                
                // Start periodic refresh
                await MainActor.run {
                    startPeriodicRefresh()
                }
            }
        }
    }
    
    @objc private func handleUserLogin() {
        // Clear old data and sync with API for new user
        clearAllData()
        
        if useAPI {
            Task {
                await syncWithAPI()
                await loadFriendStatistics()
                
                // Start periodic refresh after initial load
                await MainActor.run {
                    startPeriodicRefresh()
                }
            }
        } else {
            // For local mode, just reload empty data
            loadFriends()
            loadFriendRequests()
            loadOutgoingRequests()
            loadActivities()
            loadAnalytics()
            Task {
                await loadFriendStatistics()
            }
        }
    }
    
    @objc private func handleUserLogout() {
        // Stop periodic refresh
        stopPeriodicRefresh()
        
        // Clear all data when user logs out
        clearAllData()
    }
    
    private func clearAllData() {
        friends = []
        friendRequests = []
        outgoingRequests = []
        activities = []
        analytics = []
        searchResults = []
        errorMessage = nil
        
        // Clear from UserDefaults
        userDefaults.removeObject(forKey: friendsKey)
        userDefaults.removeObject(forKey: requestsKey)
        userDefaults.removeObject(forKey: outgoingRequestsKey)
        userDefaults.removeObject(forKey: activitiesKey)
        userDefaults.removeObject(forKey: analyticsKey)
        userDefaults.synchronize()
    }
    
    // MARK: - Friend Management
    
    func sendFriendRequest(to username: String, message: String? = nil) async -> Bool {
        guard let currentUser = getCurrentUser() else {
            errorMessage = "No current user"
            return false
        }
        
        
        if useAPI {
            // API Mode
            do {
                // Check if user is authenticated
                if case .notAuthenticated = AuthManager.shared.authState {
                    errorMessage = "Please log in to send friend requests"
                    return false
                }
                
                // First, search for the user to get their ID (case-insensitive exact match)
                let searchResponse = try await apiClient.searchUsers(query: username)
                guard let targetUser = searchResponse.users.first(where: { $0.username.lowercased() == username.lowercased() }) else {
                    errorMessage = "User not found"
                    return false
                }
                
                
                let _ = try await apiClient.sendFriendRequest(to: targetUser.id, message: message)
                errorMessage = nil
                await syncWithAPI()
                return true
            } catch {
                // Use centralized error handling for better user feedback
                ErrorHandlingService.shared.handle(error, context: ErrorContext.friendRequest.rawValue) { [weak self] in
                    Task {
                        await self?.sendFriendRequest(to: username, message: message)
                    }
                }
                
                // Also store error for backwards compatibility
                if let apiError = error as? APIError {
                    errorMessage = APIUtilities.getUserFriendlyErrorMessage(apiError)
                } else {
                    errorMessage = APIUtilities.handleNetworkError(error)
                }
                
                await syncWithAPI() // Always sync after error
                return false
            }
        } else {
            // Local Mode (current implementation)
            // Simulate network delay
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            
            // Simulate finding a user (case-insensitive exact match)
            let targetUser = User(id: UUID().uuidString, username: username, email: nil, createdAt: Date(), lastLoginAt: Date(), isAppleUser: false)
            
            // Check if request already exists
            if friendRequests.contains(where: { 
                $0.fromUserId == currentUser.id && 
                $0.toUserId == targetUser.id && 
                $0.status == .pending 
            }) {
                errorMessage = "Request already exists"
                return false
            }
            
            // Check if already friends
            if friends.contains(where: { 
                $0.userId == currentUser.id && 
                $0.friendId == targetUser.id && 
                $0.status == .accepted 
            }) {
                errorMessage = "Already friends"
                return false
            }
            
            let request = FriendRequest(
                fromUserId: currentUser.id,
                fromUsername: currentUser.username,
                toUserId: targetUser.id,
                toUsername: targetUser.username,
                message: message
            )
            
            outgoingRequests.append(request)
            saveOutgoingRequests()
            
            return true
        }
    }
    
    func cancelFriendRequest(to username: String) async -> Bool {
        guard let currentUser = getCurrentUser() else {
            errorMessage = "No current user"
            return false
        }
        if useAPI {
            // API Mode
            do {
                // Find the pending request you sent to this username
                guard let request = friendRequests.first(where: { $0.toUsername.lowercased() == username.lowercased() && $0.fromUserId == currentUser.id && $0.status == .pending }) else {
                    errorMessage = "No pending request found to cancel"
                    return false
                }
                let _ = try await apiClient.cancelFriendRequest(requestId: request.id)
                errorMessage = nil
                await syncWithAPI()
                return true
            } catch {
                errorMessage = error.localizedDescription
                await syncWithAPI()
                return false
            }
        } else {
            // Local Mode (current implementation)
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            if let index = outgoingRequests.firstIndex(where: { $0.fromUserId == currentUser.id && $0.toUsername == username && $0.status == .pending }) {
                outgoingRequests.remove(at: index)
                saveOutgoingRequests()
                return true
            }
            return false
        }
    }
    
    func acceptFriendRequest(_ request: FriendRequest) async {
        guard let currentUser = getCurrentUser() else { 
            return 
        }
        
        
        if useAPI {
            // API Mode
            do {
                let _ = try await apiClient.acceptFriendRequest(requestId: request.id)
                // Refresh data from server
                await syncWithAPI()
                errorMessage = nil
            } catch {
                // Check if it's a 404 error
                if error.localizedDescription.contains("not found") {
                    errorMessage = "This friend request has already been processed. Pull down to refresh."
                    // Force refresh to get latest data
                    await forceRefresh()
                } else {
                    errorMessage = error.localizedDescription
                }
            }
        } else {
            // Local Mode (current implementation)
            // Remove the request from incoming requests
            friendRequests.removeAll { $0.id == request.id }
            
            // Create friend relationship
            let friend = Friend(
                userId: currentUser.id,
                friendId: request.fromUserId,
                friendUsername: request.fromUsername,
                status: .accepted
            )
            
            friends.append(friend)
            saveFriends()
            saveFriendRequests()
        }
    }
    
    func declineFriendRequest(_ request: FriendRequest) async {
        
        if useAPI {
            // API Mode
            do {
                let _ = try await apiClient.declineFriendRequest(requestId: request.id)
                // Refresh data from server
                await syncWithAPI()
                errorMessage = nil
            } catch {
                // Check if it's a 404 error
                if error.localizedDescription.contains("not found") {
                    errorMessage = "This friend request has already been processed. Pull down to refresh."
                    // Force refresh to get latest data
                    await forceRefresh()
                } else {
                    errorMessage = error.localizedDescription
                }
            }
        } else {
            // Local Mode (current implementation)
            // Remove the request from incoming requests
            friendRequests.removeAll { $0.id == request.id }
            saveFriendRequests()
        }
    }
    
    func removeFriend(_ friend: Friend) async {
        if useAPI {
            // API Mode
            do {
                _ = try await apiClient.removeFriend(friendId: friend.friendId)
                // Refresh data from server
                await syncWithAPI()
                errorMessage = nil
            } catch {
                errorMessage = error.localizedDescription
            }
        } else {
            // Local Mode (current implementation)
            friends.removeAll { $0.id == friend.id }
            saveFriends()
        }
    }
    
    func blockFriend(_ friend: Friend) async {
        if useAPI {
            // API Mode
            do {
                _ = try await apiClient.blockUser(userId: friend.friendId)
                // Refresh data from server
                await syncWithAPI()
                errorMessage = nil
            } catch {
                errorMessage = error.localizedDescription
            }
        } else {
            // Local Mode (current implementation)
            if let index = friends.firstIndex(where: { $0.id == friend.id }) {
                friends[index] = Friend(
                    userId: friend.userId,
                    friendId: friend.friendId,
                    friendUsername: friend.friendUsername,
                    status: .blocked
                )
                saveFriends()
            }
        }
    }
    
    // MARK: - API Sync
    
    func syncWithAPI() async {
        guard useAPI else { return }
        
        
        do {
            let response = try await apiClient.getFriendsAndRequests()
            
            
            friends = response.friends
            friendRequests = response.requests
            outgoingRequests = response.outgoingRequests
            saveFriends()
            saveFriendRequests()
            saveOutgoingRequests()
            
            // Load friend statistics after syncing
            await loadFriendStatistics()
            
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // Force refresh by clearing local data first
    func forceRefresh() async {
        
        // Clear all local data
        friends = []
        friendRequests = []
        outgoingRequests = []
        errorMessage = nil
        
        // Clear from UserDefaults
        userDefaults.removeObject(forKey: friendsKey)
        userDefaults.removeObject(forKey: requestsKey)
        userDefaults.removeObject(forKey: outgoingRequestsKey)
        userDefaults.synchronize()
        
        // Now sync with API
        await syncWithAPI()
    }
    
    // Manual refresh function that can be called from UI
    func refreshFriends() async {
        await syncWithAPI()
    }
    
    // MARK: - Search
    
    func searchUsers(query: String) async {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        // Check if user is authenticated for API calls
        if useAPI {
            guard let currentUser = getCurrentUser() else {
                errorMessage = "Please log in to search for users"
                searchResults = []
                return
            }
        }
        
        isLoading = true
        errorMessage = nil
        
        if useAPI {
            // API Mode
            do {
                let response = try await apiClient.searchUsers(query: query)
                searchResults = response.users
            } catch {
                errorMessage = error.localizedDescription
                searchResults = []
            }
        } else {
            // Local Mode (current implementation)
            // Simulate network delay
            try? await Task.sleep(nanoseconds: 500_000_000)
            
            // Mock users for demo
            let mockUsers = [
                User(id: "1", username: "alice", email: nil, createdAt: Date(), lastLoginAt: Date(), isAppleUser: false),
                User(id: "2", username: "bob", email: nil, createdAt: Date(), lastLoginAt: Date(), isAppleUser: false),
                User(id: "3", username: "charlie", email: nil, createdAt: Date(), lastLoginAt: Date(), isAppleUser: false),
                User(id: "4", username: "diana", email: nil, createdAt: Date(), lastLoginAt: Date(), isAppleUser: false),
                User(id: "5", username: "edward", email: nil, createdAt: Date(), lastLoginAt: Date(), isAppleUser: false)
            ]
            
            searchResults = mockUsers.filter { user in
                user.username.lowercased().contains(query.lowercased())
            }
        }
        
        isLoading = false
    }
    
    // MARK: - Data Persistence
    
    private func loadFriends() {
        if let data = userDefaults.data(forKey: friendsKey),
           let friends = try? JSONDecoder().decode([Friend].self, from: data) {
            self.friends = friends
        }
    }
    
    private func saveFriends() {
        if let data = try? JSONEncoder().encode(friends) {
            userDefaults.set(data, forKey: friendsKey)
        }
    }
    
    private func loadFriendRequests() {
        if let data = userDefaults.data(forKey: requestsKey),
           let requests = try? JSONDecoder().decode([FriendRequest].self, from: data) {
            self.friendRequests = requests
        }
    }
    
    private func saveFriendRequests() {
        if let data = try? JSONEncoder().encode(friendRequests) {
            userDefaults.set(data, forKey: requestsKey)
        }
    }
    
    private func loadOutgoingRequests() {
        if let data = userDefaults.data(forKey: outgoingRequestsKey),
           let requests = try? JSONDecoder().decode([FriendRequest].self, from: data) {
            self.outgoingRequests = requests
        }
    }
    
    private func saveOutgoingRequests() {
        if let data = try? JSONEncoder().encode(outgoingRequests) {
            userDefaults.set(data, forKey: outgoingRequestsKey)
        }
    }
    
    private func getCurrentUser() -> User? {
        // Get the current user from AuthManager
        if case .authenticated(let user) = AuthManager.shared.authState {
            return user
        }
        return nil
    }
    
    // MARK: - Computed Properties
    
    var acceptedFriends: [Friend] {
        friends.filter { $0.status == .accepted }
    }
    
    var pendingRequests: [FriendRequest] {
        guard let currentUser = getCurrentUser() else { return [] }
        // Only show incoming friend requests TO the current user
        return friendRequests.filter { request in
            request.toUserId == currentUser.id && request.status == .pending
        }
    }
    
    // MARK: - Activity Management
    
    func addActivity(_ activity: SocialActivity) {
        print("🔥 FriendManager: Adding activity - \(activity.username): \(activity.description)")
        activities.insert(activity, at: 0) // Add to beginning
        saveActivities()
        print("🔥 FriendManager: Activity added. Total activities: \(activities.count)")
    }
    
    func removeActivity(_ activity: SocialActivity) {
        activities.removeAll { $0.id == activity.id }
        saveActivities()
    }
    
    func clearActivities() {
        activities.removeAll()
        saveActivities()
    }
    
    private func loadActivities() {
        print("🔄 FriendManager: Loading activities. useAPI = \(useAPI)")
        if useAPI {
            Task {
                await fetchActivitiesFromAPI()
            }
        } else {
            if let data = userDefaults.data(forKey: activitiesKey),
               let activities = try? JSONDecoder().decode([SocialActivity].self, from: data) {
                self.activities = activities
                print("🔄 FriendManager: Loaded \(activities.count) activities from local storage")
            } else {
                self.activities = []
                print("🔄 FriendManager: No cached activities found, starting with empty array")
            }
        }
    }
    
    private func saveActivities() {
        if let data = try? JSONEncoder().encode(activities) {
            userDefaults.set(data, forKey: activitiesKey)
        }
    }
    
    // MARK: - API Methods for Activities
    
    func fetchActivitiesFromAPI() async {
        do {
            print("🌐 FriendManager: Fetching activities from API...")
            isLoading = true
            errorMessage = nil
            
            let response = try await apiClient.fetchActivities()
            print("🌐 FriendManager: API returned \(response.count) activities")
            
            // If no activities from API, set empty array
            if response.isEmpty {
                print("⚠️ FriendManager: No activities received from API")
                self.activities = []
                saveActivities()
                isLoading = false
                return
            }
            
            self.activities = response.compactMap { activity in
                // Convert timestamp string to Date
                let timestamp: Date
                if let date = ISO8601DateFormatter().date(from: activity.timestamp) {
                    timestamp = date
                } else {
                    // Try parsing as MySQL datetime format
                    let mysqlFormatter = DateFormatter()
                    mysqlFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
                    if let date = mysqlFormatter.date(from: activity.timestamp) {
                        timestamp = date
                    } else {
                        timestamp = Date()
                    }
                }
                
                return SocialActivity(
                    id: String(activity.id),  // Convert Int to String for SocialActivity
                    userId: activity.userId,
                    username: activity.username,
                    profilePicture: activity.profilePicture,
                    type: mapActivityType(activity.type),
                    description: activity.description,
                    timestamp: timestamp,
                    challenge: activity.challenge,
                    achievement: activity.achievement,
                    habit: activity.habit,
                    task: activity.task,
                    goal: activity.goal
                )
            }
            saveActivities()
            
            isLoading = false
        } catch let error as DecodingError {
            isLoading = false
            
            // Provide more specific error information
            switch error {
            case .keyNotFound(let key, let context):
                errorMessage = "Missing required field: \(key.stringValue)"
            case .typeMismatch(let type, let context):
                errorMessage = "Type mismatch in activities data"
            case .valueNotFound(let type, let context):
                errorMessage = "Missing value in activities data"
            case .dataCorrupted(let context):
                errorMessage = "Corrupted activities data"
            @unknown default:
                errorMessage = "Unknown decoding error"
            }
            
            // Set empty activities when API fails
            self.activities = []
            saveActivities()
        } catch {
            print("❌ FriendManager: Failed to fetch activities from API: \(error)")
            print("❌ FriendManager: Error details: \(String(describing: error))")
            isLoading = false
            errorMessage = "Failed to fetch activities: \(error.localizedDescription)"
            // Set empty activities when API fails
            self.activities = []
            saveActivities()
            print("⚠️ FriendManager: Activities set to empty due to API failure")
        }
    }
    
    private func mapActivityType(_ type: String) -> SocialActivityType {
        switch type {
        case "challengeCompleted", "challenge_completed": return .challengeCompleted
        case "challengeJoined", "challenge_joined": return .challengeJoined
        case "challengeCreated", "challenge_created": return .challengeCreated
        case "challengeProgress", "challenge_progress": return .challengeProgress

        case "achievementUnlocked", "achievement_unlocked": return .achievementUnlocked
        case "habitStreak", "habit_streak": return .habitStreak
        case "taskCompleted", "task_completed": return .taskCompleted
        case "goalProgress", "goal_progress": return .goalProgress
        case "habit_completed": return .habitStreak // Map habit_completed to habitStreak
        case "habitCreated", "habit_created": return .habitCreated
        case "taskCreated", "task_created": return .taskCreated
        case "goalCreated", "goal_created": return .goalCreated
        default: return .taskCompleted // Default fallback
        }
    }
    
    // MARK: - Analytics Management
    
    func addAnalytics(_ analytics: Analytics) {
        self.analytics.insert(analytics, at: 0) // Add to beginning
        saveAnalytics()
    }
    
    func removeAnalytics(_ analytics: Analytics) {
        self.analytics.removeAll { $0.id == analytics.id }
        saveAnalytics()
    }
    
    func clearAnalytics() {
        self.analytics.removeAll()
        saveAnalytics()
    }
    
    private func loadAnalytics() {
        if let data = userDefaults.data(forKey: analyticsKey),
           let analytics = try? JSONDecoder().decode([Analytics].self, from: data) {
            self.analytics = analytics
        }
    }
    
    private func saveAnalytics() {
        if let data = try? JSONEncoder().encode(analytics) {
            userDefaults.set(data, forKey: analyticsKey)
        }
    }
    



    
    // MARK: - User Statistics Calculation
    
    func calculateUserStatistics(for userId: String, habitStore: HabitStore, taskStore: TaskStore, goalStore: GoalStore, challengeManager: ChallengeManager) -> UserStatistics {
        // Check if we have cached statistics for this user
        if let cachedStats = friendStatistics[userId] {
            return cachedStats
        }
        
        // Calculate longest current streak across all habits
        let currentStreak = calculateLongestCurrentStreak(for: userId, habitStore: habitStore)
        
        // Count active challenges
        let activeChallengesCount = calculateActiveChallengesCount(for: userId, challengeManager: challengeManager)
        
        // Get last activity date
        let lastActivityDate = calculateLastActivityDate(for: userId, habitStore: habitStore, taskStore: taskStore, goalStore: goalStore)
        
        let stats = UserStatistics(
            userId: userId,
            currentStreak: currentStreak,
            activeChallengesCount: activeChallengesCount,
            lastActivityDate: lastActivityDate
        )
        
        // Cache the statistics
        friendStatistics[userId] = stats
        
        return stats
    }
    
    private func calculateLongestCurrentStreak(for userId: String, habitStore: HabitStore) -> Int {
        // If calculating for current user, use their habits
        if let currentUser = getCurrentUser(), currentUser.id == userId {
            // Find the highest streak among all habits
            return habitStore.habits.map { $0.streak }.max() ?? 0
        }
        
        // For other users, check cached statistics
        if let cachedStats = friendStatistics[userId] {
            return cachedStats.currentStreak
        }
        
        // Default to 0 if no data available
        return 0
    }
    
    private func calculateActiveChallengesCount(for userId: String, challengeManager: ChallengeManager) -> Int {
        // Count challenges where the user is a participant and the challenge is active
        return challengeManager.allChallenges.filter { challenge in
            challenge.isActive && 
            !challenge.isExpired && 
            challenge.participants.contains { $0.userId == userId }
        }.count
    }
    
    private func calculateLastActivityDate(for userId: String, habitStore: HabitStore, taskStore: TaskStore, goalStore: GoalStore) -> Date? {
        var lastActivityDates: [Date] = []
        
        // If calculating for current user
        if let currentUser = getCurrentUser(), currentUser.id == userId {
            // Check last completed habit dates
            let habitDates = habitStore.habits.compactMap { $0.lastCompletedDate }
            lastActivityDates.append(contentsOf: habitDates)
            
            // Check last completed task dates (use createdAt for completed tasks)
            let taskDates = taskStore.tasks.filter { $0.isCompleted }.map { $0.createdAt }
            lastActivityDates.append(contentsOf: taskDates)
            
            // Check last completed goal dates  
            let goalDates = goalStore.goals.compactMap { $0.completedDate }
            lastActivityDates.append(contentsOf: goalDates)
            
            // Return the most recent date
            return lastActivityDates.max()
        }
        
        // For other users, check cached statistics
        if let cachedStats = friendStatistics[userId] {
            return cachedStats.lastActivityDate
        }
        
        // Default to nil if no data available
        return nil
    }
    
    // Convenience method to get statistics for current user
    func getCurrentUserStatistics(habitStore: HabitStore, taskStore: TaskStore, goalStore: GoalStore, challengeManager: ChallengeManager) -> UserStatistics? {
        guard let currentUser = getCurrentUser() else { return nil }
        return calculateUserStatistics(
            for: currentUser.id,
            habitStore: habitStore,
            taskStore: taskStore,
            goalStore: goalStore,
            challengeManager: challengeManager
        )
    }
    
    // Load friend statistics from API
    func loadFriendStatistics() async {
        guard useAPI else { 
            // For local mode, use sample data
            await MainActor.run {
                for friend in friends where friend.status == .accepted {
                    let streak = Int.random(in: 0...30)
                    let challenges = Int.random(in: 0...5)
                    let hoursAgo = Int.random(in: 1...48)
                    let lastActivity = Calendar.current.date(byAdding: .hour, value: -hoursAgo, to: Date())
                    
                    friendStatistics[friend.friendId] = UserStatistics(
                        userId: friend.friendId,
                        currentStreak: streak,
                        activeChallengesCount: challenges,
                        lastActivityDate: lastActivity
                    )
                }
            }
            return
        }
        
        // Fetch statistics for all accepted friends from API
        await MainActor.run {
            isLoading = true
        }
        
        do {
            // Fetch statistics for each friend in parallel
            await withTaskGroup(of: (String, UserStatistics?).self) { group in
                for friend in friends where friend.status == .accepted {
                    group.addTask {
                        do {
                            let stats = try await self.apiClient.getFriendStatistics(userId: friend.friendId)
                            return (friend.friendId, stats)
                        } catch {
                            return (friend.friendId, nil)
                        }
                    }
                }
                
                // Collect results
                for await (userId, stats) in group {
                    if let stats = stats {
                        await MainActor.run {
                            self.friendStatistics[userId] = stats
                        }
                    }
                }
            }
            
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    // Clear cached statistics
    func clearFriendStatistics() {
        friendStatistics.removeAll()
    }
    
    // MARK: - Periodic Refresh
    
    func startPeriodicRefresh() {
        stopPeriodicRefresh() // Stop any existing timer
        
        // Create a timer that refreshes statistics periodically
        refreshTimer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                await self.loadFriendStatistics()
            }
        }
        
    }
    
    func stopPeriodicRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    deinit {
        // Stop the timer on the main actor
        Task { @MainActor in
            self.refreshTimer?.invalidate()
        }
    }
}

// MARK: - API Response Types

struct FetchActivitiesResponse: Codable {
    let success: Bool
    let activities: [ActivityResponse]?
}

struct ActivityResponse: Codable {
    let id: Int  // Changed from String to Int to match server response
    let userId: String
    let username: String
    let profilePicture: String?
    let type: String
    let description: String
    let timestamp: String
    let metadata: ActivityMetadata?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId  // Server sends "userId" directly, no mapping needed
        case username
        case profilePicture  // Server sends "profilePicture" directly, no mapping needed
        case type  // Server sends "type" directly, no mapping needed
        case description
        case timestamp  // Server sends "timestamp" directly, no mapping needed
        case metadata
    }
    
    // Convert metadata to specific activity objects
    var challenge: SocialActivityChallenge? {
        guard let metadata = metadata else { return nil }
        if let challengeId = metadata.challengeId,
           let challengeName = metadata.challengeName {
            return SocialActivityChallenge(
                id: challengeId,
                name: challengeName,
                progress: metadata.progress ?? 0,
                target: metadata.target ?? 0
            )
        }
        return nil
    }
    

    
    var achievement: SocialActivityAchievement? {
        guard let metadata = metadata else { return nil }
        if metadata.achievementType != nil {
            return SocialActivityAchievement(
                id: UUID().uuidString,
                name: metadata.achievementType ?? "",
                level: metadata.streak ?? 0
            )
        }
        return nil
    }
    
    var habit: SocialActivityHabit? {
        guard let metadata = metadata else { return nil }
        if let habitId = metadata.habitId,
           let habitName = metadata.habitName {
            return SocialActivityHabit(
                id: habitId,
                name: habitName,
                currentStreak: metadata.streak ?? 0
            )
        }
        return nil
    }
    
    var task: SocialActivityTask? {
        guard let metadata = metadata else { return nil }
        if let taskId = metadata.taskId,
           let taskTitle = metadata.taskTitle {
            return SocialActivityTask(
                id: taskId,
                name: taskTitle,
                status: "completed"
            )
        }
        return nil
    }
    
    var goal: SocialActivityGoal? {
        guard let metadata = metadata else { return nil }
        if let goalId = metadata.goalId,
           let goalName = metadata.goalName {
            return SocialActivityGoal(
                id: goalId,
                name: goalName,
                progress: metadata.progress ?? 0,
                target: metadata.target ?? 0
            )
        }
        return nil
    }
}

struct ActivityMetadata: Codable {
    // Common fields
    let habitId: String?
    let habitName: String?
    let taskId: String?
    let taskTitle: String?
    let goalId: String?
    let goalName: String?

    let streak: Int?
    let progress: Int?
    let target: Int?
    let memberCount: Int?
    let achievementType: String?
    let category: String?
    let priority: String?
    let inviteCode: String?
    
    // Challenge specific - flattened structure for backward compatibility
    let challengeId: String?
    let challengeName: String?
    
    // Initialize from decoder with custom logic to handle both nested and flat structures
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode all optional fields with nil as default
        habitId = try container.decodeIfPresent(String.self, forKey: .habitId)
        habitName = try container.decodeIfPresent(String.self, forKey: .habitName)
        taskId = try container.decodeIfPresent(String.self, forKey: .taskId)
        taskTitle = try container.decodeIfPresent(String.self, forKey: .taskTitle)
        goalId = try container.decodeIfPresent(String.self, forKey: .goalId)
        goalName = try container.decodeIfPresent(String.self, forKey: .goalName)

        streak = try container.decodeIfPresent(Int.self, forKey: .streak)
        progress = try container.decodeIfPresent(Int.self, forKey: .progress)
        target = try container.decodeIfPresent(Int.self, forKey: .target)
        memberCount = try container.decodeIfPresent(Int.self, forKey: .memberCount)
        achievementType = try container.decodeIfPresent(String.self, forKey: .achievementType)
        category = try container.decodeIfPresent(String.self, forKey: .category)
        priority = try container.decodeIfPresent(String.self, forKey: .priority)
        inviteCode = try container.decodeIfPresent(String.self, forKey: .inviteCode)
        
        // Handle challenge fields - check both flat and nested structure
        challengeId = try container.decodeIfPresent(String.self, forKey: .challengeId)
        challengeName = try container.decodeIfPresent(String.self, forKey: .challengeName)
    }
    
    private enum CodingKeys: String, CodingKey {
        case habitId, habitName
        case taskId, taskTitle
        case goalId, goalName

        case streak, progress, target
        case memberCount, achievementType
        case category, priority, inviteCode
        case challengeId, challengeName
    }
} 