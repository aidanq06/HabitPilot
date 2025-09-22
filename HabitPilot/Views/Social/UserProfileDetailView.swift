import SwiftUI

struct UserProfileDetailView: View {
    let user: User
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var challengeManager = ChallengeManager.shared
    @StateObject private var friendManager = FriendManager.shared
    
    // Accept optional store instances - if nil, create new ones (for other users)
    var habitStore: HabitStore?
    var taskStore: TaskStore?
    var goalStore: GoalStore?
    
    // Create fallback stores for other users
    @StateObject private var fallbackHabitStore = HabitStore(shouldLoadData: false)
    @StateObject private var fallbackTaskStore = TaskStore(shouldLoadData: false)
    @StateObject private var fallbackGoalStore = GoalStore(shouldLoadData: false)
    
    // State for fetched stats
    @State private var fetchedStats: APIClient.UserStats?
    @State private var isLoadingStats = false
    @State private var statsLoadError: String?
    
    // Initializers
    init(user: User) {
        self.user = user
        self.habitStore = nil
        self.taskStore = nil
        self.goalStore = nil
    }
    
    init(user: User, habitStore: HabitStore, taskStore: TaskStore, goalStore: GoalStore) {
        self.user = user
        self.habitStore = habitStore
        self.taskStore = taskStore
        self.goalStore = goalStore
    }
    
    // Computed properties to use the right store instances
    private var activeHabitStore: HabitStore {
        if let habitStore = habitStore {
            return habitStore
        } else if isCurrentUser, let sharedStore = StoreManager.shared.getHabitStore() {
            return sharedStore
        } else {
            return fallbackHabitStore
        }
    }
    
    private var activeTaskStore: TaskStore {
        if let taskStore = taskStore {
            return taskStore
        } else if isCurrentUser, let sharedStore = StoreManager.shared.getTaskStore() {
            return sharedStore
        } else {
            return fallbackTaskStore
        }
    }
    
    private var activeGoalStore: GoalStore {
        if let goalStore = goalStore {
            return goalStore
        } else if isCurrentUser, let sharedStore = StoreManager.shared.getGoalStore() {
            return sharedStore
        } else {
            return fallbackGoalStore
        }
    }
    
    // Check if this is the current user's profile
    private var isCurrentUser: Bool {
        user.id == AuthManager.shared.currentUser?.id
    }
    
    // Helper function to check if a challenge has the user as participant
    private func isUserParticipant(in challenge: Challenge) -> Bool {
        for participant in challenge.participants {
            if participant.userId == user.id {
                return true
            }
        }
        return false
    }
    
    // Helper function to check if activity belongs to user
    private func isUserActivity(_ activity: SocialActivity) -> Bool {
        return activity.userId == user.id
    }
    
    // Filter challenges where this user is a participant
    private var userChallenges: [Challenge] {
        if isCurrentUser {
            // For current user, get all challenges they're participating in
            let allChallenges = challengeManager.allChallenges
            var result: [Challenge] = []
            
            for challenge in allChallenges {
                if isUserParticipant(in: challenge) {
                    result.append(challenge)
                }
            }
            
            return result
        } else {
            // For other users, we might not have access to their challenge data
            var result: [Challenge] = []
            for challenge in challengeManager.allChallenges {
                if isUserParticipant(in: challenge) {
                    result.append(challenge)
                }
            }
            return result
        }
    }
    
    // Filter activities for this user (if available)
    private var userActivities: [SocialActivity] {
        if isCurrentUser {
            // For current user, generate recent activities from actual data
            return generateRecentActivities()
        } else {
            // For other users, use social activities
            var result: [SocialActivity] = []
            for activity in friendManager.activities {
                if isUserActivity(activity) {
                    result.append(activity)
                }
            }
            return result
        }
    }
    
    // Generate recent activities for the current user based on their actual data
    private func generateRecentActivities() -> [SocialActivity] {
        var activities: [SocialActivity] = []
        
        // Add completed habits from today
        let completedHabits = activeHabitStore.habits.filter { $0.isCompletedToday() }
        for habit in completedHabits.prefix(3) {
            let habitActivity = SocialActivityHabit(
                id: habit.id.uuidString,
                name: habit.name,
                currentStreak: habit.streak
            )
            
            activities.append(SocialActivity(
                userId: user.id,
                username: user.username,
                profilePicture: user.profilePicture,
                type: .habitStreak,
                description: "Completed habit: \(habit.name)",
                habit: habitActivity
            ))
        }
        
        // Add completed tasks
        let completedTasks = activeTaskStore.tasks.filter { $0.isCompleted }
        for task in completedTasks.prefix(2) {
            let taskActivity = SocialActivityTask(
                id: task.id.uuidString,
                name: task.title,
                status: "Completed"
            )
            
            activities.append(SocialActivity(
                userId: user.id,
                username: user.username,
                profilePicture: user.profilePicture,
                type: .taskCompleted,
                description: "Completed task: \(task.title)",
                task: taskActivity
            ))
        }
        
        // Add completed goals
        let completedGoals = activeGoalStore.goals.filter { $0.isCompleted }
        for goal in completedGoals.prefix(2) {
            let goalActivity = SocialActivityGoal(
                id: goal.id.uuidString,
                name: goal.title,
                progress: goal.currentProgress,
                target: goal.targetValue
            )
            
            activities.append(SocialActivity(
                userId: user.id,
                username: user.username,
                profilePicture: user.profilePicture,
                type: .goalProgress,
                description: "Achieved goal: \(goal.title)",
                goal: goalActivity
            ))
        }
        
        // Sort by timestamp (most recent first) - SocialActivity creates timestamp automatically
        return activities.sorted { $0.timestamp > $1.timestamp }
    }
    
    // Real stats calculated from actual data
    private var userStats: (totalHabits: Int, totalTasks: Int, totalGoals: Int, currentStreak: Int) {
        // Determine store sources
        let habitStoreSource: String
        if habitStore != nil {
            habitStoreSource = "passed"
        } else if isCurrentUser && StoreManager.shared.getHabitStore() != nil {
            habitStoreSource = "shared"
        } else {
            habitStoreSource = "fallback"
        }
        
        let taskStoreSource: String
        if taskStore != nil {
            taskStoreSource = "passed"
        } else if isCurrentUser && StoreManager.shared.getTaskStore() != nil {
            taskStoreSource = "shared"
        } else {
            taskStoreSource = "fallback"
        }
        
        let goalStoreSource: String
        if goalStore != nil {
            goalStoreSource = "passed"
        } else if isCurrentUser && StoreManager.shared.getGoalStore() != nil {
            goalStoreSource = "shared"
        } else {
            goalStoreSource = "fallback"
        }
        
        if isCurrentUser {
            // For current user, use actual data from the active stores
            let habits = activeHabitStore.habits.count
            let tasks = activeTaskStore.tasks.count // Show total tasks, not just completed
            let goals = activeGoalStore.goals.count
            let maxStreak = activeHabitStore.habits.map { $0.streak }.max() ?? 0
            
            return (habits, tasks, goals, maxStreak)
        } else {
            // For other users, use fetched stats if available, otherwise show 0
            if let stats = fetchedStats {
                return (stats.totalHabits, stats.totalTasks, stats.totalGoals, stats.maxStreak)
            } else {
                return (0, 0, 0, 0)
            }
        }
    }
    
    var body: some View {
        return NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Hero Section with Gradient Background
                    VStack(spacing: 20) {
                        // Profile Avatar with Gradient Border
                        ProfileImageView(
                            username: user.username,
                            size: 100
                        )
                        .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                        
                        // Username and Join Date
                        VStack(spacing: 8) {
                            Text(user.username)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            let joinDate = user.createdAt
                            Text("Member since \(joinDate, style: .date)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 30)
                    .background(
                        LinearGradient(
                            colors: [
                                Color.blue.opacity(0.1),
                                Color.purple.opacity(0.05)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    // Stats Section
                    VStack(spacing: 16) {
                        Text("Statistics")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        
                        if isLoadingStats && !isCurrentUser {
                            // Show loading state for other users
                            ProgressView("Loading stats...")
                                .frame(height: 100)
                                .frame(maxWidth: .infinity)
                        } else if let error = statsLoadError {
                            // Show error state
                            VStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 32))
                                    .foregroundColor(.orange)
                                
                                Text(error)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                
                                Button("Retry") {
                                    Task {
                                        await fetchUserStats()
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            .frame(height: 100)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal)
                        } else {
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 16) {
                                ProfileStatCard(
                                    icon: "target",
                                    value: "\(userStats.totalHabits)",
                                    label: "Habits",
                                    color: .blue
                                )
                                
                                ProfileStatCard(
                                    icon: "checkmark.circle.fill",
                                    value: "\(userStats.totalTasks)",
                                    label: "Tasks",
                                    color: .green
                                )
                                
                                ProfileStatCard(
                                    icon: "flag.fill",
                                    value: "\(userStats.totalGoals)",
                                    label: "Goals",
                                    color: .purple
                                )
                                
                                ProfileStatCard(
                                    icon: "flame.fill",
                                    value: "\(userStats.currentStreak)",
                                    label: "Streak",
                                    color: .orange
                                )
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical, 20)
                    
                    // Challenges Section
                    VStack(spacing: 16) {
                        HStack {
                            Text("Active Challenges")
                                .font(.headline)
                            Spacer()
                            Text("\(userChallenges.count)")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.2))
                                .foregroundColor(.blue)
                                .clipShape(Capsule())
                        }
                        .padding(.horizontal)
                        
                        if userChallenges.isEmpty {
                            ProfileEmptyStateView(
                                icon: "trophy",
                                title: "No Active Challenges",
                                subtitle: "This user hasn't joined any challenges yet"
                            )
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(userChallenges) { challenge in
                                        ProfileChallengeCard(challenge: challenge, userId: user.id)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical, 20)
                    
                    // Recent Activity Section
                    VStack(spacing: 16) {
                        HStack {
                            Text("Recent Activity")
                                .font(.headline)
                            Spacer()
                            Text("\(userActivities.count)")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.2))
                                .foregroundColor(.green)
                                .clipShape(Capsule())
                        }
                        .padding(.horizontal)
                        
                        if userActivities.isEmpty {
                            ProfileEmptyStateView(
                                icon: "clock",
                                title: "No Recent Activity",
                                subtitle: "This user hasn't been active recently"
                            )
                        } else {
                            VStack(spacing: 12) {
                                ForEach(Array(userActivities.prefix(5))) { activity in
                                    ProfileActivityRow(activity: activity)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical, 20)
                    
                    Spacer(minLength: 20)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.medium)
                }
            }
            .onAppear {
                // Fetch stats for other users
                if !isCurrentUser {
                    Task {
                        await fetchUserStats()
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func fetchUserStats() async {
        await MainActor.run {
            isLoadingStats = true
            statsLoadError = nil
        }
        
        
        do {
            // Create a timeout task
            let statsTask = Task {
                try await APIClient.shared.getUserStats(userId: user.id)
            }
            
            // Wait for either the API call or timeout (10 seconds)
            let stats = try await withTimeout(seconds: 10) {
                try await statsTask.value
            }
            
            await MainActor.run {
                self.fetchedStats = stats
                self.isLoadingStats = false
            }
        } catch {
            await MainActor.run {
                if error.localizedDescription.contains("timeout") || error.localizedDescription.contains("timed out") {
                    self.statsLoadError = "Stats loading timed out. Please try again."
                } else {
                    self.statsLoadError = "Failed to load stats: \(error.localizedDescription)"
                }
                self.isLoadingStats = false
            }
        }
    }

    
    // Helper function to add timeout to async operations
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        return try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw TimeoutError()
            }
            
            guard let result = try await group.next() else {
                throw TimeoutError()
            }
            
            group.cancelAll()
            return result
        }
    }
}

// MARK: - Profile-Specific Supporting Views

struct ProfileStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
}

struct ProfileChallengeCard: View {
    let challenge: Challenge
    let userId: String
    
    private var userProgress: (current: Int, target: Int)? {
        if let participant = challenge.participants.first(where: { $0.userId == userId }) {
            return (participant.currentValue, challenge.targetValue)
        }
        return nil
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundColor(.orange)
                    .font(.title3)
                
                Text(challenge.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                
                Spacer()
            }
            
            if let progress = userProgress {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Progress")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(progress.current)/\(progress.target)")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    
                    ProgressView(value: Double(progress.current), total: Double(progress.target))
                        .progressViewStyle(LinearProgressViewStyle(tint: .orange))
                }
            }
        }
        .padding(16)
        .frame(width: 200)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

struct ProfileActivityRow: View {
    let activity: SocialActivity
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.green.opacity(0.2))
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.description)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Text(activity.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

struct ProfileEmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    UserProfileDetailView(user: User(
        id: "1",
        username: "john_doe",
        email: "john@example.com",
        createdAt: Date(),
        lastLoginAt: Date(),
        isAppleUser: false
    ))
} 
