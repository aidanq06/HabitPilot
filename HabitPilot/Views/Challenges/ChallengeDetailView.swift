import SwiftUI

struct ChallengeDetailView: View {
    let challenge: Challenge
    let challengeManager: ChallengeManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTab: DetailTab = .overview
    @State private var showingLeaderboard = false
    @State private var showingLeaveConfirmation = false
    @State private var hapticFeedback = UIImpactFeedbackGenerator(style: .medium)
    @State private var heroScale: CGFloat = 0.8
    @State private var heroOpacity: Double = 0.0
    @State private var contentOffset: CGFloat = 50
    @State private var progressAnimations: [String: Double] = [:]
    @State private var isLeavingChallenge = false
    
    enum DetailTab: String, CaseIterable {
        case overview = "Overview"
        case participants = "Participants"
        case progress = "Progress"
        
        var icon: String {
            switch self {
            case .overview: return "info.circle"
            case .participants: return "person.2"
            case .progress: return "chart.line.uptrend.xyaxis"
            }
        }
    }
    
    private var isParticipating: Bool {
        challengeManager.isParticipating(challenge)
    }
    
    private var userParticipant: LegacyChallengeParticipant? {
        guard let currentUserId = AuthManager.shared.currentUser?.id else { return nil }
        return challenge.participants.first { $0.userId == currentUserId }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Enhanced background gradient with animation
                LinearGradient(
                    colors: [
                        Color(hex: challenge.category.color).opacity(0.15),
                        Color(hex: challenge.category.color).opacity(0.05),
                        Color(.systemBackground)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.8), value: challenge.category.color)
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Enhanced hero section with animations
                        heroSection
                            .scaleEffect(heroScale)
                            .opacity(heroOpacity)
                        
                        // Enhanced tab selection with smoother transitions
                        tabSelectionSection
                            .offset(y: contentOffset)
                            .opacity(heroOpacity)
                        
                        // Content with staggered animations
                        contentSection
                            .offset(y: contentOffset)
                            .opacity(heroOpacity)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        hapticFeedback.impactOccurred()
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            dismiss()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title3)
                                .symbolRenderingMode(.hierarchical)
                            Text("Close")
                                .font(.system(size: 15, weight: .medium))
                        }
                        .foregroundColor(.primary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        hapticFeedback.impactOccurred()
                        shareChallenge()
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title3)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundColor(.primary)
                    }
                }
            }

        }
        .overlay(alignment: .bottom) {
            if let successMessage = challengeManager.successMessage {
                EnhancedSuccessToast(message: successMessage)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: challengeManager.successMessage)
            }
        }
        .alert("Leave Challenge", isPresented: $showingLeaveConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Leave", role: .destructive) {
                Task {
                    await leaveChallenge()
                }
            }
        } message: {
            Text("Are you sure you want to leave this challenge? Your progress will be lost.")
        }
        .alert("Error", isPresented: .constant(challengeManager.errorMessage != nil)) {
            Button("OK") {
                // Clear error message when user acknowledges it
                Task { @MainActor in
                    challengeManager.clearErrorMessage()
                }
            }
        } message: {
            if let errorMessage = challengeManager.errorMessage {
                Text(errorMessage)
            }
        }
        .onAppear {
            initializeAnimations()
        }
    }
    
    // MARK: - Animation Initialization
    private func initializeAnimations() {
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
            heroScale = 1.0
            heroOpacity = 1.0
        }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
            contentOffset = 0
        }
        
        // Initialize progress animations
        for participant in challenge.participants {
            progressAnimations[participant.id] = 0
            withAnimation(.easeOut(duration: 1.5).delay(0.5 + Double.random(in: 0...0.3))) {
                progressAnimations[participant.id] = 1.0
            }
        }
    }
    
    // MARK: - Share Challenge
    private func shareChallenge() {
        // Placeholder for share functionality
    }
    
    // MARK: - Leave Challenge
    private func leaveChallenge() async {
        isLeavingChallenge = true
        defer { isLeavingChallenge = false }
        
        let success = await challengeManager.leaveChallenge(challenge)
        if success {
            // Dismiss the view after successfully leaving
            dismiss()
        }
        // Error handling is done through the challenge manager's error messages
    }
    
    // MARK: - Enhanced Hero Section
    private var heroSection: some View {
        VStack(spacing: 24) {
            // Enhanced challenge icon with pulsing animation
            VStack(spacing: 16) {
                ZStack {
                    // Pulsing background circles
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .stroke(
                                Color(hex: challenge.category.color).opacity(0.1 - Double(index) * 0.03),
                                lineWidth: 2
                            )
                            .frame(width: 120 + CGFloat(index * 20), height: 120 + CGFloat(index * 20))
                            .scaleEffect(1.0 + sin(Date().timeIntervalSince1970 + Double(index)) * 0.1)
                            .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: UUID())
                    }
                    
                    // Main gradient circle
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(hex: challenge.category.color),
                                    Color(hex: challenge.category.color).opacity(0.8),
                                    Color(hex: challenge.category.color).opacity(0.6)
                                ],
                                center: .topLeading,
                                startRadius: 10,
                                endRadius: 50
                            )
                        )
                        .frame(width: 100, height: 100)
                        .shadow(color: Color(hex: challenge.category.color).opacity(0.4), radius: 20, x: 0, y: 8)
                    
                    Image(systemName: challenge.challengeType.defaultIcon)
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                        .symbolRenderingMode(.hierarchical)
                        .scaleEffect(1.0 + sin(Date().timeIntervalSince1970 * 1.5) * 0.05)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: UUID())
                }
                
                // Enhanced category and type badges
                HStack(spacing: 12) {
                    CategoryBadge(
                        text: challenge.category.rawValue.capitalized,
                        color: Color(hex: challenge.category.color),
                        icon: challenge.category.icon
                    )
                    
                    TypeBadge(
                        text: challenge.challengeType.rawValue,
                        color: .secondary
                    )
                }
            }
            
            // Enhanced title and description with better typography
            VStack(spacing: 12) {
                Text(challenge.title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                
                if !challenge.description.isEmpty {
                    Text(challenge.description)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(4)
                        .padding(.horizontal, 20)
                }
            }
            
            // Enhanced stats with animated counters
            HStack(spacing: 32) {
                AnimatedStatCard(
                    value: challenge.participants.count,
                    label: "Participants",
                    icon: "person.2.fill",
                    color: .blue,
                    animationDelay: 0.3
                )
                
                AnimatedStatCard(
                    value: challenge.targetValue,
                    label: "Target \(challenge.challengeType.unit)",
                    icon: "target",
                    color: Color(hex: challenge.category.color),
                    animationDelay: 0.4
                )
                
                AnimatedStatCard(
                    value: challenge.isExpired ? 0 : challenge.daysRemaining,
                    label: challenge.isExpired ? "Ended" : "Days Left",
                    icon: challenge.isExpired ? "checkmark.seal.fill" : "calendar",
                    color: challenge.isExpired ? .red : .green,
                    animationDelay: 0.5
                )
            }
            
            // Enhanced action buttons with better interactions
            actionButtonsSection
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 32)
    }
    
    // MARK: - Enhanced Action Buttons Section
    private var actionButtonsSection: some View {
        HStack(spacing: 16) {
            if isParticipating {
                // Enhanced leave button - more prominent
                Button(action: {
                    hapticFeedback.impactOccurred()
                    showingLeaveConfirmation = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "minus.circle.fill")
                            .font(.title3)
                            .symbolRenderingMode(.hierarchical)
                        Text("Leave")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [.red, .red.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(20)
                    .shadow(color: .red.opacity(0.3), radius: 6, x: 0, y: 3)
                }
                .disabled(isLeavingChallenge)
                
            } else {
                // Enhanced join button
                Button(action: {
                    hapticFeedback.impactOccurred()
                    Task {
                        await challengeManager.joinChallenge(challenge)
                    }
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "person.badge.plus.fill")
                            .font(.title3)
                            .symbolRenderingMode(.hierarchical)
                        Text("Join Challenge")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        SwiftUI.Group {
                            if challenge.isActive && !challenge.isExpired {
                                LinearGradient(
                                    colors: [
                                        Color(hex: challenge.category.color),
                                        Color(hex: challenge.category.color).opacity(0.8),
                                        Color(hex: challenge.category.color)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            } else {
                                LinearGradient(
                                    colors: [Color.gray, Color.gray.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            }
                        }
                    )
                    .cornerRadius(20)
                    .shadow(
                        color: challenge.isActive && !challenge.isExpired 
                        ? Color(hex: challenge.category.color).opacity(0.4) 
                        : Color.gray.opacity(0.3), 
                        radius: 12, x: 0, y: 6
                    )
                }
                .disabled(!challenge.isActive || challenge.isExpired)
                .scaleEffect(challenge.isActive && !challenge.isExpired ? 1.0 : 0.95)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: challenge.isActive && !challenge.isExpired)
            }
        }
    }
    
    // MARK: - Enhanced Tab Selection Section
    private var tabSelectionSection: some View {
        HStack(spacing: 0) {
            ForEach(DetailTab.allCases, id: \.self) { tab in
                Button(action: {
                    hapticFeedback.impactOccurred()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 17, weight: .medium))
                                .symbolRenderingMode(.hierarchical)
                            
                            Text(tab.rawValue)
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                        }
                        .foregroundColor(selectedTab == tab ? Color(hex: challenge.category.color) : .secondary)
                        .scaleEffect(selectedTab == tab ? 1.05 : 1.0)
                        
                        // Enhanced active indicator with gradient
                        RoundedRectangle(cornerRadius: 2)
                            .fill(
                                selectedTab == tab ? 
                                LinearGradient(
                                    colors: [
                                        Color(hex: challenge.category.color),
                                        Color(hex: challenge.category.color).opacity(0.6)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ) : 
                                LinearGradient(colors: [Color.clear], startPoint: .leading, endPoint: .trailing)
                            )
                            .frame(height: 4)
                            .animation(.spring(response: 0.4), value: selectedTab)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .padding(.horizontal, 20)
    }
    
    // MARK: - Enhanced Content Section
    private var contentSection: some View {
        SwiftUI.Group {
            switch selectedTab {
            case .overview:
                overviewContent
            case .participants:
                participantsContent
            case .progress:
                progressContent
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 120)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: selectedTab)
    }
    
    // MARK: - Enhanced Overview Content
    private var overviewContent: some View {
        VStack(spacing: 28) {
            // Enhanced challenge details card
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("Challenge Details")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "info.circle.fill")
                        .font(.title3)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundColor(Color(hex: challenge.category.color))
                }
                
                VStack(spacing: 16) {
                    EnhancedDetailRow(
                        icon: "calendar.badge.plus",
                        title: "Start Date",
                        value: challenge.createdAt.formatted(date: .abbreviated, time: .omitted),
                        color: .green
                    )
                    
                    EnhancedDetailRow(
                        icon: "flag.checkered.2.crossed",
                        title: "End Date",
                        value: challenge.endDate.formatted(date: .abbreviated, time: .omitted),
                        color: .red
                    )
                    
                    EnhancedDetailRow(
                        icon: "person.crop.circle.badge.checkmark",
                        title: "Created By",
                        value: challenge.createdBy,
                        color: .blue
                    )
                    
                    EnhancedDetailRow(
                        icon: "target",
                        title: "Challenge Type",
                        value: challenge.challengeType.rawValue,
                        color: Color(hex: challenge.category.color)
                    )
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
            )
            
            // Enhanced user progress card
            if isParticipating, let participant = userParticipant {
                enhancedUserProgressCard(participant)
            }
        }
        .padding(.vertical, 24)
    }
    
    // MARK: - Enhanced Participants Content
    private var participantsContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Participants")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("(\(challenge.participants.count))")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Image(systemName: "person.2.fill")
                    .font(.title3)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundColor(Color(hex: challenge.category.color))
            }
            
            LazyVStack(spacing: 16) {
                ForEach(Array(challenge.participants.sorted { $0.currentValue > $1.currentValue }.enumerated()), id: \.element.id) { index, participant in
                    EnhancedParticipantRowView(
                        participant: participant,
                        rank: index + 1,
                        isCurrentUser: participant.userId == AuthManager.shared.currentUser?.id,
                        targetValue: challenge.targetValue,
                        categoryColor: challenge.category.color,
                        progressAnimation: progressAnimations[participant.id] ?? 0
                    )
                }
            }
        }
        .padding(.vertical, 24)
    }
    
    // MARK: - Enhanced Progress Content
    private var progressContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Text("Progress Overview")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title3)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundColor(Color(hex: challenge.category.color))
            }
            
            if isParticipating, let participant = userParticipant {
                // Enhanced user's detailed progress
                enhancedUserProgressCard(participant)
                
                // Progress insights card
                VStack(alignment: .leading, spacing: 16) {
                    Text("Progress Insights")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    VStack(spacing: 12) {
                        ProgressInsightRow(
                            icon: "chart.bar.fill",
                            title: "Daily Average",
                            value: String(format: "%.1f", Double(participant.currentValue) / Double(max(1, Calendar.current.dateComponents([.day], from: challenge.createdAt, to: Date()).day ?? 1))),
                            color: .blue
                        )
                        
                        ProgressInsightRow(
                            icon: "speedometer",
                            title: "Progress Rate",
                            value: "\(participant.progressPercentage)%",
                            color: .green
                        )
                        
                        ProgressInsightRow(
                            icon: "flame.fill",
                            title: "Remaining",
                            value: "\(participant.targetValue - participant.currentValue)",
                            color: .red
                        )
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(hex: challenge.category.color).opacity(0.05))
                )
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "chart.line.uptrend.xyaxis.circle")
                        .font(.system(size: 60))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundColor(Color(hex: challenge.category.color).opacity(0.6))
                    
                    Text("Join the challenge to track your progress!")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 60)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 24)
    }
    
    // MARK: - Enhanced User Progress Card
    private func enhancedUserProgressCard(_ participant: LegacyChallengeParticipant) -> some View {
        VStack(spacing: 20) {
            HStack {
                Text("Your Progress")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(participant.currentValue)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: challenge.category.color))
                    
                    Text("of \(participant.targetValue)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            
            // Enhanced progress visualization
            VStack(spacing: 12) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background with subtle pattern
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(hex: challenge.category.color).opacity(0.1))
                            .frame(height: 20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(Color(hex: challenge.category.color).opacity(0.2), lineWidth: 1)
                            )
                        
                        // Animated progress with multiple layers
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(hex: challenge.category.color),
                                        Color(hex: challenge.category.color).opacity(0.8),
                                        Color(hex: challenge.category.color),
                                        Color(hex: challenge.category.color).opacity(0.9)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(
                                width: geometry.size.width * participant.progress * (progressAnimations[participant.id] ?? 0),
                                height: 20
                            )
                            .overlay(
                                // Shimmer effect
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0),
                                                Color.white.opacity(0.4),
                                                Color.white.opacity(0)
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: 60)
                                    .offset(x: (progressAnimations[participant.id] ?? 0) * (geometry.size.width + 60) - 60)
                                    .animation(.linear(duration: 2.5).repeatForever(autoreverses: false), value: progressAnimations[participant.id])
                            )
                            .animation(.easeOut(duration: 1.5).delay(0.3), value: progressAnimations[participant.id])
                    }
                }
                .frame(height: 20)
                
                HStack {
                    Text("\(participant.progressPercentage)% Complete")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if participant.isCompleted {
                        HStack(spacing: 6) {
                            Image(systemName: "star.fill")
                                .symbolRenderingMode(.multicolor)
                            Text("Completed!")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.yellow)
                        .scaleEffect((progressAnimations[participant.id] ?? 0) * 1.0)
                    }
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: challenge.category.color).opacity(0.08),
                            Color(hex: challenge.category.color).opacity(0.04)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(hex: challenge.category.color).opacity(0.3),
                                    Color(hex: challenge.category.color).opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
}

// MARK: - Enhanced Supporting Views

struct CategoryBadge: View {
    let text: String
    let color: Color
    let icon: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
            Text(text)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            LinearGradient(
                colors: [color, color.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
        .shadow(color: color.opacity(0.3), radius: 4, x: 0, y: 2)
    }
}

struct TypeBadge: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundColor(color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(.systemGray6))
            .cornerRadius(12)
    }
}

struct AnimatedStatCard: View {
    let value: Int
    let label: String
    let icon: String
    let color: Color
    let animationDelay: Double
    
    @State private var animatedValue: Int = 0
    @State private var isVisible = false
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundColor(color)
                
                Text("\(animatedValue)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(color)
                    .contentTransition(.numericText())
            }
            .scaleEffect(isVisible ? 1.0 : 0.8)
            .opacity(isVisible ? 1.0 : 0.0)
            
            Text(label)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .opacity(isVisible ? 1.0 : 0.0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(animationDelay)) {
                isVisible = true
                animatedValue = value
            }
        }
    }
}

struct EnhancedDetailRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .symbolRenderingMode(.hierarchical)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct EnhancedParticipantRowView: View {
    let participant: LegacyChallengeParticipant
    let rank: Int
    let isCurrentUser: Bool
    let targetValue: Int
    let categoryColor: String
    let progressAnimation: Double
    
    private var progressPercentage: Double {
        guard targetValue > 0 else { return 0 }
        return min(Double(participant.currentValue) / Double(targetValue), 1.0)
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Enhanced rank badge with better visuals
            ZStack {
                Circle()
                    .fill(
                        rank == 1 ? 
                        LinearGradient(colors: [.yellow, .red], startPoint: .topLeading, endPoint: .bottomTrailing) :
                        rank == 2 ? 
                        LinearGradient(colors: [.gray, .black.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                        rank == 3 ? 
                        LinearGradient(colors: [.red, .red.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                        LinearGradient(colors: [Color(hex: categoryColor).opacity(0.3), Color(hex: categoryColor).opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 36, height: 36)
                    .shadow(color: rank <= 3 ? .black.opacity(0.2) : .clear, radius: 4, x: 0, y: 2)
                
                if rank <= 3 {
                    Image(systemName: rank == 1 ? "crown.fill" : rank == 2 ? "medal.fill" : "rosette")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .symbolRenderingMode(.hierarchical)
                } else {
                    Text("\(rank)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: categoryColor))
                }
            }
            
            // Enhanced user info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(participant.username)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    if isCurrentUser {
                        Text("(You)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color(hex: categoryColor))
                            .cornerRadius(8)
                    }
                }
                
                Text("\(participant.currentValue) of \(targetValue)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Enhanced progress visualization
            VStack(alignment: .trailing, spacing: 6) {
                Text("\(Int(progressPercentage * 100))%")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: categoryColor))
                
                if participant.isCompleted {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.seal.fill")
                            .symbolRenderingMode(.multicolor)
                        Text("Done!")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.green)
                    .scaleEffect(progressAnimation * 1.0)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    isCurrentUser ? 
                    LinearGradient(
                        colors: [
                            Color(hex: categoryColor).opacity(0.15),
                            Color(hex: categoryColor).opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ) :
                    LinearGradient(colors: [Color(.systemBackground)], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isCurrentUser ? 
                            Color(hex: categoryColor).opacity(0.3) :
                            Color.clear,
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: isCurrentUser ? Color(hex: categoryColor).opacity(0.1) : .clear, radius: 4, x: 0, y: 2)
    }
}

struct ProgressInsightRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .symbolRenderingMode(.hierarchical)
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(color)
        }
    }
}

