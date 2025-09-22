import SwiftUI

struct ChallengeCardView: View {
    let challenge: Challenge
    let isParticipating: Bool
    let onTap: () -> Void
    let onJoin: () -> Void
    let onLeave: () -> Void
    
    @State private var showingLeaveAlert = false
    @State private var isPressed = false
    @State private var cardScale: CGFloat = 1.0
    @State private var progressAnimation: Double = 0
    
    var userParticipant: LegacyChallengeParticipant? {
        guard let currentUserId = AuthManager.shared.currentUser?.id else { return nil }
        return challenge.participants.first { $0.userId == currentUserId }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Header with enhanced category and status
                headerSection
                
                // Main content with improved hierarchy
                mainContentSection
                
                // Enhanced progress section
                if isParticipating, let participant = userParticipant {
                    progressSection(participant)
                }
                
                // Footer with enhanced actions
                footerSection
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(
                        color: isPressed ? 
                            Color(hex: challenge.category.color).opacity(0.3) : 
                            Color.black.opacity(0.08),
                        radius: isPressed ? 12 : 8,
                        x: 0,
                        y: isPressed ? 6 : 4
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: isParticipating ? [
                                Color(hex: challenge.category.color).opacity(0.4),
                                Color(hex: challenge.category.color).opacity(0.2)
                            ] : [Color.clear, Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isParticipating ? 2 : 0
                    )
            )
            .scaleEffect(cardScale)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: cardScale)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .onLongPressGesture(minimumDuration: 0) { isPressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = isPressing
                cardScale = isPressing ? 1.02 : 1.0
            }
        } perform: {
            onTap()
        }
        .alert("Leave Challenge", isPresented: $showingLeaveAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Leave", role: .destructive) {
                onLeave()
            }
        } message: {
            Text("Are you sure you want to leave \"\(challenge.title)\"? Your progress will be lost.")
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.1)) {
                progressAnimation = 1.0
            }
        }
    }
    
    // MARK: - Enhanced Header Section
    private var headerSection: some View {
        HStack {
            // Enhanced category badge with gradient
            HStack(spacing: 6) {
                Image(systemName: challenge.category.icon)
                    .font(.system(size: 13, weight: .semibold))
                    .imageScale(.medium)
                Text(challenge.category.rawValue.capitalized)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                LinearGradient(
                    colors: [
                        Color(hex: challenge.category.color),
                        Color(hex: challenge.category.color).opacity(0.8)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(12)
            .shadow(color: Color(hex: challenge.category.color).opacity(0.3), radius: 4, x: 0, y: 2)
            
            Spacer()
            
            // Enhanced status badges with better animations
            HStack(spacing: 8) {
                if isParticipating {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12, weight: .bold))
                            .symbolRenderingMode(.hierarchical)
                        Text("Joined")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        LinearGradient(
                            colors: [.green, .green.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(8)
                    .scaleEffect(progressAnimation * 1.0)
                }
                
                if challenge.isExpired {
                    statusBadge(
                        icon: "clock.badge.xmark",
                        text: "Ended",
                        colors: [.red, .red.opacity(0.8)]
                    )
                } else if challenge.daysRemaining <= 3 {
                    statusBadge(
                        icon: "exclamationmark.triangle.fill",
                        text: "Ending Soon",
                        colors: [.red, .red.opacity(0.8)]
                    )
                    .scaleEffect(1.0 + sin(Date().timeIntervalSince1970 * 2) * 0.05)
                    .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: UUID())
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    private func statusBadge(icon: String, text: String, colors: [Color]) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .symbolRenderingMode(.hierarchical)
            Text(text)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            LinearGradient(
                colors: colors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(8)
    }
    
    // MARK: - Enhanced Main Content Section
    private var mainContentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title and type with better hierarchy
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(challenge.title)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    HStack(spacing: 6) {
                        Image(systemName: challenge.challengeType.defaultIcon)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(hex: challenge.category.color))
                        Text(challenge.challengeType.rawValue)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Enhanced target value display
                VStack(spacing: 2) {
                    Text("\(challenge.targetValue)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: challenge.category.color))
                        .scaleEffect(progressAnimation * 1.0)
                    
                    Text(challenge.challengeType.unit)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .kerning(0.5)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: challenge.category.color).opacity(0.1))
                )
            }
            
            // Description with fade effect
            if !challenge.description.isEmpty {
                Text(challenge.description)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .opacity(0.9)
            }
            
            // Enhanced stats row with better visual hierarchy
            HStack(spacing: 24) {
                EnhancedChallengeStatItem(
                    icon: "person.2.fill",
                    value: "\(challenge.participants.count)",
                    label: "Participants",
                    color: .blue,
                    animationDelay: 0.1
                )
                
                EnhancedChallengeStatItem(
                    icon: challenge.isExpired ? "checkmark.circle.fill" : "calendar",
                    value: challenge.isExpired ? "Ended" : "\(challenge.daysRemaining)d",
                    label: challenge.isExpired ? "Status" : "Remaining",
                    color: challenge.isExpired ? .red : .green,
                    animationDelay: 0.2
                )
                
                if let leader = challenge.participants.max(by: { $0.currentValue < $1.currentValue }) {
                    EnhancedChallengeStatItem(
                        icon: "trophy.fill",
                        value: "\(leader.currentValue)",
                        label: "Top Score",
                        color: .yellow,
                        animationDelay: 0.3
                    )
                }
                
                Spacer()
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Enhanced Progress Section
    private func progressSection(_ participant: LegacyChallengeParticipant) -> some View {
        VStack(spacing: 12) {
            HStack {
                Text("Your Progress")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(participant.currentValue)/\(participant.targetValue)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: challenge.category.color))
            }
            
            // Enhanced progress bar with gradient and animation
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: challenge.category.color).opacity(0.15))
                        .frame(height: 10)
                    
                    // Progress with gradient and animation
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: challenge.category.color),
                                    Color(hex: challenge.category.color).opacity(0.7),
                                    Color(hex: challenge.category.color)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geometry.size.width * participant.progress * progressAnimation,
                            height: 10
                        )
                        .animation(.easeOut(duration: 1.2).delay(0.3), value: progressAnimation)
                        .overlay(
                            // Shimmer effect
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0),
                                            Color.white.opacity(0.3),
                                            Color.white.opacity(0)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: 30)
                                .offset(x: progressAnimation * (geometry.size.width + 30) - 30)
                                .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: progressAnimation)
                        )
                }
            }
            .frame(height: 10)
            
            HStack {
                Text("\(participant.progressPercentage)% complete")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if participant.isCompleted {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 13))
                            .symbolRenderingMode(.multicolor)
                        Text("Completed!")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.yellow)
                    .scaleEffect(progressAnimation * 1.0)
                }
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(
            LinearGradient(
                colors: [
                    Color(hex: challenge.category.color).opacity(0.08),
                    Color(hex: challenge.category.color).opacity(0.04)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay(
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: challenge.category.color).opacity(0.3),
                            Color(hex: challenge.category.color).opacity(0.1)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1),
            alignment: .top
        )
    }
    
    // MARK: - Enhanced Footer Section
    private var footerSection: some View {
        HStack(spacing: 12) {
            if !isParticipating {
                // Enhanced join button
                Button(action: onJoin) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16, weight: .medium))
                            .symbolRenderingMode(.hierarchical)
                        Text("Join Challenge")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
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
                    .cornerRadius(14)
                    .shadow(
                        color: challenge.isActive && !challenge.isExpired 
                        ? Color(hex: challenge.category.color).opacity(0.4) 
                        : Color.gray.opacity(0.3), 
                        radius: 6, x: 0, y: 3
                    )
                }
                .disabled(!challenge.isActive || challenge.isExpired)
                .scaleEffect(challenge.isActive && !challenge.isExpired ? 1.0 : 0.95)
            } else {
                // Enhanced leave button
                Button(action: {
                    showingLeaveAlert = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "minus.circle")
                            .font(.system(size: 15, weight: .medium))
                        Text("Leave")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                    }
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.red.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.red.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
            }
            
            // Enhanced details button
            Button(action: onTap) {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 15, weight: .medium))
                        .symbolRenderingMode(.hierarchical)
                    Text("Details")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                }
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.blue.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                        )
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
}

// MARK: - Enhanced Challenge Stat Item
private struct EnhancedChallengeStatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    let animationDelay: Double
    
    @State private var isVisible = false
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(color)
                    .symbolRenderingMode(.hierarchical)
                
                Text(value)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(color)
            }
            .scaleEffect(isVisible ? 1.0 : 0.8)
            .opacity(isVisible ? 1.0 : 0.0)
            
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .kerning(0.3)
                .lineLimit(1)
                .opacity(isVisible ? 1.0 : 0.0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(animationDelay)) {
                isVisible = true
            }
        }
    }
} 