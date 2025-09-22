import SwiftUI

struct HabitRowView: View {
    let habit: Habit
    let onToggleCompletion: () -> Void
    let onToggleEnabled: () -> Void
    let onTap: () -> Void
    let onDelete: () -> Void // Not used anymore, but kept for interface compatibility
    @EnvironmentObject var purchaseManager: PurchaseService
    @EnvironmentObject var habitStore: HabitStore
    
    @State private var isStreakAnimating = false
    @State private var showStreakGlow = false
    @State private var isPressed = false
    @State private var showConfetti = false
    @State private var wasCompleted = false
    @State private var isCardHovered = false
    @State private var completionScale: CGFloat = 1.0
    @State private var slideOffset: CGFloat = 0
    @State private var slideOpacity: Double = 1.0
    @State private var isElevated: Bool = false
    @State private var pulseAnimation = false
    @State private var rotationAngle: Double = 0
    @State private var glowIntensity: Double = 0
    @State private var morphingShape = false
    @State private var isDisappearing = false
    @State private var isReappearing = false
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Simplified background layer for better performance
                backgroundLayer
                
                // Main content with unique layout
                HStack(spacing: 12) { // Slightly more spacing between completion area and main content
                    // Left side - Animated completion area
                    completionArea
                    
                    // Main habit info - takes up remaining space and forces left alignment
                    VStack(alignment: .leading, spacing: 8) {
                        // Title
                        Text(habit.name)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(textColor)
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Description
                        if !habit.description.isEmpty {
                            Text(habit.description)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(textColor.opacity(0.7))
                                .fixedSize(horizontal: false, vertical: true)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        // Progress for incremental habits
                        if habit.type == .incremental {
                            HStack(spacing: 6) {
                                Text("\(habit.todayProgress)/\(habit.dailyTarget)")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundColor(textColor)
                                
                                Text("(\(Int(habit.progressFraction * 100))%)")
                                    .font(.system(size: 10, weight: .medium, design: .rounded))
                                    .foregroundColor(textColor.opacity(0.6))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .layoutPriority(1)
                    
                    // Right side - Action area for incremental habits
                    if habit.type == .incremental {
                        actionArea
                    }
                }
                .padding(.vertical, 16)
            }
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color.clear)
            )
            .opacity(habit.isEnabled ? 1.0 : 0.6)
            .scaleEffect(habit.isEnabled ? 1.0 : 0.98)
            .scaleEffect(isCardHovered ? 1.02 : 1.0)
            .zIndex(isElevated ? 1000 : 1)
            .shadow(
                color: isCardHovered ? .black.opacity(0.15) : .clear,
                radius: isCardHovered ? 15 : 0,
                x: 0,
                y: isCardHovered ? 8 : 0
            )
            .animation(AnimationHelper.Curve.smooth, value: habit.isEnabled)
            .animation(AnimationHelper.Curve.smooth, value: isCardHovered)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .confetti(isActive: showConfetti, duration: 1.5)
        .opacity(isDisappearing ? 0 : 1)
        .scaleEffect(isDisappearing ? 0.95 : 1.0)
        .animation(AnimationHelper.Curve.quick, value: isDisappearing)
        .onAppear {
            wasCompleted = habit.isCompletedToday()
            isElevated = false
            // Reduced animations for better performance
            if habit.streak > 0 {
                isStreakAnimating = true
            }
        }
        .onTapGesture {
            withAnimation(AnimationHelper.Curve.bounce) {
                isCardHovered = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(AnimationHelper.Curve.smooth) {
                    isCardHovered = false
                }
            }
            
            onTap()
        }
        .onChange(of: habit.isCompletedToday()) { _, isCompleted in
            if isCompleted && !wasCompleted {
                // Simplified completion animation
                showConfetti = true
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    showConfetti = false
                }
            }
            wasCompleted = isCompleted
        }
        .onChange(of: habit.streak) { _, newStreak in
            if newStreak > 0 && isMilestone(newStreak) {
                HapticFeedback.shared.streakMilestone()
            }
        }
    }
    
    // MARK: - Completion Area
    private var completionArea: some View {
        VStack(spacing: 0) {
            ZStack {
                // Simplified completion ring with better performance
                Circle()
                    .stroke(
                        habit.isCompletedToday() 
                        ? AnyShapeStyle(Color.successGradient)
                        : AnyShapeStyle(bgColor.opacity(0.3)),
                        lineWidth: 3
                    )
                    .frame(width: 70, height: 70)
                
                // Inner completion circle
                Circle()
                    .fill(
                        habit.isCompletedToday() 
                        ? AnyShapeStyle(Color.successGradient)
                        : AnyShapeStyle(LinearGradient(
                            colors: [bgColor.opacity(0.8), bgColor.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                    )
                    .frame(width: 50, height: 50)
                    .overlay(
                        Circle()
                            .stroke(
                                habit.isCompletedToday() 
                                ? Color.successGreen 
                                : bgColor.opacity(0.4),
                                lineWidth: 2
                            )
                    )
                    .shadow(
                        color: habit.isCompletedToday() 
                        ? Color.successGreen.shadowColor(0.4)
                        : bgColor.shadowColor(0.3),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
                
                // Completion icon with fixed rotation
                Image(systemName: habit.isCompletedToday() ? "checkmark" : "plus")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(habit.isCompletedToday() ? .white : textColor)
                    .rotationEffect(.degrees(habit.isCompletedToday() ? 0 : 0))
                    .scaleEffect(completionScale)
                    .animation(AnimationHelper.Curve.bounce, value: habit.isCompletedToday())
            }
            .onTapGesture {
                if habit.type == .simple {
                    // Optimized completion animation
                    withAnimation(AnimationHelper.Curve.bounce) {
                        completionScale = 1.3
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(AnimationHelper.Curve.smooth) {
                            completionScale = 1.0
                        }
                    }
                    
                    // Start disappearing animation
                    withAnimation(AnimationHelper.Curve.quick) {
                        isDisappearing = true
                    }
                    
                    // After disappearing animation, update the model
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        onToggleCompletion()
                        HapticFeedback.shared.habitCompleted()
                        
                        // Reset disappearing state after a short delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            isDisappearing = false
                        }
                    }
                }
            }
            
            // Streak indicator with simplified animation
            if habit.streak > 0 {
                HStack(spacing: 4) {
                    ForEach(0..<min(fireCount, 3), id: \.self) { index in
                        Text("🔥")
                            .font(.system(size: 12))
                    }
                    
                    Text("\(habit.streak)")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(streakBackgroundColor)
                        )
                }
                .padding(.top, 4)
            }
            
            // Progress bar for incremental habits
            if habit.type == .incremental {
                ProgressBar(
                    progress: habit.progressFraction,
                    backgroundColor: bgColor.opacity(0.2),
                    progressColor: bgColor,
                    height: 6,
                    animated: true
                )
                .padding(.top, 4)
            }
        }
        .frame(width: 70, alignment: .center) // Fixed width instead of maxWidth: .infinity
        .padding(.leading, 12) // Slightly more padding to prevent button from touching the edge
    }
    

    
    // MARK: - Action Area
    private var actionArea: some View {
        VStack(spacing: 8) {
            Button(action: {
                withAnimation(AnimationHelper.Curve.bounce) {
                    completionScale = 1.2
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(AnimationHelper.Curve.smooth) {
                        completionScale = 1.0
                    }
                }
                
                habitStore.incrementHabitProgress(habit)
                HapticFeedback.shared.habitCompleted()
            }) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [bgColor.opacity(0.8), bgColor.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                        .overlay(
                            Circle()
                                .stroke(bgColor.opacity(0.4), lineWidth: 2)
                        )
                        .shadow(color: bgColor.shadowColor(0.3), radius: 4, x: 0, y: 2)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(textColor)
                        .scaleEffect(completionScale)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            Text("\(habit.todayProgress)/\(habit.dailyTarget)")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.horizontal, 16)
    }
    
    // MARK: - Background Layer
    private var backgroundLayer: some View {
        let baseGradient = LinearGradient(
            colors: [
                bgColor.opacity(0.12),
                bgColor.opacity(0.06),
                bgColor.opacity(0.02)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        return RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(baseGradient)
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(bgColor.opacity(0.2), lineWidth: 1.0)
            )
    }
    
    private var simplifiedGeometricPatterns: some View {
        ZStack {
            // Reduced to 2 patterns for better performance
            ForEach(0..<2, id: \.self) { index in
                Circle()
                    .fill(bgColor.opacity(0.08))
                    .frame(width: 15 + CGFloat(index * 10), height: 15 + CGFloat(index * 10))
                    .offset(
                        x: morphingShape ? 20 : -20,
                        y: morphingShape ? -15 : 15
                    )
                    .animation(
                        Animation.easeInOut(duration: 4.0) // Slower animation for better performance
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.8),
                        value: morphingShape
                    )
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var bgColor: Color {
        Color(hex: habit.colorHex)
    }
    
    private var textColor: Color {
        Color.primary
    }
    
    private var fireCount: Int {
        min(habit.streak, 5)
    }
    
    private var fireSize: CGFloat {
        switch fireCount {
        case 1: return 14
        case 2: return 12
        case 3: return 10
        default: return 8
        }
    }
    
    private var streakBackgroundColor: Color {
        switch habit.streak {
        case 1...6: return .orange
        case 7...13: return .red
        case 14...20: return .purple
        case 21...27: return .blue
        case 28...34: return .green
        default: return .yellow
        }
    }
    
    private var streakGlowColor: Color {
        switch habit.streak {
        case 1...6: return .orange
        case 7...13: return .red
        case 14...20: return .purple
        case 21...27: return .blue
        case 28...34: return .green
        default: return .yellow
        }
    }
    
    private func isMilestone(_ streak: Int) -> Bool {
        return streak % 7 == 0 || streak % 10 == 0
    }
}

// MARK: - Color Extensions
extension Color {
    var shadowColor: (Double) -> Color {
        return { opacity in
            self.opacity(opacity)
        }
    }
}

// MARK: - AI Suggested Habit Row View
struct SuggestedHabitRowView: View {
    let suggestion: SuggestedHabit
    let onConfirm: () -> Void
    let onDismiss: () -> Void
    
    @State private var isPressed = false
    @State private var confirmScale: CGFloat = 1.0
    @State private var dismissScale: CGFloat = 1.0
    @State private var showingDetails = false
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Main suggestion row
            HStack(spacing: 16) {
                // Left side - Category icon and difficulty indicator
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: suggestion.colorHex).opacity(0.15))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: categoryIcon)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(Color(hex: suggestion.colorHex))
                    }
                    
                    // Difficulty badge
                    HStack(spacing: 4) {
                        Image(systemName: suggestion.difficulty.icon)
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text(suggestion.difficulty.rawValue)
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color(hex: suggestion.difficulty.color))
                    )
                }
                
                // Center content - Habit details
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .top) {
                        Text(suggestion.name)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.leading)
                        
                        Spacer(minLength: 8)
                        
                        // AI badge
                        HStack(spacing: 4) {
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("AI")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(LinearGradient(
                                    colors: [Color.blue, Color.purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                        )
                    }
                    
                    Text(suggestion.description)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                    
                    // Metadata row
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.orange)
                            
                            Text("\(suggestion.estimatedTimeMinutes)m")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: suggestion.frequency.icon)
                                .font(.system(size: 10))
                                .foregroundColor(.blue)
                            
                            Text(suggestion.frequency.displayName)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        
                        if suggestion.type == .incremental {
                            HStack(spacing: 4) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.green)
                                
                                Text("\(suggestion.dailyTarget)x")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                    }
                }
                
                // Right side - Action buttons
                VStack(spacing: 8) {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            confirmScale = 1.2
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                confirmScale = 1.0
                            }
                        }
                        
                        HapticFeedback.shared.successNotification()
                        onConfirm()
                    }) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [Color.green, Color.green.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 44, height: 44)
                                .shadow(color: Color.green.opacity(0.3), radius: 6, x: 0, y: 3)
                            
                            Image(systemName: "checkmark")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .scaleEffect(confirmScale)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            dismissScale = 1.2
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                dismissScale = 1.0
                            }
                        }
                        
                        HapticFeedback.shared.lightImpact()
                        onDismiss()
                    }) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [Color.secondary, Color.secondary.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 44, height: 44)
                                .shadow(color: Color.secondary.opacity(0.2), radius: 4, x: 0, y: 2)
                            
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .scaleEffect(dismissScale)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            // Expandable details section
            if showingDetails {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                        .background(Color(hex: suggestion.colorHex).opacity(0.3))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Why this habit?")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text(suggestion.reasoning)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    if !suggestion.benefits.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Key Benefits")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(suggestion.benefits.prefix(3), id: \.self) { benefit in
                                    HStack(spacing: 8) {
                                        Circle()
                                            .fill(Color(hex: suggestion.colorHex))
                                            .frame(width: 4, height: 4)
                                        
                                        Text(benefit)
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity.combined(with: .move(edge: .top))
                ))
            }
        }
        .background(backgroundView)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onTapGesture {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                showingDetails.toggle()
            }
            HapticFeedback.shared.lightImpact()
        }
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .onAppear {
            isAnimating = true
        }
    }
    
    // MARK: - Background View Helper
    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(Color.secondaryBackground)
            .overlay(dashedBorderOverlay)
    }
    
    private var dashedBorderOverlay: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .stroke(
                Color(hex: suggestion.colorHex).opacity(0.6),
                style: StrokeStyle(
                    lineWidth: 2,
                    lineCap: .round,
                    dash: [8, 6]
                )
            )
            .opacity(isAnimating ? 0.8 : 0.6)
            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
    }
    
    private var categoryIcon: String {
        switch suggestion.category.lowercased() {
        case "health": return "heart.fill"
        case "fitness": return "figure.run"
        case "productivity": return "briefcase.fill"
        case "mindfulness": return "leaf.fill"
        case "learning": return "book.fill"
        default: return "star.fill"
        }
    }
}

// MARK: - Universal Suggestion View (Bottom of List)
struct UniversalSuggestionView: View {
    let suggestion: SuggestedItem
    let onConfirm: () -> Void
    let onDismiss: () -> Void
    
    @State private var isCardHovered = false
    @State private var morphingShape = false
    @State private var showingDetails = false
    @State private var confirmScale: CGFloat = 1.0
    @State private var dismissScale: CGFloat = 1.0
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                showingDetails.toggle()
            }
            HapticFeedback.shared.lightImpact()
        }) {
            ZStack {
                // Background matching HabitRowView style exactly
                suggestionBackgroundLayer
                
                // Main content with same layout as HabitRowView
                HStack(spacing: 0) {
                    // Left side - Icon area (matches HabitRowView completion area)
                    suggestionIconArea
                    
                    // Center content - Main suggestion info (gets remaining width)
                    suggestionContentArea
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Right side - AI badge and dismiss button
                    VStack(alignment: .trailing, spacing: 8) {
                        // Small dismiss button (top-right)
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                dismissScale = 1.2
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    dismissScale = 1.0
                                }
                            }
                            
                            onDismiss()
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.secondary.opacity(0.6))
                                .frame(width: 18, height: 18)
                                .background(
                                    Circle()
                                        .fill(Color.secondary.opacity(0.1))
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .scaleEffect(dismissScale)
                        
                        Spacer()
                        
                        // AI badge at bottom-right
                        HStack(spacing: 3) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 8, weight: .medium))
                                .foregroundColor(.white)
                            
                            Text("AI")
                                .font(.system(size: 8, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(Color.purple.opacity(0.7))
                        )
                    }
                    .padding(.trailing, 16)
                }
                .padding(.vertical, 16)
                
                // Adaptive overlay with why now content
                if showingDetails {
                    whyNowOverlay
                }
            }
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color.clear)
            )
            .scaleEffect(isCardHovered ? 1.02 : 1.0)
            .shadow(
                color: isCardHovered ? .black.opacity(0.15) : .clear,
                radius: isCardHovered ? 15 : 0,
                x: 0,
                y: isCardHovered ? 8 : 0
            )
            .animation(AnimationHelper.Curve.smooth, value: isCardHovered)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .onAppear {
            morphingShape = true
        }
        .onTapGesture {
            withAnimation(AnimationHelper.Curve.bounce) {
                isCardHovered = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(AnimationHelper.Curve.smooth) {
                    isCardHovered = false
                }
            }
        }
    }
    
    // MARK: - Suggestion Icon Area
    private var suggestionIconArea: some View {
        VStack(spacing: 0) {
            ZStack {
                // Icon background
                                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(hex: suggestionColorHex).opacity(0.15),
                                        Color(hex: suggestionColorHex).opacity(0.08)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 70, height: 70)
                            .overlay(
                                Circle()
                                    .stroke(
                                        Color(hex: suggestionColorHex).opacity(0.3),
                                        lineWidth: 2
                                    )
                            )
                
                // Icon
                Image(systemName: suggestionIcon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(Color(hex: suggestionColorHex))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
    }
    
    // MARK: - Suggestion Content Area
    private var suggestionContentArea: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title and description (like regular habit)
            Text(suggestionName)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)
            
            if !suggestionReasoning.isEmpty {
                Text(suggestionReasoning)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer(minLength: 0)
            
            // Type indicator at the bottom
            HStack {
                Text(suggestionTypeName.uppercased())
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: suggestionColorHex))
                    .tracking(0.5)
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
    }
    
    // MARK: - Suggestion Background Layer (adaptive with dashed border)
    private var suggestionBackgroundLayer: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(
                        Color(hex: suggestionColorHex).opacity(0.4),
                        style: StrokeStyle(
                            lineWidth: 2.0,
                            lineCap: .round,
                            dash: [8, 6]
                        )
                    )
                    .opacity(morphingShape ? 0.8 : 0.6)
                    .animation(
                        Animation.easeInOut(duration: 2.0)
                            .repeatForever(autoreverses: true),
                        value: morphingShape
                    )
            )
    }
    
    // MARK: - Adaptive Overlay with Why Now Content
    private var whyNowOverlay: some View {
        ZStack {
            // Adaptive background covering the entire card
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: Color(.sRGBLinear, white: 0, opacity: 0.1), radius: 8, x: 0, y: 4)
            
            VStack(alignment: .leading, spacing: 16) {
                // Header with close button
                HStack {
                    Text("Why now?")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            showingDetails = false
                        }
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(width: 24, height: 24)
                            .background(
                                Circle()
                                    .fill(Color.secondary.opacity(0.1))
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Reasoning
                Text(suggestionReasoning)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
                
                // Benefits based on suggestion type
                if let benefits = suggestionBenefits, !benefits.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Benefits")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(benefits.prefix(3), id: \.self) { benefit in
                                HStack(spacing: 10) {
                                    Circle()
                                        .fill(Color(hex: suggestionColorHex))
                                        .frame(width: 4, height: 4)
                                        .padding(.top, 2)
                                    
                                    Text(benefit)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.primary.opacity(0.7))
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }
                }
                
                // Add button at bottom
                Button(action: {
                    onConfirm()
                }) {
                    HStack {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                        Text("Add to My Habits")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(hex: suggestionColorHex))
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(20)
        }
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .scale(scale: 0.95)),
            removal: .opacity.combined(with: .scale(scale: 0.95))
        ))
    }
    
    // MARK: - Computed Properties
    private var suggestionIcon: String {
        switch suggestion {
        case .habit(let habit):
            switch habit.category.lowercased() {
            case "health": return "heart.fill"
            case "fitness": return "figure.run"
            case "productivity": return "briefcase.fill"
            case "mindfulness": return "leaf.fill"
            case "learning": return "book.fill"
            default: return "star.fill"
            }
        case .task: return "checkmark.circle.fill"
        case .goal: return "target"
        }
    }
    
    private var suggestionTypeName: String {
        switch suggestion {
        case .habit: return "Habit"
        case .task: return "Task"
        case .goal: return "Goal"
        }
    }
    
    private var suggestionBenefits: [String]? {
        switch suggestion {
        case .habit(let habit): return habit.benefits
        case .task(let task): return task.benefits
        case .goal(let goal): return goal.benefits
        }
    }
    
    // MARK: - Additional Computed Properties for UniversalSuggestionView
    private var suggestionColorHex: String {
        switch suggestion {
        case .habit(let habit): return habit.colorHex
        case .task(let task): return task.colorHex
        case .goal(let goal): return goal.colorHex
        }
    }
    
    private var suggestionName: String {
        switch suggestion {
        case .habit(let habit): return habit.name
        case .task(let task): return task.title
        case .goal(let goal): return goal.title
        }
    }
    
    private var suggestionReasoning: String {
        switch suggestion {
        case .habit(let habit): return habit.reasoning
        case .task(let task): return task.reasoning
        case .goal(let goal): return goal.reasoning
        }
    }
}