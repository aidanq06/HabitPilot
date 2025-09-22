import SwiftUI

struct ChallengesListView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var challengeManager = ChallengeManager.shared
    @ObservedObject var habitStore: HabitStore
    
    @State private var selectedFilter: ChallengeFilter = .myChallenges
    @State private var showingCreateChallenge = false
    @State private var selectedChallenge: Challenge?
    @State private var showingFilters = false
    @State private var hapticFeedback = UIImpactFeedbackGenerator(style: .medium)
    @State private var searchFieldFocused = false
    @State private var headerOpacity: Double = 1.0
    @State private var contentOffset: CGFloat = 0
    @State private var cardAnimations: [String: Double] = [:]
    
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
    
    var currentChallenges: [Challenge] {
        switch selectedFilter {
        case .myChallenges:
            return challengeManager.myActiveChallenges + challengeManager.myCompletedChallenges
        case .available:
            return challengeManager.availableChallenges
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Enhanced background with animated gradient
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        selectedFilter.color.opacity(0.03),
                        Color(.systemGray6).opacity(0.2)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.8), value: selectedFilter)
                
                VStack(spacing: 0) {
                    // Search bar
                    searchSection
                        .offset(y: contentOffset)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: contentOffset)
                    
                    // Filter selection
                    filterSelectionSection
                        .offset(y: contentOffset)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: contentOffset)
                    
                    // Main content with enhanced animations
                    mainContentSection
                        .offset(y: contentOffset)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: contentOffset)
                }
            }
            .navigationTitle("Challenges")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button(action: {
                        hapticFeedback.impactOccurred()
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            dismiss()
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title3)
                                .symbolRenderingMode(.hierarchical)
                            Text("Done")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.blue)
                    }
                }
                
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    // Small create challenge button
                    Button(action: {
                        hapticFeedback.impactOccurred()
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showingCreateChallenge = true
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundColor(.red)
                    }
                }
            }
            .sheet(isPresented: $showingCreateChallenge) {
                ChallengeCreationView(
                    habitStore: habitStore
                )
            }
            .sheet(item: $selectedChallenge) { challenge in
                ChallengeDetailView(
                    challenge: challenge,
                    challengeManager: challengeManager
                )
            }
            .sheet(isPresented: $showingFilters) {
                ChallengeFiltersView(challengeManager: challengeManager)
            }
            .refreshable {
                hapticFeedback.impactOccurred()
                await challengeManager.refreshChallenges()
            }
            .alert("Error", isPresented: Binding<Bool>(
                get: { challengeManager.errorMessage != nil },
                set: { _ in }
            )) {
                Button("OK") { }
            } message: {
                Text(challengeManager.errorMessage ?? "")
            }
            .overlay(alignment: .bottom) {
                if let successMessage = challengeManager.successMessage {
                    EnhancedSuccessToast(message: successMessage)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: challengeManager.successMessage)
                }
            }
        }
        .onAppear {
            initializeAnimations()
        }
    }
    
    // MARK: - Animation Initialization
    private func initializeAnimations() {
        contentOffset = 50
        headerOpacity = 0.0
        
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
            headerOpacity = 1.0
        }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
            contentOffset = 0
        }
        
        // Initialize card animations
        for challenge in currentChallenges {
            cardAnimations[challenge.id] = 0
            withAnimation(.easeOut(duration: 0.8).delay(0.3 + Double.random(in: 0...0.5))) {
                cardAnimations[challenge.id] = 1.0
            }
        }
    }
    
    // MARK: - Search Section
    private var searchSection: some View {
        VStack(spacing: 16) {
            // Enhanced search bar with better UX
            HStack(spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(searchFieldFocused ? .blue : .secondary)
                        .animation(.easeInOut(duration: 0.2), value: searchFieldFocused)
                    
                    TextField("Search challenges...", text: $challengeManager.searchText)
                        .font(.system(size: 16, weight: .regular))
                        .textFieldStyle(PlainTextFieldStyle())
                        .onTapGesture {
                            searchFieldFocused = true
                        }
                        .onSubmit {
                            searchFieldFocused = false
                        }
                    
                    if !challengeManager.searchText.isEmpty {
                        Button(action: {
                            challengeManager.searchText = ""
                            searchFieldFocused = false
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(searchFieldFocused ? Color.blue.opacity(0.5) : Color.clear, lineWidth: 2)
                        )
                )
                .animation(.easeInOut(duration: 0.2), value: searchFieldFocused)
                
                // Quick filter button
                Button(action: {
                    hapticFeedback.impactOccurred()
                    showingFilters = true
                }) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.blue)
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.blue.opacity(0.1))
                        )
                }
            }
            .padding(.horizontal, 20)
            
            // Enhanced active filters row
            if challengeManager.selectedCategory != nil {
                activeFiltersRow
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.03), radius: 6, x: 0, y: 2)
        )
        .padding(.horizontal, 16)
    }
    
    // MARK: - Enhanced active filters row
    private var activeFiltersRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                if let category = challengeManager.selectedCategory {
                    EnhancedFilterChip(
                        title: category.displayName,
                        icon: category.icon,
                        color: Color(hex: category.color)
                    ) {
                        challengeManager.setCategory(nil)
                    }
                }
                
                Button(action: {
                    hapticFeedback.impactOccurred()
                    challengeManager.clearAllFilters()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                        Text("Clear All")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            colors: [.red, .red.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Filter Selection Section
    private var filterSelectionSection: some View {
        HStack(spacing: 0) {
            ForEach(ChallengeFilter.allCases, id: \.self) { filter in
                Button(action: {
                    hapticFeedback.impactOccurred()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        selectedFilter = filter
                    }
                }) {
                    VStack(spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: filter.icon)
                                .font(.system(size: 17, weight: .medium))
                                .symbolRenderingMode(.hierarchical)
                            
                            Text(filter.rawValue)
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                        }
                        .foregroundColor(selectedFilter == filter ? filter.color : .secondary)
                        .scaleEffect(selectedFilter == filter ? 1.05 : 1.0)
                        
                        // Enhanced active indicator with gradient and animation
                        RoundedRectangle(cornerRadius: 3)
                            .fill(
                                selectedFilter == filter ? 
                                LinearGradient(
                                    colors: [filter.color, filter.color.opacity(0.6)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ) : 
                                LinearGradient(colors: [Color.clear], startPoint: .leading, endPoint: .trailing)
                            )
                            .frame(height: 4)
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedFilter)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .padding(.horizontal, 16)
    }
    
    // MARK: - Enhanced Main Content Section
    @ViewBuilder
    private var mainContentSection: some View {
        if challengeManager.isLoading && currentChallenges.isEmpty {
            enhancedLoadingView
        } else if currentChallenges.isEmpty {
            enhancedEmptyStateView
        } else {
            enhancedChallengesListView
        }
    }
    
    // MARK: - Enhanced Loading View
    private var enhancedLoadingView: some View {
        VStack(spacing: 24) {
            // Animated loading indicator
            ZStack {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .stroke(selectedFilter.color.opacity(0.3), lineWidth: 3)
                        .frame(width: 30 + CGFloat(index * 15), height: 30 + CGFloat(index * 15))
                        .scaleEffect(1.0 + sin(Date().timeIntervalSince1970 * 2 + Double(index)) * 0.3)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: UUID())
                }
                
                Image(systemName: selectedFilter.icon)
                    .font(.system(size: 24, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundColor(selectedFilter.color)
            }
            
            Text("Loading challenges...")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
    
    // MARK: - Enhanced Empty State View
    private var enhancedEmptyStateView: some View {
        VStack(spacing: 32) {
            // Enhanced animated icon with particles
            ZStack {
                // Background circles
                ForEach(0..<5, id: \.self) { index in
                    Circle()
                        .fill(selectedFilter.color.opacity(0.1 - Double(index) * 0.02))
                        .frame(width: 60 + CGFloat(index * 20), height: 60 + CGFloat(index * 20))
                        .scaleEffect(1.0 + sin(Date().timeIntervalSince1970 + Double(index)) * 0.1)
                        .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: UUID())
                }
                
                // Main icon
                Image(systemName: selectedFilter.icon)
                    .font(.system(size: 48, weight: .light))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundColor(selectedFilter.color.opacity(0.7))
                    .scaleEffect(1.0 + sin(Date().timeIntervalSince1970 * 1.5) * 0.1)
                    .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: UUID())
            }
            
            VStack(spacing: 16) {
                Text(emptyStateTitle)
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text(emptyStateMessage)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .lineSpacing(4)
            }
            
            if selectedFilter == .available || selectedFilter == .myChallenges {
                VStack(spacing: 16) {
                    Button(action: {
                        hapticFeedback.impactOccurred()
                        showingCreateChallenge = true
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .symbolRenderingMode(.hierarchical)
                            Text("Create Your First Challenge")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [.red, .red.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(20)
                        .shadow(color: .red.opacity(0.4), radius: 12, x: 0, y: 6)
                    }
                    
                    Button(action: {
                        hapticFeedback.impactOccurred()
                        challengeManager.clearAllFilters()
                        challengeManager.searchText = ""
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.clockwise.circle")
                                .font(.system(size: 16))
                            Text("Refresh & Clear Filters")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.blue.opacity(0.1))
                        )
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 60)
        .padding(.horizontal, 20)
    }
    
    // MARK: - Enhanced Challenges List View
    private var enhancedChallengesListView: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(Array(currentChallenges.enumerated()), id: \.element.id) { index, challenge in
                    ChallengeCardView(
                        challenge: challenge,
                        isParticipating: challengeManager.isParticipating(challenge),
                        onTap: {
                            hapticFeedback.impactOccurred()
                            selectedChallenge = challenge
                        },
                        onJoin: {
                            hapticFeedback.impactOccurred()
                            Task {
                                await challengeManager.joinChallenge(challenge)
                            }
                        },
                        onLeave: {
                            hapticFeedback.impactOccurred()
                            Task {
                                await challengeManager.leaveChallenge(challenge)
                            }
                        }
                    )
                    .scaleEffect(cardAnimations[challenge.id] ?? 0)
                    .opacity(cardAnimations[challenge.id] ?? 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double(index) * 0.1), value: cardAnimations[challenge.id])
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 120) // Extra space for tab bar
        }
        .refreshable {
            await challengeManager.refreshChallenges()
        }
    }
    
    // MARK: - Computed Properties
    private var emptyStateTitle: String {
        switch selectedFilter {
        case .myChallenges:
            return challengeManager.searchText.isEmpty ? "No Challenges Yet" : "No Matches Found"
        case .available:
            return challengeManager.searchText.isEmpty ? "Discover Amazing Challenges!" : "No Matches Found"
        }
    }
    
    private var emptyStateMessage: String {
        switch selectedFilter {
        case .myChallenges:
            return challengeManager.searchText.isEmpty ? "Ready to start your journey? Create or join challenges to build amazing habits and compete with others!" : "Try adjusting your search terms or clearing filters to find your challenges."
        case .available:
            return challengeManager.searchText.isEmpty ? "Join exciting challenges and compete with friends to build better habits and achieve your goals together!" : "Try adjusting your search terms or clearing filters to discover more challenges."
        }
    }
}

// MARK: - Enhanced Supporting Views

struct EnhancedQuickStatCard: View {
    let title: String
    let value: Int
    let icon: String
    let color: Color
    let animationDelay: Double
    
    @State private var animatedValue: Int = 0
    @State private var isVisible = false
    
    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundColor(color)
                
                Text("\(animatedValue)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(color)
                    .contentTransition(.numericText())
            }
            .scaleEffect(isVisible ? 1.0 : 0.8)
            .opacity(isVisible ? 1.0 : 0.0)
            
            Text(title)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .kerning(0.5)
                .lineLimit(1)
                .opacity(isVisible ? 1.0 : 0.0)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [color.opacity(0.15), color.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(animationDelay)) {
                isVisible = true
                animatedValue = value
            }
        }
    }
}

struct EnhancedFeaturedChallengeCard: View {
    let challenge: Challenge
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Enhanced category badge with better styling
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: challenge.category.icon)
                            .font(.system(size: 12, weight: .medium))
                            .symbolRenderingMode(.hierarchical)
                        Text(challenge.category.rawValue.capitalized)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: challenge.category.color), Color(hex: challenge.category.color).opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(10)
                    .shadow(color: Color(hex: challenge.category.color).opacity(0.3), radius: 4, x: 0, y: 2)
                    
                    Spacer()
                }
                
                Spacer()
                
                // Enhanced title and stats
                VStack(alignment: .leading, spacing: 8) {
                    Text(challenge.title)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 11))
                            Text("\(challenge.participants.count)")
                                .font(.system(size: 11, weight: .medium))
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "target")
                                .font(.system(size: 11))
                            Text("\(challenge.targetValue)")
                                .font(.system(size: 11, weight: .medium))
                        }
                        
                        Spacer()
                    }
                    .foregroundColor(.white.opacity(0.9))
                }
            }
            .padding(16)
            .frame(width: 180, height: 140)
            .background(
                ZStack {
                    LinearGradient(
                        colors: [
                            Color(hex: challenge.category.color),
                            Color(hex: challenge.category.color).opacity(0.8),
                            Color(hex: challenge.category.color).opacity(0.9)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    // Subtle pattern overlay
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.1),
                            Color.clear,
                            Color.black.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            )
            .cornerRadius(20)
            .shadow(color: Color(hex: challenge.category.color).opacity(0.4), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: UUID())
    }
}

struct EnhancedFilterChip: View {
    let title: String
    let icon: String
    let color: Color
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .symbolRenderingMode(.hierarchical)
            
            Text(title)
                .font(.system(size: 13, weight: .medium, design: .rounded))
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
                    .symbolRenderingMode(.hierarchical)
            }
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
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

