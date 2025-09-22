import Foundation
import SwiftUI
import Combine

@MainActor
class ChallengeManager: ObservableObject {
    static let shared = ChallengeManager()
    
    // MARK: - Published Properties
    @Published var allChallenges: [Challenge] = []
    @Published var myActiveChallenges: [Challenge] = []
    @Published var myCompletedChallenges: [Challenge] = []
    @Published var availableChallenges: [Challenge] = []
    @Published var featuredChallenges: [Challenge] = []
    
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    // Filter and search state
    @Published var selectedCategory: ChallengeCategory?
    @Published var selectedDifficulty: ChallengeDifficulty?
    @Published var searchText = ""
    @Published var showOnlyActive = true
    
    // Statistics
    @Published var totalChallengesJoined = 0
    @Published var totalChallengesCompleted = 0
    @Published var currentStreakDays = 0
    @Published var totalPointsEarned = 0
    
    private var cancellables = Set<AnyCancellable>()
    private let apiClient = APIClient.shared
    
    // Prevent concurrent loading operations
    private var loadingTask: Task<Void, Never>?
    
    // MARK: - Initialization
    private init() {
        setupSubscriptions()
        Task {
            await loadInitialData()
        }
    }
    
    private func setupSubscriptions() {
        // Auto-refresh every 5 minutes when app is active
        Timer.publish(every: 300, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task {
                    await self?.refreshChallenges()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Data Loading
    func loadInitialData() async {
        // Cancel any existing loading task
        loadingTask?.cancel()
        
        loadingTask = Task {
            // Load sequentially to avoid cancellation issues
            await loadAllChallenges()
            
            // Check if cancelled before continuing
            guard !Task.isCancelled else {
                print("⚠️ [CHALLENGE-MANAGER] Loading cancelled after loadAllChallenges")
                return
            }
            
            await loadMyChallenges()
            
            // Check if cancelled before continuing
            guard !Task.isCancelled else {
                print("⚠️ [CHALLENGE-MANAGER] Loading cancelled after loadMyChallenges")
                return
            }
            
            await loadStatistics()
        }
        
        await loadingTask?.value
    }
    
    func refreshChallenges() async {
        guard !isRefreshing else { 
            print("⚠️ [CHALLENGE-MANAGER] Refresh already in progress, skipping")
            return 
        }
        isRefreshing = true
        defer { isRefreshing = false }
        
        print("🔄 [CHALLENGE-MANAGER] Starting challenge refresh...")
        await loadInitialData()
        print("✅ [CHALLENGE-MANAGER] Challenge refresh completed")
    }
    
    private func loadAllChallenges() async {
        do {
            print("🔄 [CHALLENGE-MANAGER] Loading all challenges...")
            
            // Check if task was cancelled before making API call
            guard !Task.isCancelled else {
                print("⚠️ [CHALLENGE-MANAGER] All challenges loading was cancelled")
                return
            }
            
            let challenges = try await apiClient.getChallenges()
            
            // Check if task was cancelled after API call
            guard !Task.isCancelled else {
                print("⚠️ [CHALLENGE-MANAGER] All challenges loading was cancelled after API call")
                return
            }
            
            print("✅ [CHALLENGE-MANAGER] Loaded \(challenges.count) challenges")
            
            await MainActor.run {
                self.allChallenges = challenges
                self.updateAvailableChallenges()
                self.updateFeaturedChallenges()
                self.clearError()
                print("📱 [CHALLENGE-MANAGER] UI updated with challenges")
            }
        } catch is CancellationError {
            print("⚠️ [CHALLENGE-MANAGER] All challenges loading was cancelled")
            // Don't set error for cancellation
        } catch {
            print("❌ [CHALLENGE-MANAGER] Failed to load challenges: \(error)")
            await MainActor.run {
                self.setError("Failed to load challenges: \(error.localizedDescription)")
            }
        }
    }
    
    private func loadMyChallenges() async {
        do {
            print("🔄 [CHALLENGE-MANAGER] Loading my challenges...")
            
            // Check if task was cancelled before making API call
            guard !Task.isCancelled else {
                print("⚠️ [CHALLENGE-MANAGER] My challenges loading was cancelled")
                return
            }
            
            let myChallenges = try await apiClient.getMyChallenges()
            
            // Check if task was cancelled after API call
            guard !Task.isCancelled else {
                print("⚠️ [CHALLENGE-MANAGER] My challenges loading was cancelled after API call")
                return
            }
            
            print("✅ [CHALLENGE-MANAGER] Loaded \(myChallenges.count) my challenges")
            
            await MainActor.run {
                self.myActiveChallenges = myChallenges.filter { !$0.isExpired && $0.isActive }
                self.myCompletedChallenges = myChallenges.filter { $0.isExpired || !$0.isActive }
                self.updateAvailableChallenges()
                self.clearError()
                print("📱 [CHALLENGE-MANAGER] My challenges UI updated: \(self.myActiveChallenges.count) active, \(self.myCompletedChallenges.count) completed")
            }
        } catch is CancellationError {
            print("⚠️ [CHALLENGE-MANAGER] My challenges loading was cancelled")
            // Don't set error for cancellation
        } catch {
            print("❌ [CHALLENGE-MANAGER] Failed to load my challenges: \(error)")
            await MainActor.run {
                self.setError("Failed to load your challenges: \(error.localizedDescription)")
            }
        }
    }
    
    private func loadStatistics() async {
        // Calculate statistics from loaded data
        await MainActor.run {
            self.totalChallengesJoined = self.myActiveChallenges.count + self.myCompletedChallenges.count
            self.totalChallengesCompleted = self.myCompletedChallenges.count
            
            // Calculate current streak (simplified)
            self.currentStreakDays = self.calculateCurrentStreak()
            
            // Calculate total points (simplified)
            self.totalPointsEarned = self.calculateTotalPoints()
        }
    }
    
    // MARK: - Challenge Actions
    func createChallenge(_ request: CreateChallengeRequest) async -> Bool {
        print("🚀 [CHALLENGE-MANAGER] Creating challenge: \(request.title)")
        isLoading = true
        defer { 
            isLoading = false 
            print("🏁 [CHALLENGE-MANAGER] Create challenge loading state cleared")
        }
        
        do {
            print("📡 [CHALLENGE-MANAGER] Sending create challenge request...")
            let challenge = try await apiClient.createChallenge(
                title: request.title,
                description: request.description,
                endDate: request.endDate,
                challengeType: request.challengeType.rawValue,
                targetValue: request.targetValue,
                category: request.category.rawValue,
                habitName: request.habitName,
                habitDescription: request.habitDescription,
                habitIcon: request.habitIcon,
                habitColor: request.habitColor,
                linkedHabitId: request.linkedHabitId
            )
            
            print("✅ [CHALLENGE-MANAGER] Challenge created successfully: \(challenge.id)")
            
            await MainActor.run {
                self.allChallenges.append(challenge)
                self.myActiveChallenges.append(challenge)
                self.updateAvailableChallenges()
                self.setSuccess("Challenge created successfully! 🎉")
                print("📱 [CHALLENGE-MANAGER] Challenge added to local state")
                
                // Notify that habits should be refreshed since backend created a habit for the challenge creator
                NotificationCenter.default.post(name: .shouldRefreshHabits, object: nil)
            }
            
            // Refresh challenge list to ensure sync
            await refreshChallenges()
            
            return true
        } catch {
            print("❌ [CHALLENGE-MANAGER] Failed to create challenge: \(error)")
            await MainActor.run {
                self.setError("Failed to create challenge: \(error.localizedDescription)")
            }
            return false
        }
    }
    
    func joinChallenge(_ challenge: Challenge) async -> Bool {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await apiClient.joinChallenge(challengeId: challenge.id)
            
            await MainActor.run {
                // Update local state
                if let index = self.allChallenges.firstIndex(where: { $0.id == challenge.id }) {
                    var updatedChallenge = self.allChallenges[index]
                    
                    if let currentUser = AuthManager.shared.currentUser {
                        let newParticipant = LegacyChallengeParticipant(
                            userId: currentUser.id,
                            username: currentUser.username,
                            targetValue: updatedChallenge.targetValue
                        )
                        updatedChallenge.participants.append(newParticipant)
                        
                        self.allChallenges[index] = updatedChallenge
                        self.myActiveChallenges.append(updatedChallenge)
                    }
                }
                
                self.updateAvailableChallenges()
                self.setSuccess("Joined challenge successfully! 🚀")
                
                // Notify that habits should be refreshed since backend created a habit for this challenge
                NotificationCenter.default.post(name: .shouldRefreshHabits, object: nil)
            }
            
            return true
        } catch {
            await MainActor.run {
                self.setError("Failed to join challenge: \(error.localizedDescription)")
            }
            return false
        }
    }
    
    func leaveChallenge(_ challenge: Challenge) async -> Bool {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await apiClient.leaveChallenge(challengeId: challenge.id)
            
            await MainActor.run {
                // Update local state
                if let index = self.allChallenges.firstIndex(where: { $0.id == challenge.id }) {
                    var updatedChallenge = self.allChallenges[index]
                    
                    if let currentUser = AuthManager.shared.currentUser {
                        updatedChallenge.participants.removeAll { $0.userId == currentUser.id }
                        self.allChallenges[index] = updatedChallenge
                    }
                }
                
                self.myActiveChallenges.removeAll { $0.id == challenge.id }
                self.updateAvailableChallenges()
                self.setSuccess("Left challenge successfully")
                
                // Notify that habits should be refreshed since backend deleted the associated habit
                NotificationCenter.default.post(name: .shouldRefreshHabits, object: nil)
            }
            
            return true
        } catch {
            await MainActor.run {
                self.setError("Failed to leave challenge: \(error.localizedDescription)")
            }
            return false
        }
    }
    
    func updateProgress(_ challenge: Challenge, newValue: Int? = nil, increment: Int? = nil) async -> Bool {
        do {
            let response = try await apiClient.updateChallengeProgress(
                challengeId: challenge.id,
                newValue: newValue,
                increment: increment
            )
            
            await MainActor.run {
                // Update local challenge data
                if let index = self.allChallenges.firstIndex(where: { $0.id == challenge.id }),
                   let currentUserId = AuthManager.shared.currentUser?.id,
                   let participantIndex = self.allChallenges[index].participants.firstIndex(where: { $0.userId == currentUserId }) {
                    
                    // Update the participant's current value and completion status
                    var updatedParticipants = self.allChallenges[index].participants
                    updatedParticipants[participantIndex].currentValue = response.currentValue
                    updatedParticipants[participantIndex].isCompleted = response.isCompleted
                    updatedParticipants[participantIndex].lastUpdated = Date()
                    
                    // Update the participants array
                    self.allChallenges[index].participants = updatedParticipants
                    
                    // Update in myActiveChallenges as well
                    if let myIndex = self.myActiveChallenges.firstIndex(where: { $0.id == challenge.id }) {
                        self.myActiveChallenges[myIndex] = self.allChallenges[index]
                    }
                }
                
                self.setSuccess("Progress updated! 📈")
            }
            
            return true
        } catch {
            await MainActor.run {
                self.setError("Failed to update progress: \(error.localizedDescription)")
            }
            return false
        }
    }
    
    func getLeaderboard(for challenge: Challenge) async -> [ChallengeLeaderboardEntry] {
        do {
            let legacyEntries = try await apiClient.getChallengeLeaderboard(challengeId: challenge.id)
            // Convert LegacyChallengeLeaderboardEntry to ChallengeLeaderboardEntry
            return legacyEntries.map { legacyEntry in
                ChallengeLeaderboardEntry(
                    id: legacyEntry.id,
                    rank: legacyEntry.rank,
                    userId: legacyEntry.userId,
                    username: legacyEntry.username,
                    profilePicture: legacyEntry.profilePicture,
                    currentValue: legacyEntry.currentValue,
                    targetValue: legacyEntry.targetValue,
                    isCompleted: legacyEntry.isCompleted,
                    progressPercentage: legacyEntry.progressPercentage,
                    joinedAt: legacyEntry.joinedAt
                )
            }
        } catch {
            await MainActor.run {
                self.setError("Failed to load leaderboard: \(error.localizedDescription)")
            }
            return []
        }
    }
    
    // MARK: - Computed Properties
    var filteredChallenges: [Challenge] {
        var challenges = showOnlyActive ? allChallenges.filter { !$0.isExpired && $0.isActive } : allChallenges
        
        // Apply category filter
        if let category = selectedCategory {
            challenges = challenges.filter { $0.category == category }
        }
        
        // Apply difficulty filter
        if let difficulty = selectedDifficulty {
            challenges = challenges.filter { $0.difficulty == difficulty }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            challenges = challenges.filter { challenge in
                challenge.title.localizedCaseInsensitiveContains(searchText) ||
                challenge.description.localizedCaseInsensitiveContains(searchText) ||
                challenge.category.rawValue.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return challenges.sorted { !$0.isExpired && $1.isExpired }
    }
    
    var isParticipating: (Challenge) -> Bool {
        return { challenge in
            guard let currentUserId = AuthManager.shared.currentUser?.id else { return false }
            return challenge.participants.contains { $0.userId == currentUserId }
        }
    }
    
    // MARK: - Helper Methods
    private func updateAvailableChallenges() {
        let currentUserId = AuthManager.shared.currentUser?.id
        availableChallenges = allChallenges.filter { challenge in
            !challenge.isExpired &&
            challenge.isActive &&
            !challenge.participants.contains { $0.userId == currentUserId }
        }
    }
    
    private func updateFeaturedChallenges() {
        // Simple logic: challenges with most participants that are still active
        featuredChallenges = allChallenges
            .filter { !$0.isExpired && $0.isActive }
            .sorted { $0.participants.count > $1.participants.count }
            .prefix(5)
            .map { $0 }
    }
    
    private func calculateCurrentStreak() -> Int {
        // Simplified calculation - in a real app, this would be more sophisticated
        let completedChallenges = myCompletedChallenges.filter { $0.isExpired }
        return completedChallenges.count
    }
    
    private func calculateTotalPoints() -> Int {
        // Simplified calculation - would integrate with rewards system
        return myCompletedChallenges.count * 100 + myActiveChallenges.count * 10
    }
    
    // MARK: - Error and Success Handling
    private func setError(_ message: String) {
        errorMessage = message
        successMessage = nil
        
        // Auto-clear error after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if self.errorMessage == message {
                self.errorMessage = nil
            }
        }
    }
    
    private func setSuccess(_ message: String) {
        successMessage = message
        errorMessage = nil
        
        // Auto-clear success after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            if self.successMessage == message {
                self.successMessage = nil
            }
        }
    }
    
    private func clearError() {
        errorMessage = nil
    }
    
    func clearErrorMessage() {
        errorMessage = nil
    }
    
    // MARK: - Filter Methods
    func setCategory(_ category: ChallengeCategory?) {
        selectedCategory = category
    }
    
    func setDifficulty(_ difficulty: ChallengeDifficulty?) {
        selectedDifficulty = difficulty
    }
    

    
    func clearAllFilters() {
        selectedCategory = nil
        selectedDifficulty = nil
        searchText = ""
    }
    
    // MARK: - Quick Actions
    func quickJoinRecommendedChallenge() async -> Bool {
        guard let recommended = featuredChallenges.first else { return false }
        return await joinChallenge(recommended)
    }
    
    func getPersonalizedRecommendations() -> [Challenge] {
        // Simple recommendation logic - could be enhanced with ML
        return availableChallenges
            .filter { $0.category == .fitness || $0.category == .health }
            .prefix(3)
            .map { $0 }
    }
}

// MARK: - Create Challenge Request
struct CreateChallengeRequest {
    let title: String
    let description: String
    let endDate: Date
    let challengeType: ChallengeType
    let category: ChallengeCategory
    let targetValue: Int
    let habitName: String
    let habitDescription: String
    let habitIcon: String
    let habitColor: String
    let linkedHabitId: String?
}

// MARK: - Challenge Progress Response
struct ChallengeProgressResponse: Codable {
    let currentValue: Int
    let targetValue: Int
    let isCompleted: Bool
    let progressPercentage: Int
    
    enum CodingKeys: String, CodingKey {
        case currentValue = "current_value"
        case targetValue = "target_value"
        case isCompleted = "is_completed"
        case progressPercentage = "progress_percentage"
    }
}

// MARK: - Challenge Leaderboard Entry
struct ChallengeLeaderboardEntry: Identifiable, Codable {
    let id: String
    let rank: Int
    let userId: String
    let username: String
    let profilePicture: String?
    let currentValue: Int
    let targetValue: Int
    let isCompleted: Bool
    let progressPercentage: Int
    let joinedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case rank
        case userId = "user_id"
        case username
        case profilePicture = "profile_picture"
        case currentValue = "current_value"
        case targetValue = "target_value"
        case isCompleted = "is_completed"
        case progressPercentage = "progress_percentage"
        case joinedAt = "joined_at"
    }
} 