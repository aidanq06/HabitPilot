import SwiftUI

// MARK: - Goal Filter Enum
enum GoalFilter: CaseIterable {
    case all
    case completed
    case inProgress
    case highPriority
}

struct GoalsView: View {
    @ObservedObject var goalStore: GoalStore
    @ObservedObject var habitStore: HabitStore
    @EnvironmentObject var suggestionManager: SuggestionHelper
    @State private var showingAddGoal = false
    @State private var selectedGoal: Goal?
    @State private var goalToDelete: Goal?
    @State private var showingDeleteConfirmation = false
    @State private var showingTemplates = false
    @State private var showingUpgrade = false
    @State private var animateCards = false
    @State private var forceRefresh = false
    @State private var selectedFilter: GoalFilter = .all
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.secondaryBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom Header
                    VStack(spacing: 16) {
                        // Top row with title and action buttons
                        HStack {
                            // Title with premium indicator on the left
                            HStack {
                                Text("Goals")
                                    .font(.system(size: 34, weight: .bold))
                                    .foregroundColor(.primary)
                                
                                // Premium indicator when approaching limit
                                if !PurchaseService.shared.isUnlimitedPurchased && goalStore.goals.count >= 3 {
                                    HStack(spacing: 4) {
                                        Image(systemName: "crown.fill")
                                            .font(.caption)
                                            .foregroundColor(.yellow)
                                        
                                        Text("\(goalStore.goals.count)/5")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.yellow.opacity(0.2))
                                    )
                                }
                            }
                            
                            Spacer()
                            
                            // Action buttons with enhanced design
                            HStack(spacing: 12) {
                                Button(action: {
                                    if goalStore.canAddMoreGoals {
                                        showingAddGoal = true
                                    } else {
                                        showingUpgrade = true
                                    }
                                }) {
                                    ZStack {
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [Color.infoBlue, Color.infoBlue.opacity(0.8)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 44, height: 44)
                                            .shadow(color: Color.infoBlue.shadowColor(opacity: 0.3), radius: 8, x: 0, y: 4)
                                        
                                        Image(systemName: "plus")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }
                                
                                Button(action: {
                                    if goalStore.canAddMoreGoals {
                                        showingTemplates = true
                                    } else {
                                        showingUpgrade = true
                                    }
                                }) {
                                    ZStack {
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [Color.blue, Color.blue.opacity(0.8)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 44, height: 44)
                                            .shadow(color: Color.blue.shadowColor(opacity: 0.3), radius: 8, x: 0, y: 4)
                                        
                                        Image(systemName: "doc.text.fill")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // Filter buttons row - full width
                        HStack(spacing: 16) {
                            GoalFilterButton(
                                icon: "list.bullet.clipboard.fill",
                                value: "\(goalStore.goals.count)",
                                label: "All",
                                color: .blue,
                                isSelected: selectedFilter == .all
                            ) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedFilter = .all
                                }
                            }
                            
                            GoalFilterButton(
                                icon: "checkmark.circle.fill",
                                value: "\(completedGoalsCount)",
                                label: "Completed",
                                color: .green,
                                isSelected: selectedFilter == .completed
                            ) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedFilter = .completed
                                }
                            }
                            
                            GoalFilterButton(
                                icon: "clock.fill",
                                value: "\(inProgressGoalsCount)",
                                label: "In Progress",
                                color: .orange,
                                isSelected: selectedFilter == .inProgress
                            ) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedFilter = .inProgress
                                }
                            }
                            
                            GoalFilterButton(
                                icon: "exclamationmark.triangle.fill",
                                value: "\(highPriorityGoalsCount)",
                                label: "High Priority",
                                color: .red,
                                isSelected: selectedFilter == .highPriority
                            ) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedFilter = .highPriority
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                    // End Custom Header
                    
                    if goalStore.goals.isEmpty {
                        enhancedEmptyStateView
                    } else {
                        enhancedGoalsListView
                    }
                }
            }
            .navigationBarHidden(true)
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 0)
            }
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    HStack(spacing: 10) {
                        Button(action: {
                            if goalStore.canAddMoreGoals {
                                showingAddGoal = true
                            } else {
                                showingUpgrade = true
                            }
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.green)
                                .padding(8)
                                .background(
                                    Circle()
                                        .fill(Color.green.opacity(0.12))
                                )
                        }
                        .contentShape(Rectangle())

                        Button(action: {
                            if goalStore.canAddMoreGoals {
                                showingTemplates = true
                            } else {
                                showingUpgrade = true
                            }
                        }) {
                            Image(systemName: "doc.text.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.blue)
                                .padding(8)
                                .background(
                                    Circle()
                                        .fill(Color.blue.opacity(0.10))
                                )
                        }
                        .contentShape(Rectangle())
                    }
                }
            }
            .sheet(isPresented: $showingAddGoal) {
                AddGoalView(goalStore: goalStore, habitStore: habitStore)
            }
            .sheet(isPresented: $showingTemplates) {
                GoalTemplatesView(goalStore: goalStore, habitStore: habitStore)
            }
            .sheet(isPresented: $showingUpgrade) {
                UpgradeView(purchaseManager: PurchaseService.shared, habitStore: habitStore)
            }
            .sheet(item: $selectedGoal) { goal in
                NavigationView {
                    GoalDetailView(goal: goal, goalStore: goalStore)
                }
            }
            .confirmationDialog(
                "Delete Goal",
                isPresented: $showingDeleteConfirmation
            ) {
                if let goal = goalToDelete {
                    Button("Delete '\(goal.title)'", role: .destructive) {
                        deleteGoal(goal)
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete this goal? This action cannot be undone.")
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 0.6).delay(0.2)) {
                    animateCards = true
                }
                
                // Check for contextual AI suggestions
                Task {
                    await suggestionManager.checkForSuggestion(
                        contentType: .goal,
                        goalStore: goalStore
                    )
                }
            }
        }
    }
    
    // MARK: - Enhanced Empty State
    private var enhancedEmptyStateView: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Clean text content without middle illustration
            VStack(spacing: 32) {
                VStack(spacing: 16) {
                    Text("Set Your Goals")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color.primary,
                                    Color.green.opacity(0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .multilineTextAlignment(.center)
                    
                    Text("Define clear objectives and track your\nprogress towards achieving them.")
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                }
                

                
                // Feature highlights with more space
                VStack(spacing: 12) {
                    ForEach(0..<3, id: \.self) { index in
                        let goalFeatures = [
                            ("flag.fill", "Set clear priorities", Color.purple),
                            ("chart.bar.fill", "Track detailed progress", Color.teal),
                            ("calendar.badge.clock", "Meet important deadlines", Color.orange)
                        ]
                        
                        HStack(spacing: 16) {
                            Circle()
                                .fill(goalFeatures[index].2.opacity(0.15))
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Image(systemName: goalFeatures[index].0)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(goalFeatures[index].2)
                                )
                            
                            Text(goalFeatures[index].1)
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(.secondaryText)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.cardBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(goalFeatures[index].2.opacity(0.2), lineWidth: 1)
                                )
                        )
                    }
                }
                .padding(.horizontal, 24)
            }
            
            Spacer()
            
            // Single action button
            Button(action: { showingAddGoal = true }) {
                HStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text("Create Your First Goal")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [
                            Color.green,
                            Color.mint.opacity(0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(
                    color: Color.green.opacity(0.3),
                    radius: 8,
                    x: 0,
                    y: 4
                )
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Enhanced Goals List View
    private var enhancedGoalsListView: some View {
        VStack(spacing: 0) {
            // Enhanced sort section only
            enhancedSortSection
            
            // Enhanced goals list
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(Array(sortedGoals.enumerated()), id: \.element.id) { index, goal in
                        EnhancedGoalRowView(
                            goal: goal,
                            onTap: {
                                selectedGoal = goal
                            },
                            onToggle: {
                                goalStore.toggleGoalCompletion(goal)
                                forceRefresh.toggle()
                            },
                            onDelete: {
                                goalToDelete = goal
                                showingDeleteConfirmation = true
                            },
                            onIncrement: {
                                goalStore.incrementGoalProgress(goal)
                            },
                            onCompletion: {
                                // This callback is now handled by the parent view
                            }
                        )
                        .offset(x: animateCards ? 0 : 50)
                        .opacity(animateCards ? 1 : 0)
                        .animation(
                            .easeOut(duration: 0.6)
                                .delay(Double(index) * 0.1),
                            value: animateCards
                        )
                        .animation(
                            .easeInOut(duration: 0.4),
                            value: sortedGoals.map { $0.id }
                        )
                    }
                    
                    // AI Suggestion (contextual) - inside ScrollView
                    if suggestionManager.showingSuggestion,
                       let suggestion = suggestionManager.currentSuggestion {
                        UniversalSuggestionView(
                            suggestion: suggestion,
                            onConfirm: {
                                suggestionManager.confirmSuggestion(
                                    suggestion,
                                    habitStore: habitStore,
                                    taskStore: nil,
                                    goalStore: goalStore
                                )
                            },
                            onDismiss: {
                                suggestionManager.dismissSuggestion(suggestion)
                                
                                // Immediately reload new suggestion after dismissal
                                Task {
                                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
                                    await suggestionManager.checkForSuggestion(
                                        contentType: .goal,
                                        goalStore: goalStore
                                    )
                                }
                            }
                        )
                        .padding(.top, 24)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 90) // Adjusted to match actual navigation bar height
            }
        }
    }
    
    // MARK: - Enhanced Header Section
    private var enhancedSortSection: some View {
        VStack(spacing: 16) {
            // Empty section - removed redundant heading and goal count tracker
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 12)
    }
    

    
    // MARK: - Enhanced Feature Card
    private struct EnhancedFeatureCard: View {
        let icon: String
        let text: String
        let color: Color
        let delay: Double
        
        @State private var isAnimating = false
        
        var body: some View {
            HStack(spacing: 16) {
                // Enhanced icon with animation
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 40, height: 40)
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                        .animation(
                            Animation.easeInOut(duration: 2.0)
                                .repeatForever(autoreverses: true)
                                .delay(delay),
                            value: isAnimating
                        )
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(color)
                }
                
                Text(text)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondaryText)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        color.opacity(0.2),
                                        color.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .onAppear {
                isAnimating = true
            }
        }
    }
    
    // MARK: - Helper Methods
    private var sortedGoals: [Goal] {
        let goals = goalStore.goals
        
        // Filter based on selected filter
        let filteredGoals: [Goal]
        switch selectedFilter {
        case .all:
            filteredGoals = goals
        case .completed:
            filteredGoals = goals.filter { $0.isCompleted }
        case .inProgress:
            filteredGoals = goals.filter { !$0.isCompleted }
        case .highPriority:
            filteredGoals = goals.filter { $0.priority == .high }
        }
        
        // Sort by priority first, then put completed goals at the bottom
        return filteredGoals.sorted { goal1, goal2 in
            // First, separate completed and active goals
            if goal1.isCompleted != goal2.isCompleted {
                return !goal1.isCompleted && goal2.isCompleted
            }
            // Then sort by priority within each group
            return goal1.priority.sortOrder < goal2.priority.sortOrder
        }
    }
    
    // MARK: - Computed Properties for Filter Counts
    private var completedGoalsCount: Int {
        goalStore.goals.filter { $0.isCompleted }.count
    }
    
    private var inProgressGoalsCount: Int {
        goalStore.goals.filter { !$0.isCompleted }.count
    }
    
    private var highPriorityGoalsCount: Int {
        goalStore.goals.filter { $0.priority == .high }.count
    }
    
    private func deleteGoal(_ goal: Goal) {
        Task {
            await goalStore.deleteGoal(goal)
        }
    }
}

// MARK: - Goal Filter Button View
struct GoalFilterButton: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            HapticFeedback.shared.lightImpact()
            action()
        }) {
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(isSelected ? .white : color)
                    
                    Text(value)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(isSelected ? .white : .primary)
                }
                
                Text(label)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        isSelected 
                        ? color
                        : color.opacity(0.1)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        isSelected 
                        ? color.opacity(0.3) 
                        : Color.clear,
                        lineWidth: isSelected ? 1 : 0
                    )
            )
            .shadow(
                color: isSelected 
                ? color.opacity(0.3) 
                : Color.clear,
                radius: isSelected ? 4 : 0,
                x: 0,
                y: isSelected ? 2 : 0
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Enhanced Goal Row View
struct EnhancedGoalRowView: View {
    let goal: Goal
    let onTap: () -> Void
    let onToggle: () -> Void
    let onDelete: () -> Void
    let onIncrement: () -> Void
    var onCompletion: (() -> Void)? = nil
    
    @State private var showConfetti = false
    @State private var wasCompleted = false
    @State private var isCardHovered = false
    @State private var completionScale: CGFloat = 1.0
    @State private var cardOffset: CGFloat = 0
    @State private var cardOpacity: Double = 0
    @State private var progressAnimation: CGFloat = 0
    @State private var slideOffset: CGFloat = 0
    @State private var slideOpacity: Double = 1.0
    @State private var isElevated: Bool = false
    @State private var isSliding: Bool = false
    @State private var morphingShape = false
    @State private var glowIntensity: Double = 0.3
    @State private var isDisappearing = false
    @State private var isReappearing = false
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Enhanced background with morphing patterns
                enhancedGoalBackground
                
                // Main content
                VStack(spacing: 16) {
                    // Header with title and priority
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(goal.title)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.primaryText)
                                .multilineTextAlignment(.leading)
                                .lineLimit(2)
                                .strikethrough(goal.isCompleted)
                            
                            Text(goal.description)
                                .font(.caption)
                                .foregroundColor(.secondaryText)
                                .lineLimit(2)
                        }
                        
                        Spacer()
                        
                        // Priority badge
                        Text(goal.priority.rawValue)
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color(hex: goal.priority.color))
                            )
                    }
                    
                    // Progress section
                    VStack(spacing: 8) {
                        HStack {
                            Text("Progress")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondaryText)
                            
                            Spacer()
                            
                            Text("\(goal.currentProgress)/\(goal.targetValue)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.primaryText)
                        }
                        
                        // Enhanced progress bar
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(hex: goal.category.color).opacity(0.2))
                                .frame(height: 8)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(hex: goal.category.color),
                                            Color(hex: goal.category.color).opacity(0.8)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(0, min(CGFloat(goal.currentProgress) / CGFloat(goal.targetValue) * UIScreen.main.bounds.width * 0.7, UIScreen.main.bounds.width * 0.7)), height: 8)
                                .animation(.easeInOut(duration: 0.8), value: goal.currentProgress)
                        }
                    }
                    
                    // Action buttons
                    HStack(spacing: 12) {
                        // Increment button (for measurable goals)
                        if (goal.goalType == .measurable || goal.goalType == .habit) && !goal.isCompleted {
                            Button(action: {
                                withAnimation(AnimationHelper.Curve.bounce) {
                                    completionScale = 1.2
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    withAnimation(AnimationHelper.Curve.smooth) {
                                        completionScale = 1.0
                                    }
                                }
                                onIncrement()
                                HapticFeedback.shared.buttonPress()
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color(hex: goal.category.color))
                                    
                                    Text("Increment")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(Color(hex: goal.category.color))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color(hex: goal.category.color).opacity(0.3), lineWidth: 1)
                                        )
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        Spacer()
                        
                        // Completion toggle button
                        if !goal.isCompleted {
                            Button(action: {
                                withAnimation(AnimationHelper.Curve.lightBounce) {
                                    completionScale = 1.2
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    withAnimation(AnimationHelper.Curve.smooth) {
                                        completionScale = 1.0
                                    }
                                }
                                
                                // Start disappearing animation
                                withAnimation(AnimationHelper.Curve.smooth) {
                                    isDisappearing = true
                                }
                                
                                // After disappearing animation, update the model
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    onToggle()
                                    HapticFeedback.shared.habitCompleted()
                                    
                                    // Reset disappearing state after a short delay
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        isDisappearing = false
                                    }
                                }
                            }) {
                                enhancedCompletionToggleButton
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(20)
            }
            .background(enhancedGoalBackground)
            .opacity(goal.isCompleted ? 0.8 : 1.0)
            .offset(y: slideOffset)
            .opacity(slideOpacity)
            .zIndex(isElevated ? 1000 : 1)
            .scaleEffect(isCardHovered ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isCardHovered)
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            Button("Delete", role: .destructive) {
                onDelete()
            }
        }
        .confetti(isActive: showConfetti, duration: 2.0)
        .opacity(isDisappearing ? 0 : 1)
        .scaleEffect(isDisappearing ? 0.8 : 1.0)
        .offset(y: isDisappearing ? -50 : 0)
        .animation(AnimationHelper.Curve.smooth, value: isDisappearing)
        .onAppear {
            wasCompleted = goal.isCompleted
            cardOpacity = 1.0
            cardOffset = 0
            slideOffset = 0
            slideOpacity = 1.0
            isElevated = false
            isSliding = false
            // Animate progress bar
            withAnimation(.easeInOut(duration: 1.0).delay(0.3)) {
                progressAnimation = goal.progressPercentage
            }
            
            // Start morphing animation
            withAnimation(Animation.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                morphingShape = true
            }
        }
        .onChange(of: goal.isCompleted) { _, isCompleted in
            if isCompleted && !wasCompleted {
                showConfetti = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    showConfetti = false
                }
            }
            wasCompleted = isCompleted
        }
    }
    
    // MARK: - Enhanced UI Components
    private var enhancedGoalBackground: some View {
        let baseGradient = LinearGradient(
            colors: [
                Color(hex: goal.category.color).opacity(0.18),
                Color(hex: goal.category.color).opacity(0.10),
                Color(hex: goal.category.color).opacity(0.05),
                Color(hex: goal.category.color).opacity(0.12),
                Color(hex: goal.category.color).opacity(0.03)
            ],
            startPoint: morphingShape ? .topLeading : .bottomTrailing,
            endPoint: morphingShape ? .bottomTrailing : .topLeading
        )
        
        let strokeGradient = LinearGradient(
            colors: [
                Color(hex: goal.category.color).opacity(0.6),
                Color(hex: goal.category.color).opacity(0.4),
                Color(hex: goal.category.color).opacity(0.2),
                Color(hex: goal.category.color).opacity(0.3)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        return RoundedRectangle(cornerRadius: 32, style: .continuous)
            .fill(baseGradient)
            .overlay(goalGeometricPatterns)
            .overlay(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .stroke(strokeGradient, lineWidth: 2.5)
            )
            .shadow(
                color: Color(hex: goal.category.color).shadowColor(glowIntensity),
                radius: 24,
                x: 0,
                y: 10
            )
    }
    
    private var goalGeometricPatterns: some View {
        ZStack {
            // Goal-specific: Diamond/star-like patterns
            ForEach(0..<5, id: \.self) { index in
                Diamond()
                    .fill(Color(hex: goal.category.color).opacity(0.12))
                    .frame(width: 12 + CGFloat(index * 6), height: 12 + CGFloat(index * 6))
                    .offset(
                        x: morphingShape ? 35 : -35,
                        y: morphingShape ? -25 : 25
                    )
                    .rotationEffect(.degrees(morphingShape ? 90 : -90))
                    .animation(
                        Animation.easeInOut(duration: 5.0)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.4),
                        value: morphingShape
                    )
            }
            
            // Additional star-like elements for goal achievement feel
            ForEach(0..<3, id: \.self) { index in
                Star(points: 5)
                    .fill(Color(hex: goal.category.color).opacity(0.08))
                    .frame(width: 8 + CGFloat(index * 4), height: 8 + CGFloat(index * 4))
                    .offset(
                        x: morphingShape ? -30 : 30,
                        y: morphingShape ? 20 : -20
                    )
                    .rotationEffect(.degrees(morphingShape ? 180 : 0))
                    .animation(
                        Animation.easeInOut(duration: 4.5)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.6),
                        value: morphingShape
                    )
            }
        }
    }
    
    // Custom Diamond shape for goals
    struct Diamond: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            let center = CGPoint(x: rect.midX, y: rect.midY)
            let width = rect.width / 2
            let height = rect.height / 2
            
            path.move(to: CGPoint(x: center.x, y: center.y - height))
            path.addLine(to: CGPoint(x: center.x + width, y: center.y))
            path.addLine(to: CGPoint(x: center.x, y: center.y + height))
            path.addLine(to: CGPoint(x: center.x - width, y: center.y))
            path.closeSubpath()
            
            return path
        }
    }
    
    // Custom Star shape for goals
    struct Star: Shape {
        let points: Int
        
        func path(in rect: CGRect) -> Path {
            var path = Path()
            let center = CGPoint(x: rect.midX, y: rect.midY)
            let radius = min(rect.width, rect.height) / 2
            let innerRadius = radius * 0.4
            
            for i in 0..<points * 2 {
                let angle = Double(i) * .pi / Double(points)
                let currentRadius = i % 2 == 0 ? radius : innerRadius
                let x = center.x + CGFloat(cos(angle)) * currentRadius
                let y = center.y + CGFloat(sin(angle)) * currentRadius
                
                if i == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            path.closeSubpath()
            return path
        }
    }
    
    private var enhancedCompletionToggleButton: some View {
        let categoryColor = Color(hex: goal.category.color)
        let backgroundGradient: AnyShapeStyle = goal.isCompleted ? AnyShapeStyle(Color.successGradient) : AnyShapeStyle(LinearGradient(
            colors: [
                categoryColor.opacity(0.15),
                categoryColor.opacity(0.08)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ))
        let strokeColor: Color = goal.isCompleted ? Color.successGreen : categoryColor.opacity(0.4)
        let shadowColor: Color = goal.isCompleted ? Color.successGreen.shadowColor(opacity: 0.4) : Color.clear
        let iconName = goal.isCompleted ? "checkmark" : "plus"
        let iconColor = goal.isCompleted ? Color.white : categoryColor.opacity(0.8)
        let iconScale: CGFloat = goal.isCompleted ? 1.1 : 1.0
        let iconRotation: Double = goal.isCompleted ? 360 : 0
        
        return ZStack {
            Circle()
                .fill(backgroundGradient)
                .frame(width: 52, height: 52)
                .overlay(
                    Circle()
                        .stroke(strokeColor, lineWidth: 2.5)
                )
                .shadow(
                    color: shadowColor,
                    radius: 10,
                    x: 0,
                    y: 5
                )
            
            Image(systemName: iconName)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(iconColor)
                .scaleEffect(iconScale)
                .rotationEffect(.degrees(iconRotation))
                .animation(AnimationHelper.Curve.bounce, value: goal.isCompleted)
        }
        .scaleEffect(completionScale)
    }
    
    private var enhancedPlusButton: some View {
        let categoryColor = Color(hex: goal.category.color)
        
        return ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            categoryColor.opacity(0.2),
                            categoryColor.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 44, height: 44)
                .overlay(
                    Circle()
                        .stroke(categoryColor.opacity(0.4), lineWidth: 2)
                )
                .shadow(
                    color: categoryColor.opacity(0.2),
                    radius: 6,
                    x: 0,
                    y: 3
                )
            
            Image(systemName: "plus")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(categoryColor)
        }
        .scaleEffect(completionScale)
    }
    
    private var enhancedCategoryIcon: some View {
        let categoryColor = Color(hex: goal.category.color)
        let iconGradient = LinearGradient(
            colors: [
                categoryColor.opacity(0.25),
                categoryColor.opacity(0.15)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        return ZStack {
            Circle()
                .fill(iconGradient)
                .frame(width: 52, height: 52)
                .overlay(
                    Circle()
                        .stroke(categoryColor.opacity(0.4), lineWidth: 2)
                )
                .shadow(
                    color: categoryColor.opacity(0.25),
                    radius: 6,
                    x: 0,
                    y: 3
                )
            
            Image(systemName: goal.category.icon)
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(categoryColor)
        }
    }
    
    private var enhancedPriorityBadge: some View {
        let priorityColor = Color(hex: goal.priority.color)
        let priorityGradient = LinearGradient(
            colors: [
                priorityColor,
                priorityColor.opacity(0.8)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        return Text(goal.priority.rawValue)
            .font(.caption)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(priorityGradient)
            )
            .shadow(
                color: priorityColor.opacity(0.4),
                radius: 4,
                x: 0,
                y: 2
            )
    }
    
    private var enhancedProgressBarSection: some View {
        let progressColor = Color(hex: goal.category.color)
        
        return VStack(spacing: 6) {
            // Enhanced progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(progressColor.opacity(0.15))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [
                                    progressColor,
                                    progressColor.opacity(0.8)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progressAnimation, height: 8)
                        .animation(.easeInOut(duration: 0.8), value: progressAnimation)
                }
            }
            .frame(height: 8)
            
            // Enhanced progress text
            HStack {
                Text("\(Int(goal.progressPercentage * 100))%")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(progressColor)
                
                Spacer()
                
                Text("\(goal.currentProgress)/\(goal.targetValue)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondaryText)
            }
        }
        .padding(.top, 6)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Goal Orbiting Element Component
private struct GoalOrbitingElement: View {
    let index: Int
    let animateCards: Bool
    let color: Color
    @State private var orbitAngle = 0.0
    @State private var pulsate = false
    @State private var floatOffset = 0.0
    
    var body: some View {
        let goalIcons = ["target", "flag.fill", "star.fill", "diamond.fill", "heart.fill", "crown.fill"]
        let orbitRadius = CGFloat(85 + index * 18)
        let baseAngle = Double(index) * 24.0
        
        Image(systemName: goalIcons[index % goalIcons.count])
            .font(.system(size: CGFloat(14 + index % 12), weight: .medium))
            .foregroundColor(color.opacity(0.8))
            .shadow(color: color.opacity(0.5), radius: 3, x: 1, y: 1)
            .offset(
                x: cos((baseAngle + orbitAngle) * .pi / 180) * orbitRadius,
                y: sin((baseAngle + orbitAngle) * .pi / 180) * orbitRadius + floatOffset
            )
            .scaleEffect(pulsate ? 1.4 : 0.9)
            .opacity(pulsate ? 0.9 : 0.6)
            .onAppear {
                // Orbital motion
                withAnimation(
                    Animation.linear(duration: Double.random(in: 12...20))
                        .repeatForever(autoreverses: false)
                        .delay(Double(index) * 0.15)
                ) {
                    orbitAngle = 360
                }
                
                // Pulsation
                withAnimation(
                    Animation.easeInOut(duration: Double.random(in: 1.8...3.5))
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.25)
                ) {
                    pulsate = true
                }
                
                // Floating motion
                withAnimation(
                    Animation.easeInOut(duration: Double.random(in: 2.5...4.0))
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.3)
                ) {
                    floatOffset = CGFloat.random(in: -12...12)
                }
            }
    }
}

#Preview {
    GoalsView(goalStore: GoalStore(), habitStore: HabitStore())
} 