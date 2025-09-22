import SwiftUI

struct SocialView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var friendManager = FriendManager.shared
    @StateObject private var challengeManager = ChallengeManager.shared
    @StateObject private var achievementManager = AchievementManager()
    @EnvironmentObject var habitStore: HabitStore
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var goalStore: GoalStore
    @State private var showingStatsAchievements = false
    @State private var showingSettings = false
    @State private var showingAddFriends = false
    @State private var showingFriendRequests = false
    @State private var showingFriendsList = false
    @State private var showingCreateChallenge = false
    @State private var showingChallengesList = false
    @State private var showingStreakLeaderboard = false
    @State private var selectedTab: SocialTab = .activity
    @State private var showingActivityFeed = false
    @State private var showingSocialAnalytics = false
    @State private var showingCelebration = false
    @State private var searchText = ""
    @State private var showingSearch = false
    @State private var showingNotifications = false
    
    enum SocialTab: String, CaseIterable {
        case activity = "Activity"
        case friends = "Friends"
        case challenges = "Challenges"
        
        var icon: String {
            switch self {
            case .activity: return "bolt.fill"
            case .friends: return "person.2.fill"
            case .challenges: return "trophy.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .activity: return Color(hex: "#007AFF") // Blue
            case .friends: return Color(hex: "#FF6B9D") // Pink/Light Purple
            case .challenges: return Color(hex: "#FF6B35") // Orange/Red
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.secondaryBackground
                    .ignoresSafeArea()
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    headerSection
                    contentSection
                }
                .background(Color.secondaryBackground)
            }
            .navigationBarHidden(true)
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 0)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showingStatsAchievements) {
                StatsTabView(
                    habitStore: habitStore,
                    taskStore: taskStore,
                    goalStore: goalStore,
                    achievementManager: achievementManager
                )
            }
            .sheet(isPresented: $showingSettings) {
                UserProfileView()
                    .environmentObject(habitStore)
                    .environmentObject(taskStore)
                    .environmentObject(goalStore)
            }
            .sheet(isPresented: $showingAddFriends) {
                AddFriendView()
            }
            .sheet(isPresented: $showingFriendRequests) {
                FriendRequestsView()
            }
            .sheet(isPresented: $showingFriendsList) {
                FriendsListView()
            }


            .sheet(isPresented: $showingCreateChallenge) {
                ChallengeCreationView(
                    habitStore: habitStore
                )
            }
            .sheet(isPresented: $showingChallengesList) {
                ChallengesListView(
                    habitStore: habitStore
                )
            }
            .sheet(isPresented: $showingStreakLeaderboard) {
                StreakLeaderboardView(friendManager: friendManager)
            }
            .sheet(isPresented: $showingActivityFeed) {
                ActivityFeedView(friendManager: friendManager, searchText: searchText)
            }
            .sheet(isPresented: $showingSocialAnalytics) {
                SocialAnalyticsView(friendManager: friendManager)
            }
            .overlay(
                CelebrationOverlay(isShowing: $showingCelebration)
            )
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            headerTitleBar
            searchSection
            tabPickerSection
        }
        .background(Color.secondaryBackground)
    }
    
    private var headerTitleBar: some View {
        ZStack {
            // Centered Title
            Text(selectedTab.rawValue)
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(.primary)
            
            HStack {
                // Settings Button (Left)
                Button(action: { showingSettings = true }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                // Right side buttons
                HStack(spacing: 12) {
                    // Create Challenge Button (only for challenges tab)
                    if selectedTab == .challenges {
                        Button(action: { showingCreateChallenge = true }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 24))
                                .symbolRenderingMode(.hierarchical)
                                .foregroundColor(.red)
                        }
                    }
                    
                    // Notification Badge
                    if friendManager.friendRequests.count > 0 {
                        Button(action: { showingFriendRequests = true }) {
                            ZStack {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 20, height: 20)
                                
                                Text("\(friendManager.friendRequests.count)")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
    }
    
    private var searchSection: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search friends", text: $searchText)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .onChange(of: searchText) { _ in
                        Task {
                            await friendManager.searchUsers(query: searchText)
                        }
                    }
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
                    .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
            )
        }
        .padding(.horizontal, 24)
        .padding(.top, 4)
    }
    
    private var tabPickerSection: some View {
        HStack(spacing: 12) {
            ForEach(SocialTab.allCases, id: \.self) { tab in
                SocialTabButton(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            selectedTab = tab
                        }
                    }
                )
            }
        }
        .padding(.horizontal, 20)
    }
    
    @ViewBuilder
    private var contentSection: some View {
        if !searchText.isEmpty {
            SearchResultsView(
                users: filteredUsers,
                friends: filteredFriends,
                challenges: filteredChallenges
            )
            .background(Color.secondaryBackground)
        } else {
            mainContentView
        }
    }
    
    private var mainContentView: some View {
        ScrollView {
            VStack(spacing: 20) {
                switch selectedTab {
                case .friends:
                    FriendsTabContent(
                        friendManager: friendManager,
                        showingAddFriends: $showingAddFriends,
                        showingFriendRequests: $showingFriendRequests,
                        showingFriendsList: $showingFriendsList
                    )
                case .challenges:
                    ModernChallengesMainView(
                        habitStore: habitStore
                    )

                case .activity:
                    ActivityFeedView(friendManager: friendManager, searchText: searchText)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 90)
        }
        .background(Color.secondaryBackground)
        .refreshable {
            await refreshData()
        }
    }
    
    private func refreshData() async {
        await friendManager.refreshFriends()
        await challengeManager.loadInitialData()
    }
}

// MARK: - Social Tab Button
struct SocialTabButton: View {
    let tab: SocialView.SocialTab
    let isSelected: Bool
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            HapticFeedback.shared.lightImpact()
            action()
        }) {
            VStack(spacing: 8) {
                Image(systemName: tab.icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isSelected ? .white : tab.color)
                
                Text(tab.rawValue)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .white : .primaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        isSelected ?
                        LinearGradient(
                            colors: [tab.color, tab.color.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [tab.color.opacity(0.15), tab.color.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? tab.color.opacity(0.3) : tab.color.opacity(0.3),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .scaleEffect(isSelected ? 1.05 : (isPressed ? 0.95 : 1.0))
            .animation(.easeInOut(duration: 0.2), value: isSelected)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Empty Friends State
struct EmptyFriendsState: View {
    @Binding var showingAddFriends: Bool
    @Binding var showingFriendRequests: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "person.2.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.blue)
            }
            
            // Title and subtitle
            VStack(spacing: 8) {
                Text("No Friends Yet")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Connect with friends to share progress and compete in challenges")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            // Action buttons
            VStack(spacing: 12) {
                Button(action: { showingAddFriends = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 18))
                        Text("Add Friends")
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                
                Button(action: { showingFriendRequests = true }) {
                    Text("View Friend Requests")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

// MARK: - Friends Tab Content
struct FriendsTabContent: View {
    @ObservedObject var friendManager: FriendManager
    @Binding var showingAddFriends: Bool
    @Binding var showingFriendRequests: Bool
    @Binding var showingFriendsList: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            // Friend Requests Indicator
            if friendManager.friendRequests.count > 0 {
                Button(action: { showingFriendRequests = true }) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 24, height: 24)
                            
                            Text("\(friendManager.friendRequests.count)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        
                        Text("\(friendManager.friendRequests.count) friend request\(friendManager.friendRequests.count == 1 ? "" : "s")")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.red.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Friends List
            if friendManager.acceptedFriends.isEmpty {
                EmptyFriendsState(showingAddFriends: $showingAddFriends, showingFriendRequests: $showingFriendRequests)
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(friendManager.acceptedFriends.prefix(10)) { friend in
                        FriendCard(friend: friend)
                    }
                }
            }
        }
    }
}

// MARK: - Challenges Tab Content
struct ChallengesTabContent: View {
    @StateObject private var challengeManager = ChallengeManager.shared
    @Binding var showingCreateChallenge: Bool
    @Binding var showingChallengesList: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            // Quick Stats Cards
            if !challengeManager.allChallenges.isEmpty {
                HStack(spacing: 12) {
                    SocialQuickStatCard(
                        title: "Active",
                        value: "\(challengeManager.allChallenges.filter { $0.isActive && !$0.isExpired }.count)",
                        icon: "flame.fill",
                        color: .orange
                    )
                    
                    SocialQuickStatCard(
                        title: "Joined",
                        value: "\(challengeManager.myActiveChallenges.count)",
                        icon: "person.fill.checkmark",
                        color: .green
                    )
                    
                    SocialQuickStatCard(
                        title: "Available",
                        value: "\(challengeManager.availableChallenges.count)",
                        icon: "plus.circle",
                        color: .blue
                    )
                }
            }
            
            // Create Challenge Button
            Button(action: { showingCreateChallenge = true }) {
                HStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                    
                    Text("Create New Challenge")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color.orange, Color.orange.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: Color.orange.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Active Challenges
            if challengeManager.allChallenges.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "trophy.circle")
                        .font(.system(size: 60))
                        .foregroundColor(.red.opacity(0.6))
                    
                    VStack(spacing: 8) {
                        Text("No Active Challenges")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("Create or join a challenge to compete with friends and achieve your goals!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    
                    Button(action: { showingChallengesList = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                            Text("Browse Challenges")
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [.blue, .blue.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: .blue.opacity(0.3), radius: 6, x: 0, y: 3)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Active Challenges")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Button(action: { showingChallengesList = true }) {
                            HStack(spacing: 4) {
                                Text("View All")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Image(systemName: "arrow.right")
                                    .font(.caption)
                            }
                            .foregroundColor(.blue)
                        }
                    }
                    
                    LazyVStack(spacing: 12) {
                        ForEach(challengeManager.allChallenges.prefix(3)) { challenge in
                            ModernChallengeCardCompact(challenge: challenge)
                        }
                    }
                }
            }
        }
    }
}



// MARK: - Modern Challenge Card Compact
struct ModernChallengeCardCompact: View {
    let challenge: Challenge
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var challengeManager = ChallengeManager.shared
    @State private var showingChallengeDetail = false
    
    private var currentParticipant: LegacyChallengeParticipant? {
        challenge.participants.first { $0.userId == authManager.currentUser?.id }
    }
    
    private var isUserChallenge: Bool {
        currentParticipant != nil
    }
    
    var body: some View {
        Button(action: { showingChallengeDetail = true }) {
            VStack(spacing: 0) {
                // Header with type and status
                HStack {
                    // Challenge type badge
                    HStack(spacing: 4) {
                        Image(systemName: challenge.challengeType.defaultIcon)
                            .font(.caption)
                        Text(challenge.challengeType.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(hex: challenge.challengeType.defaultColor))
                    .cornerRadius(8)
                    
                    Spacer()
                    
                    // Status indicators
                    if isUserChallenge {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                            Text("Joined")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                // Main content
                VStack(alignment: .leading, spacing: 12) {
                    // Title and basic info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(challenge.title)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        HStack(spacing: 12) {
                            HStack(spacing: 4) {
                                Image(systemName: "person.2")
                                    .font(.caption)
                                Text("\(challenge.participants.count)")
                                    .font(.caption)
                            }
                            .foregroundColor(.secondary)
                            
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                    .font(.caption)
                                Text(challenge.isExpired ? "Expired" : "\(challenge.daysRemaining)d left")
                                    .font(.caption)
                            }
                            .foregroundColor(challenge.isExpired ? .red : .secondary)
                            
                            HStack(spacing: 4) {
                                Image(systemName: challenge.category.icon)
                                    .font(.caption)
                                Text(challenge.category.rawValue)
                                    .font(.caption)
                            }
                            .foregroundColor(Color(hex: challenge.category.color))
                        }
                    }
                    
                    // Progress for user challenges
                    if isUserChallenge, let participant = currentParticipant {
                        VStack(spacing: 6) {
                            HStack {
                                Text("Progress")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text("\(participant.currentValue)/\(participant.targetValue)")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color(hex: challenge.challengeType.defaultColor))
                            }
                            
                            ProgressView(value: participant.progress)
                                .progressViewStyle(LinearProgressViewStyle(tint: Color(hex: challenge.challengeType.defaultColor)))
                                .scaleEffect(x: 1, y: 1.5, anchor: .center)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 2)
        .sheet(isPresented: $showingChallengeDetail) {
            ChallengeDetailView(challenge: challenge, challengeManager: ChallengeManager.shared)
        }
    }
}

// MARK: - Modern Challenges Main View (Nuclear Version)
struct ModernChallengesMainView: View {
    @StateObject private var challengeManager = ChallengeManager.shared
    @ObservedObject var habitStore: HabitStore
    
    @State private var selectedFilter: ChallengeFilter = .myChallenges
    @State private var showingCreateChallenge = false
    @State private var searchText = ""
    
    enum ChallengeFilter: String, CaseIterable {
        case myChallenges = "My Challenges"
        case available = "Available"
        
        var icon: String {
            switch self {
            case .myChallenges: return "person.circle.fill"
            case .available: return "globe"
            }
        }
        
        var color: Color {
            switch self {
            case .myChallenges: return .blue
            case .available: return .green
            }
        }
    }
    
    var filteredChallenges: [Challenge] {
        let challenges: [Challenge]
        
        switch selectedFilter {
        case .myChallenges:
            challenges = challengeManager.myActiveChallenges + challengeManager.myCompletedChallenges
        case .available:
            challenges = challengeManager.availableChallenges
        }
        
        if searchText.isEmpty {
            return challenges
        } else {
            return challenges.filter { challenge in
                challenge.title.localizedCaseInsensitiveContains(searchText) ||
                challenge.description.localizedCaseInsensitiveContains(searchText) ||
                challenge.category.rawValue.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with search
            headerSection
            
            // Filter tabs
            filterTabsSection
            
            // Content
            if challengeManager.isLoading {
                loadingView
            } else if filteredChallenges.isEmpty {
                emptyStateView
            } else {
                challengesListView
            }
        }
        .background(Color.secondaryBackground)
        .sheet(isPresented: $showingCreateChallenge) {
            ChallengeCreationView(habitStore: habitStore)
        }
        .onAppear {
            Task {
                await challengeManager.loadInitialData()
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search challenges...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    private var filterTabsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ChallengeFilter.allCases, id: \.self) { filter in
                    NuclearFilterTab(
                        filter: filter,
                        isSelected: selectedFilter == filter,
                        action: { selectedFilter = filter }
                    )
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 12)
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading challenges...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: selectedFilter.icon)
                .font(.system(size: 60))
                .foregroundColor(selectedFilter.color.opacity(0.6))
            
            VStack(spacing: 8) {
                Text(emptyStateTitle)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(emptyStateMessage)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Button(action: { showingCreateChallenge = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("Create Challenge")
                }
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [.orange, .orange.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: .orange.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 20)
    }
    
    private var challengesListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(filteredChallenges) { challenge in
                    NuclearChallengeCard(
                        challenge: challenge,
                        isUserChallenge: challengeManager.myActiveChallenges.contains { $0.id == challenge.id }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
    
    private var emptyStateTitle: String {
        switch selectedFilter {
        case .myChallenges:
            return searchText.isEmpty ? "No Challenges Yet" : "No Matching Challenges"
        case .available:
            return "No Available Challenges"
        }
    }
    
    private var emptyStateMessage: String {
        switch selectedFilter {
        case .myChallenges:
            return searchText.isEmpty ? "Create or join challenges to track your progress and compete with others!" : "Try adjusting your search terms"
        case .available:
            return "Check back later for new challenges, or create your own!"
        }
    }
}

// MARK: - Nuclear Stat Card
struct NuclearStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
            }
            .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Nuclear Filter Tab
struct NuclearFilterTab: View {
    let filter: ModernChallengesMainView.ChallengeFilter
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: filter.icon)
                    .font(.caption)
                Text(filter.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .white : filter.color)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? filter.color : filter.color.opacity(0.1))
            .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Nuclear Challenge Card
struct NuclearChallengeCard: View {
    let challenge: Challenge
    let isUserChallenge: Bool
    @StateObject private var challengeManager = ChallengeManager.shared
    
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isSuccess = false
    @State private var showingDetailView = false
    
    var userParticipant: LegacyChallengeParticipant? {
        guard let currentUserId = AuthManager.shared.currentUser?.id else { return nil }
        return challenge.participants.first { $0.userId == currentUserId }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with type indicator and status
            HStack {
                // Challenge type badge
                HStack(spacing: 4) {
                    Image(systemName: challenge.challengeType.defaultIcon)
                        .font(.caption)
                    Text(challenge.challengeType.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(hex: challenge.challengeType.defaultColor))
                .cornerRadius(8)
                
                Spacer()
                
                // Status indicators
                HStack(spacing: 8) {
                    if isUserChallenge {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                            Text("Joined")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    if challenge.isExpired {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.caption)
                            Text("Expired")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            // Main content
            VStack(alignment: .leading, spacing: 12) {
                // Title and description
                VStack(alignment: .leading, spacing: 4) {
                    Text(challenge.title)
                        .font(.title3)
                        .fontWeight(.bold)
                        .lineLimit(2)
                    
                    if !challenge.description.isEmpty {
                        Text(challenge.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                    }
                }
                
                // Challenge details
                HStack(spacing: 16) {
                    NuclearDetailItem(
                        icon: "calendar",
                        text: challenge.isExpired ? "Expired" : "\(challenge.daysRemaining) days left",
                        color: challenge.isExpired ? .red : .primary
                    )
                    
                    NuclearDetailItem(
                        icon: "person.2",
                        text: "\(challenge.participants.count) participants",
                        color: .primary
                    )
                    
                    NuclearDetailItem(
                        icon: challenge.category.icon,
                        text: challenge.category.rawValue,
                        color: Color(hex: challenge.category.color)
                    )
                }
                
                // Progress section for user challenges
                if isUserChallenge, let participant = userParticipant {
                    progressSection(for: participant)
                }
                
                // Action buttons
                actionButtonsSection
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
        .onTapGesture {
            showingDetailView = true
        }
        .sheet(isPresented: $showingDetailView) {
            ChallengeDetailView(challenge: challenge, challengeManager: ChallengeManager.shared)
        }
        .alert(isSuccess ? "Success" : "Error", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func progressSection(for participant: LegacyChallengeParticipant) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text("Your Progress")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(participant.currentValue)/\(participant.targetValue) \(challenge.challengeType.unit)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: challenge.challengeType.defaultColor))
            }
            
            ProgressView(value: participant.progress)
                .progressViewStyle(LinearProgressViewStyle(tint: Color(hex: challenge.challengeType.defaultColor)))
                .scaleEffect(x: 1, y: 1.5, anchor: .center)
            
            HStack {
                Text("\(participant.progressPercentage)% complete")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if participant.isCompleted {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                        Text("Completed!")
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.yellow)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var actionButtonsSection: some View {
        HStack(spacing: 12) {
            if !isUserChallenge {
                Button(action: {
                    Task {
                        await joinChallenge()
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                        Text("Join Challenge")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: challenge.isActive && !challenge.isExpired ? [.green, .green.opacity(0.8)] : [.gray, .gray.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(10)
                }
                .disabled(!challenge.isActive || challenge.isExpired || challengeManager.isLoading)
            } else {
                Button(action: {
                    Task {
                        await leaveChallenge()
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "minus.circle")
                        Text("Leave")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(10)
                }
                .disabled(challengeManager.isLoading)
            }
            
            Button(action: { showingDetailView = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                    Text("Details")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
            }
        }
    }
    
    private func joinChallenge() async {
        await challengeManager.joinChallenge(challenge)
        
        if let error = challengeManager.errorMessage {
            alertMessage = error
            isSuccess = false
        } else {
            alertMessage = "Successfully joined \(challenge.title)!"
            isSuccess = true
        }
        showingAlert = true
    }
    
    private func leaveChallenge() async {
        await challengeManager.leaveChallenge(challenge)
        
        if let error = challengeManager.errorMessage {
            alertMessage = error
            isSuccess = false
        } else {
            alertMessage = "Successfully left \(challenge.title)"
            isSuccess = true
        }
        showingAlert = true
    }
}

// MARK: - Nuclear Detail Item
struct NuclearDetailItem: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Challenge Card
struct ChallengeCard: View {
    let challenge: Challenge
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var challengeManager = ChallengeManager.shared
    @State private var showingChallengeDetail = false
    
    private var currentParticipant: LegacyChallengeParticipant? {
        challenge.participants.first { $0.userId == authManager.currentUser?.id }
    }
    
    private var participantRank: Int? {
        guard let participant = currentParticipant else { return nil }
        let sortedParticipants = challenge.participants.sorted { $0.currentValue > $1.currentValue }
        return sortedParticipants.firstIndex(where: { $0.userId == participant.userId }).map { $0 + 1 }
    }
    
    private var progressPercentage: Double {
        guard let participant = currentParticipant,
              challenge.targetValue > 0 else { return 0 }
        return min(Double(participant.currentValue) / Double(challenge.targetValue), 1.0)
    }
    
    private var challengeGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(hex: challenge.category.color).opacity(0.15),
                Color(hex: challenge.category.color).opacity(0.08)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    @ViewBuilder
    private var challengeIcon: some View {
        ZStack {
            Circle()
                .fill(Color(hex: challenge.category.color).opacity(0.2))
                .frame(width: 48, height: 48)
            
            Image(systemName: challenge.challengeType.defaultIcon)
                .font(.title3)
                .foregroundColor(Color(hex: challenge.category.color))
        }
    }
    
    @ViewBuilder
    private var challengeInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(challenge.title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .lineLimit(1)
            
            HStack(spacing: 8) {
                Label("\(challenge.participants.count)", systemImage: "person.2.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if challenge.daysRemaining > 0 {
                    Label("\(challenge.daysRemaining)d left", systemImage: "clock.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    @ViewBuilder
    private var rankBadge: some View {
        if let rank = participantRank {
            VStack(spacing: 2) {
                Text("#\(rank)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(rank <= 3 ? Color(hex: challenge.category.color) : .secondary)
                Text("Rank")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    @ViewBuilder
    private var progressSection: some View {
        if let participant = currentParticipant {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("\(participant.currentValue)/\(challenge.targetValue)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("\(Int(progressPercentage * 100))%")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
                
                // Progress Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.secondary.opacity(0.15))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(hex: challenge.category.color))
                            .frame(width: geometry.size.width * CGFloat(progressPercentage), height: 8)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progressPercentage)
                    }
                }
                .frame(height: 8)
            }
        }
    }
    
    var body: some View {
        Button(action: { showingChallengeDetail = true }) {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack(spacing: 12) {
                    challengeIcon
                    challengeInfo
                    Spacer()
                    rankBadge
                }
                
                // Progress Section
                progressSection
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(challengeGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(hex: challenge.category.color).opacity(0.3), lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingChallengeDetail) {
            ChallengeDetailView(challenge: challenge, challengeManager: ChallengeManager.shared)
        }
    }
}

// MARK: - Enhanced Friend Card
struct FriendCard: View {
    let friend: Friend
    @EnvironmentObject var habitStore: HabitStore
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var goalStore: GoalStore
    @StateObject private var friendManager = FriendManager.shared
    @StateObject private var challengeManager = ChallengeManager.shared
    @State private var userStats: UserStatistics?
    @State private var detailedStats: APIClient.UserStats?
    @State private var isPressed = false
    @State private var showingFriendDetails = false
    @State private var showingQuickActions = false
    @State private var isLoadingStats = false
    @State private var loadingTimer: Timer?
    
    // Feature flag to disable stats loading if API is having issues
    private let enableStatsLoading = false
    
    private var friendGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(hex: "#FF6B9D").opacity(0.15),
                Color(hex: "#FF6B9D").opacity(0.08),
                Color(hex: "#FF6B9D").opacity(0.03)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var strokeGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(hex: "#FF6B9D").opacity(0.4),
                Color(hex: "#FF6B9D").opacity(0.2)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Main Card Content
            VStack(spacing: 16) {
                // Header with Avatar and Basic Info
                HStack(spacing: 16) {
                    // Avatar with Online Status
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "#FF6B9D"), Color(hex: "#FF6B9D").opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 56, height: 56)
                        
                        Text(String(friend.friendUsername.prefix(1)).uppercased())
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        // Online Status Indicator
                        Circle()
                            .fill(Color.green)
                            .frame(width: 14, height: 14)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                            )
                            .offset(x: 20, y: 20)
                    }
                    
                    // Friend Name and Status
                    VStack(alignment: .leading, spacing: 6) {
                        Text(friend.friendUsername)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        // Status Row
                        HStack(spacing: 12) {
                            // Streak
                            HStack(spacing: 4) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.orange)
                                Text("\(detailedStats?.maxStreak ?? userStats?.currentStreak ?? 0) days")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                            }
                            
                            // Challenges
                            HStack(spacing: 4) {
                                Image(systemName: "trophy.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.yellow)
                                Text("\(userStats?.activeChallengesCount ?? 0)")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Last Activity
                        if let lastActivity = userStats?.lastActivityDescription {
                            Text(lastActivity)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                    
                    // More Options Button
                    Button(action: {
                        showingQuickActions = true
                    }) {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(width: 30, height: 30)
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                // Stats Grid
                if enableStatsLoading && isLoadingStats {
                    ProgressView()
                        .frame(height: 80)
                        .frame(maxWidth: .infinity)
                } else if enableStatsLoading || detailedStats != nil {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        StatItem(
                            icon: "target",
                            value: "\(detailedStats?.totalHabits ?? 0)",
                            label: "Habits",
                            color: .blue
                        )
                        
                        StatItem(
                            icon: "checkmark.circle.fill",
                            value: "\(detailedStats?.totalTasks ?? 0)",
                            label: "Tasks",
                            color: .green
                        )
                        
                        StatItem(
                            icon: "flag.fill",
                            value: "\(detailedStats?.totalGoals ?? 0)",
                            label: "Goals",
                            color: .purple
                        )
                        
                        StatItem(
                            icon: "flame.fill",
                            value: "\(detailedStats?.maxStreak ?? userStats?.currentStreak ?? 0)",
                            label: "Max Streak",
                            color: .orange
                        )
                    }
                    .padding(.horizontal, 16)
                }
                
                // View Profile Button
                Button(action: {
                    showingFriendDetails = true
                }) {
                    HStack(spacing: 8) {
                        Text("View Full Profile")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Image(systemName: "arrow.right")
                            .font(.caption)
                    }
                    .foregroundColor(Color(hex: "#FF6B9D"))
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(hex: "#FF6B9D").opacity(0.1))
                    )
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(friendGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(strokeGradient, lineWidth: 1.5)
                )
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onTapGesture {
            showingFriendDetails = true
        }
        .sheet(isPresented: $showingFriendDetails) {
            FriendDetailSheet(friend: friend)
        }
        .confirmationDialog("Friend Actions", isPresented: $showingQuickActions) {
            Button("View Profile") {
                showingFriendDetails = true
            }
            Button("Remove Friend", role: .destructive) {
                Task {
                    await friendManager.removeFriend(friend)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .onAppear {
            loadFriendData()
        }
        .onDisappear {
            loadingTimer?.invalidate()
        }
    }
    
    private func loadFriendData() {
        // Calculate basic statistics
        userStats = friendManager.calculateUserStatistics(
            for: friend.friendId,
            habitStore: habitStore,
            taskStore: taskStore,
            goalStore: goalStore,
            challengeManager: challengeManager
        )
        
        // Load detailed stats from API
        guard enableStatsLoading else { return }
        
        Task {
            await MainActor.run {
                isLoadingStats = true
            }
            
            do {
                
                // Create a timeout task
                let statsTask = Task {
                    try await APIClient.shared.getUserStats(userId: friend.friendId)
                }
                
                // Wait for either the API call or timeout (8 seconds for friend cards)
                let stats = try await withTimeout(seconds: 8) {
                    try await statsTask.value
                }
                
                await MainActor.run {
                    detailedStats = stats
                }
                
            } catch {
                // Stats will remain nil, showing basic stats instead
            }
            
            await MainActor.run {
                isLoadingStats = false
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

// MARK: - Timeout Error
struct TimeoutError: Error, LocalizedError {
    var errorDescription: String? {
        return "The request timed out"
    }
}

// MARK: - Stat Item Component
struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.primary)
            
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Friend Details View
struct FriendDetailSheet: View {
    let friend: Friend
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var habitStore: HabitStore
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var goalStore: GoalStore
    @StateObject private var friendManager = FriendManager.shared
    @StateObject private var challengeManager = ChallengeManager.shared
    @State private var userStats: UserStatistics?
    @State private var detailedStats: APIClient.UserStats?
    @State private var isLoadingStats = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Header
                    VStack(spacing: 16) {
                        // Avatar
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "#FF6B9D"), Color(hex: "#FF6B9D").opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 100, height: 100)
                            
                            Text(String(friend.friendUsername.prefix(1)).uppercased())
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        VStack(spacing: 8) {
                            Text(friend.friendUsername)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text("Friend since \(friend.createdAt, style: .date)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Stats Overview
                    if isLoadingStats {
                        ProgressView("Loading stats...")
                            .frame(height: 100)
                    } else {
                        VStack(spacing: 16) {
                            // Current Activity
                            if let userStats = userStats {
                                HStack(spacing: 20) {
                                    // Current Streak
                                    VStack(spacing: 4) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "flame.fill")
                                                .font(.title2)
                                                .foregroundColor(.orange)
                                            Text("\(userStats.currentStreak)")
                                                .font(.title)
                                                .fontWeight(.bold)
                                        }
                                        Text("Day Streak")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    
                                    Divider()
                                        .frame(height: 40)
                                    
                                    // Active Challenges
                                    VStack(spacing: 4) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "trophy.fill")
                                                .font(.title2)
                                                .foregroundColor(.yellow)
                                            Text("\(userStats.activeChallengesCount)")
                                                .font(.title)
                                                .fontWeight(.bold)
                                        }
                                        Text("Challenges")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.secondaryBackground)
                                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                                )
                            }
                            
                            // Detailed Stats Grid
                            if let stats = detailedStats {
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: 16) {
                                    DetailedStatCard(
                                        title: "Total Habits",
                                        value: "\(stats.totalHabits)",
                                        icon: "target",
                                        color: .blue,
                                        subtitle: "Active habits tracked"
                                    )
                                    
                                    DetailedStatCard(
                                        title: "Total Tasks",
                                        value: "\(stats.totalTasks)",
                                        icon: "checkmark.circle.fill",
                                        color: .green,
                                        subtitle: "Tasks completed"
                                    )
                                    
                                    DetailedStatCard(
                                        title: "Total Goals",
                                        value: "\(stats.totalGoals)",
                                        icon: "flag.fill",
                                        color: .purple,
                                        subtitle: "Goals achieved"
                                    )
                                    
                                    DetailedStatCard(
                                        title: "Best Streak",
                                        value: "\(stats.maxStreak) days",
                                        icon: "flame.fill",
                                        color: .orange,
                                        subtitle: "Longest streak"
                                    )
                                }
                            }
                        }
                    }
                    
                    // Activity Content
                    VStack(spacing: 16) {
                        ActivityTabContent(friend: friend, userStats: userStats)
                    }
                    .padding(.top, 16)
                    
                    // Privacy Notice
                    HStack {
                        Image(systemName: "lock.shield.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Only public information is shown to protect privacy")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.secondary.opacity(0.1))
                    )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationTitle("Friend Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            loadFriendData()
        }
    }
    
    private func loadFriendData() {
        // Calculate basic statistics
        userStats = friendManager.calculateUserStatistics(
            for: friend.friendId,
            habitStore: habitStore,
            taskStore: taskStore,
            goalStore: goalStore,
            challengeManager: challengeManager
        )
        
        // Load detailed stats from API
        Task {
            await MainActor.run {
                isLoadingStats = true
            }
            
            do {
                detailedStats = try await APIClient.shared.getUserStats(userId: friend.friendId)
            } catch {
                // Don't leave the UI in loading state if the API call fails
            }
            
            await MainActor.run {
                isLoadingStats = false
            }
        }
    }
}

// MARK: - Detailed Stat Card
struct DetailedStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.secondaryBackground)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Activity Row
struct ActivityRow: View {
    let icon: String
    let title: String
    let time: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - Activity Tab Content
struct ActivityTabContent: View {
    let friend: Friend
    let userStats: UserStatistics?
    
    var body: some View {
        VStack(spacing: 16) {
            if let lastActivity = userStats?.lastActivityDate {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Activity")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        ActivityRow(
                            icon: "checkmark.circle.fill",
                            title: "Last active",
                            time: lastActivity.formatted(.relative(presentation: .named)),
                            color: .green
                        )
                        
                        if let streak = userStats?.currentStreak, streak > 0 {
                            ActivityRow(
                                icon: "flame.fill",
                                title: "Maintaining \(streak)-day streak",
                                time: "Current",
                                color: .orange
                            )
                        }
                        
                        if let challenges = userStats?.activeChallengesCount, challenges > 0 {
                            ActivityRow(
                                icon: "trophy.fill",
                                title: "Participating in \(challenges) challenge\(challenges == 1 ? "" : "s")",
                                time: "Active",
                                color: .yellow
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    
                    Text("No recent activity")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Check back later to see their progress")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            }
        }
    }
}

// MARK: - Achievements Tab Content
struct AchievementsTabContent: View {
    let friend: Friend
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "star.circle")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text("Achievements Coming Soon")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("You'll be able to see your friend's achievements here")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Friend Challenges Tab Content
struct FriendChallengesTabContent: View {
    let friend: Friend
    @StateObject private var challengeManager = ChallengeManager.shared
    
    private var friendChallenges: [Challenge] {
        challengeManager.allChallenges.filter { challenge in
            challenge.participants.contains { $0.userId == friend.friendId }
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            if friendChallenges.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "trophy.circle")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    
                    Text("No Active Challenges")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Your friend isn't participating in any challenges yet")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Active Challenges")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .padding(.horizontal)
                    
                    ForEach(friendChallenges.prefix(5)) { challenge in
                        FriendChallengeRow(challenge: challenge, friendId: friend.friendId)
                            .padding(.horizontal)
                    }
                }
            }
        }
    }
}

// MARK: - Friend Challenge Row
struct FriendChallengeRow: View {
    let challenge: Challenge
    let friendId: String
    
    private var friendParticipant: LegacyChallengeParticipant? {
        challenge.participants.first { $0.userId == friendId }
    }
    
    private var progressPercentage: Double {
        guard let participant = friendParticipant,
              challenge.targetValue > 0 else { return 0 }
        return min(Double(participant.currentValue) / Double(challenge.targetValue), 1.0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: challenge.challengeType.defaultIcon)
                    .font(.caption)
                    .foregroundColor(Color(hex: challenge.category.color))
                
                Text(challenge.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                if let participant = friendParticipant {
                    Text("\(participant.currentValue)/\(challenge.targetValue)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 4)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: challenge.category.color))
                        .frame(width: geometry.size.width * CGFloat(progressPercentage), height: 4)
                }
            }
            .frame(height: 4)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondaryBackground)
        )
    }
}



















// MARK: - Activity Feed View
struct ActivityFeedView: View {
    @ObservedObject var friendManager: FriendManager
    var searchText: String

    var filteredActivities: [SocialActivity] {
        // Get current user ID to filter out own activities
        let currentUserId: String?
        if case .authenticated(let user) = AuthManager.shared.authState {
            currentUserId = user.id
        } else {
            currentUserId = nil
        }
        
        // Filter out own activities first, then apply search filter if needed
        let activitiesWithoutOwnActivity = friendManager.activities.filter { activity in
            activity.userId != currentUserId
        }
        
        if searchText.isEmpty {
            return activitiesWithoutOwnActivity
        } else {
            return activitiesWithoutOwnActivity.filter {
                $0.username.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if friendManager.isLoading && filteredActivities.isEmpty {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.2)
                        
                        Text("Loading activities...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 300)
                    .padding(.top, 20)
                } else if filteredActivities.isEmpty {
                    EmptyActivityState()
                        .padding(.top, 20)
                        .padding(.horizontal, 20)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredActivities) { activity in
                            ActivityCard(activity: activity)
                                .padding(.horizontal, 20)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .bottom).combined(with: .opacity),
                                    removal: .scale.combined(with: .opacity)
                                ))
                        }
                        
                        // Load more indicator
                        if filteredActivities.count > 20 {
                            HStack {
                                Text("Showing recent activities")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 20)
                        }
                    }
                }
            }
            .padding(.bottom, 20)
        }
        .refreshable {
            await refreshActivities()
        }
        .task {
            print("📱 SocialView: ActivityFeedView loaded. Activities count: \(friendManager.activities.count)")
            print("📱 SocialView: API activity feed enabled: \(APIConfig.enableActivityFeed)")
            print("📱 SocialView: Use API enabled: \(APIConfig.useAPI)")
            if APIConfig.enableActivityFeed && APIConfig.useAPI && friendManager.activities.isEmpty {
                print("📱 SocialView: Activities empty, fetching from API...")
                await friendManager.fetchActivitiesFromAPI()
            } else if !APIConfig.useAPI {
                print("📱 SocialView: API disabled, using local mode only")
            }
        }
    }
    
    private func refreshActivities() async {
        print("🔄 SocialView: Refreshing activities...")
        if APIConfig.useAPI {
            await friendManager.fetchActivitiesFromAPI()
        } else {
            print("🔄 SocialView: API disabled, skipping refresh")
        }
    }
}

// MARK: - Activity Card
struct ActivityCard: View {
    let activity: SocialActivity
    @State private var isPressed = false
    @State private var showingProfile = false
    @State private var showDetails = false
    
    private var activityColor: Color {
        Color(hex: activity.type.color)
    }
    
    private var activityGradient: LinearGradient {
        LinearGradient(
            colors: [
                activityColor.opacity(0.15),
                activityColor.opacity(0.08),
                activityColor.opacity(0.03)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var strokeGradient: LinearGradient {
        LinearGradient(
            colors: [
                activityColor.opacity(0.4),
                activityColor.opacity(0.2)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Avatar with activity type indicator
                ZStack(alignment: .bottomTrailing) {
                    ProfileImageView(
                        username: activity.username,
                        size: 48
                    )
                    
                    // Activity type icon
                    Circle()
                        .fill(Color(hex: activity.type.color))
                        .frame(width: 20, height: 20)
                        .overlay(
                            Image(systemName: activity.type.icon)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .offset(x: 4, y: 4)
                }
                
                // Activity Details
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(activity.username)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text("·")
                            .foregroundColor(.secondary)
                        
                        Text(activity.timestamp, style: .relative)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    
                    Text(activity.description)
                        .font(.system(size: 14))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    // Additional details based on activity type
                    if let habitStreak = activity.habit {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: activity.type.color))
                            Text("\(habitStreak.currentStreak) day streak")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color(hex: activity.type.color))
                        }
                    } else if let achievement = activity.achievement {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: activity.type.color))
                            Text("Level \(achievement.level)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color(hex: activity.type.color))
                        }
                    }
                }
                
                Spacer()
                
                // Activity type badge
                VStack {
                    Text(activity.type.rawValue)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color(hex: activity.type.color))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color(hex: activity.type.color).opacity(0.15))
                        )
                    Spacer()
                }
            }
            .padding(16)
            
            // Expandable details section
            if showDetails {
                Divider()
                    .padding(.horizontal, 16)
                
                VStack(alignment: .leading, spacing: 8) {
                    if let challenge = activity.challenge {
                        ActivityDetailRow(
                            icon: "trophy.fill",
                            title: challenge.name,
                            subtitle: "Progress: \(challenge.progress)/\(challenge.target)",
                            color: activityColor
                        )
                    }
                    
                    if let goal = activity.goal {
                        ActivityDetailRow(
                            icon: "target",
                            title: goal.name,
                            subtitle: "Progress: \(goal.progress)/\(goal.target)",
                            color: activityColor
                        )
                    }
                    
                    if let task = activity.task {
                        ActivityDetailRow(
                            icon: "checkmark.circle.fill",
                            title: task.name,
                            subtitle: "Status: \(task.status)",
                            color: activityColor
                        )
                    }
                }
                .padding(16)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(activityGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(strokeGradient, lineWidth: 1.5)
                )
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isPressed)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showDetails)
        .onTapGesture {
            withAnimation {
                showDetails.toggle()
            }
        }
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .contextMenu {
            Button(action: {
                showingProfile = true
            }) {
                Label("View Profile", systemImage: "person.circle")
            }
            
            if activity.userId != AuthManager.shared.currentUser?.id {
                Button(action: {
                    // Add friend action
                }) {
                    Label("Add Friend", systemImage: "person.badge.plus")
                }
            }
        }
        .sheet(isPresented: $showingProfile) {
            // Create a User object from the activity
            let user = User(
                id: activity.userId,
                username: activity.username,
                email: nil,
                createdAt: Date(),
                lastLoginAt: Date(),
                isAppleUser: false
            )
            UserProfileDetailView(user: user)
        }
    }
}

// MARK: - Activity Detail Row
struct ActivityDetailRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Empty Activity State
struct EmptyActivityState: View {
    
    private var emptyGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(hex: "#007AFF").opacity(0.1),
                Color(hex: "#007AFF").opacity(0.05)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(emptyGradient)
                    .frame(width: 80, height: 80)
                
                Image(systemName: "bolt.fill")
                    .font(.system(size: 32))
                    .foregroundColor(Color(hex: "#007AFF"))
            }
            
            VStack(spacing: 8) {
                Text("No activity yet")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text("When you or your friends create or complete habits, goals, and tasks, you'll see their activity here.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.cardBackground.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color(hex: "#007AFF").opacity(0.1), lineWidth: 1)
                )
                .shadow(color: Color(hex: "#007AFF").opacity(0.08), radius: 12, x: 0, y: 6)
        )
    }
}

// MARK: - Activity Details View
struct ActivityDetailsView: View {
    let activity: SocialActivity
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(activity.username)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(activity.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(activity.description)
                .font(.body)
                .foregroundColor(.primary)
                .padding(.top, 8)
            
            if let challenge = activity.challenge {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Challenge: \(challenge.name)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("Progress: \(challenge.progress)/\(challenge.target)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
            

            
            if let achievement = activity.achievement {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Achievement: \(achievement.name)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("Level: \(achievement.level)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
            
            if let habit = activity.habit {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Habit: \(habit.name)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("Streak: \(habit.currentStreak)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
            
            if let task = activity.task {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Task: \(task.name)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("Status: \(task.status)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
            
            if let goal = activity.goal {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Goal: \(goal.name)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("Progress: \(goal.progress)/\(goal.target)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.secondaryBackground)
                .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 8)
        )
    }
}

// MARK: - Social Analytics View
struct SocialAnalyticsView: View {
    @ObservedObject var friendManager: FriendManager
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Social Analytics")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            if friendManager.analytics.isEmpty {
                EmptyAnalyticsState()
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(friendManager.analytics.prefix(10)) { analytics in
                        AnalyticsCard(analytics: analytics)
                    }
                }
            }
        }
        .padding(.top, 20)
    }
}

// MARK: - Empty Analytics State
struct EmptyAnalyticsState: View {
    private var emptyGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(hex: "#FF6B35").opacity(0.1),
                Color(hex: "#FF6B35").opacity(0.05)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(emptyGradient)
                    .frame(width: 80, height: 80)
                
                Image(systemName: "chart.bar.xaxis")
                    .font(.system(size: 32))
                    .foregroundColor(Color(hex: "#FF6B35"))
            }
            
            VStack(spacing: 8) {
                Text("No analytics yet")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text("Track your social activity to see detailed analytics")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: { /* No action for now */ }) {
                HStack(spacing: 8) {
                    Image(systemName: "chart.bar.xaxis")
                    Text("Track Activity")
                }
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "#FF6B35"), Color(hex: "#FF6B35").opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(12)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.secondaryBackground)
                .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 6)
        )
    }
}

// MARK: - Analytics Card
struct AnalyticsCard: View {
    let analytics: Analytics
    @State private var isPressed = false
    
    private var analyticsGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(hex: "#FF6B35").opacity(0.15),
                Color(hex: "#FF6B35").opacity(0.08),
                Color(hex: "#FF6B35").opacity(0.03)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var strokeGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(hex: "#FF6B35").opacity(0.4),
                Color(hex: "#FF6B35").opacity(0.2)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: "chart.bar.fill")
                .font(.title2)
                .foregroundColor(.white)
            
            // Analytics Details
            VStack(alignment: .leading, spacing: 4) {
                Text(analytics.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(analytics.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Value: \(analytics.value)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(analyticsGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(strokeGradient, lineWidth: 1.5)
                )
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Analytics Details View
struct AnalyticsDetailsView: View {
    let analytics: Analytics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(analytics.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(analytics.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(analytics.description)
                .font(.body)
                .foregroundColor(.primary)
                .padding(.top, 8)
            
            if let challenge = analytics.challenge {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Challenge: \(challenge.name)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("Progress: \(challenge.progress)/\(challenge.target)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
            

            
            if let achievement = analytics.achievement {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Achievement: \(achievement.name)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("Level: \(achievement.level)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
            
            if let habit = analytics.habit {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Habit: \(habit.name)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("Streak: \(habit.currentStreak)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
            
            if let task = analytics.task {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Task: \(task.name)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("Status: \(task.status)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
            
            if let goal = analytics.goal {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Goal: \(goal.name)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("Progress: \(goal.progress)/\(goal.target)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.secondaryBackground)
                .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 8)
        )
    }
}

// MARK: - Celebration Overlay
struct CelebrationOverlay: View {
    @Binding var isShowing: Bool
    
    var body: some View {
        if isShowing {
            ZStack {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isShowing = false
                        }
                    }
                
                VStack(spacing: 20) {
                    Image(systemName: "party.popper.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)
                    
                    Text("Celebration!")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Share your achievements with friends!")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .padding(32)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [Color.orange, Color.yellow],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            }
            .transition(.opacity)
        }
    }
}

// In SocialView, add computed properties for filtered results:
extension SocialView {
    var filteredUsers: [User] {
        if searchText.isEmpty { return [] }
        return friendManager.searchResults
    }
    var filteredFriends: [Friend] {
        if searchText.isEmpty { return friendManager.friends }
        return friendManager.friends.filter {
            $0.friendUsername.localizedCaseInsensitiveContains(searchText)
        }
    }
    var filteredChallenges: [Challenge] {
        let currentUserId = AuthManager.shared.currentUser?.id
        let availableChallenges = challengeManager.allChallenges.filter { challenge in
            !challenge.participants.contains { $0.userId == currentUserId }
        }
        
        if searchText.isEmpty { return availableChallenges }
        return availableChallenges.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.description.localizedCaseInsensitiveContains(searchText) ||
            $0.challengeType.rawValue.localizedCaseInsensitiveContains(searchText) ||
            $0.category.rawValue.localizedCaseInsensitiveContains(searchText)
        }
    }

    var filteredActivities: [SocialActivity] {
        if searchText.isEmpty { return friendManager.activities }
        return friendManager.activities.filter {
            $0.username.localizedCaseInsensitiveContains(searchText) ||
            $0.description.localizedCaseInsensitiveContains(searchText)
        }
    }
}

// Add the SearchResultsView:
struct SearchResultsView: View {
    let users: [User]
    let friends: [Friend]
    let challenges: [Challenge]
    @StateObject private var friendManager = FriendManager.shared
    @StateObject private var challengeManager = ChallengeManager.shared
    @State private var pendingFriendRequests: Set<String> = []
    @State private var pendingChallengeJoins: Set<String> = []
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if !users.isEmpty {
                    Text("Users")
                        .font(.headline)
                        .padding(.leading, 4)
                    ForEach(users) { user in
                        UserSearchCard(
                            user: user,
                            friendManager: friendManager,
                            pendingRequests: $pendingFriendRequests
                        )
                    }
                }
                if !friends.isEmpty {
                    Text("Friends")
                        .font(.headline)
                        .padding(.leading, 4)
                    ForEach(friends) { friend in
                        FriendCard(friend: friend)
                    }
                }
                if !challenges.isEmpty {
                    Text("Challenges")
                        .font(.headline)
                        .padding(.leading, 4)
                    ForEach(challenges) { challenge in
                        ChallengeSearchCard(
                            challenge: challenge,
                            pendingJoins: $pendingChallengeJoins
                        )
                    }
                }

                if users.isEmpty && friends.isEmpty && challenges.isEmpty {
                    VStack(spacing: 16) {
                        Text("No results found")
                            .font(.title3)
                            .fontWeight(.semibold)
                        Text("Try a different search term.")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                }
            }
            .padding(.top, 16)
            .padding(.horizontal, 8)
        }
    }
}


struct ChallengeSearchCard: View {
    let challenge: Challenge
    @StateObject private var challengeManager = ChallengeManager.shared
    @Binding var pendingJoins: Set<String>
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    private var isAlreadyParticipating: Bool {
        challengeManager.myActiveChallenges.contains { $0.id == challenge.id }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "trophy.fill")
                .font(.title2)
                .foregroundColor(Color(hex: "#FF6B35"))
                .frame(width: 40, height: 40)
            VStack(alignment: .leading, spacing: 4) {
                Text(challenge.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                Text(challenge.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                Text("\(challenge.participants.count) participants")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Spacer()
            
            // Action Button
            if isAlreadyParticipating {
                Text("Joined")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.green.opacity(0.2))
                    )
            } else {
                Button(action: {
                    Task {
                        pendingJoins.insert(challenge.id)
                        await challengeManager.joinChallenge(challenge)
                        if challengeManager.errorMessage != nil {
                            alertMessage = challengeManager.errorMessage ?? "Failed to join challenge"
                            showingAlert = true
                        } else {
                            alertMessage = "Successfully joined \(challenge.title)!"
                            showingAlert = true
                        }
                        pendingJoins.remove(challenge.id)
                    }
                }) {
                    Text(pendingJoins.contains(challenge.id) ? "Joining..." : "Join")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "#FF6B35"), Color(hex: "#FF6B35").opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                }
                .disabled(pendingJoins.contains(challenge.id) || !challenge.isActive || challenge.isExpired)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
        .alert("Challenge", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
}



struct UserSearchCard: View {
    let user: User
    @ObservedObject var friendManager: FriendManager
    @Binding var pendingRequests: Set<String>
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingProfile = false
    
    private var isAlreadyFriend: Bool {
        friendManager.friends.contains { $0.friendUsername.lowercased() == user.username.lowercased() }
    }
    
    private var hasPendingRequest: Bool {
        friendManager.outgoingRequests.contains { $0.toUsername.lowercased() == user.username.lowercased() }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 40, height: 40)
                Text(String(user.username.prefix(1)).uppercased())
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(user.username)
                    .font(.headline)
                    .fontWeight(.semibold)
                if let email = user.email {
                    Text(email)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            
            // Action Button
            if isAlreadyFriend {
                Text("Friends")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.green.opacity(0.2))
                    )
            } else if hasPendingRequest {
                Text("Request Sent")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.orange.opacity(0.2))
                    )
            } else {
                Button(action: {
                    Task {
                        pendingRequests.insert(user.id)
                        let success = await friendManager.sendFriendRequest(to: user.username)
                        if success {
                            alertMessage = "Friend request sent to \(user.username)!"
                        } else {
                            alertMessage = friendManager.errorMessage ?? "Failed to send friend request"
                        }
                        showingAlert = true
                        pendingRequests.remove(user.id)
                    }
                }) {
                    Text(pendingRequests.contains(user.id) ? "Sending..." : "Add Friend")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.blue, Color.blue.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                }
                .disabled(pendingRequests.contains(user.id))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
        .onTapGesture {
            showingProfile = true
        }
        .alert("Friend Request", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showingProfile) {
            UserProfileDetailView(user: user)
        }
    }
}

// MARK: - Social Quick Stat Card
private struct SocialQuickStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
            }
            .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}