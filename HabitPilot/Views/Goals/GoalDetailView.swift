import SwiftUI

struct GoalDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let goal: Goal
    @ObservedObject var goalStore: GoalStore
    
    @State private var showingEditGoal = false
    @State private var showingDeleteConfirmation = false
    @State private var showConfetti = false
    @State private var wasCompleted = false
    @State private var completionScale: CGFloat = 1.0
    @State private var animateProgress = false
    @State private var animateCards = false
    
    var body: some View {
        ZStack {
            Color.secondaryBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Enhanced Goal Header
                    enhancedGoalHeaderCard
                    
                    // Enhanced Goal Details
                    enhancedGoalDetailsCard
                    
                    // Enhanced Progress Section (for measurable goals)
                    if goal.goalType != .simple {
                        enhancedProgressCard
                    }
                    
                    // Enhanced Action Buttons
                    enhancedActionButtonsCard
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
                .padding(.bottom, 40) // Add extra bottom padding to ensure content can scroll past navigation bar
            }
        }
        .navigationTitle("Goal Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Edit Goal") {
                        showingEditGoal = true
                    }
                    
                    Button("Delete Goal", role: .destructive) {
                        showingDeleteConfirmation = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title2)
                        .foregroundColor(.infoBlue)
                }
            }
        }
        .confirmationDialog(
            "Delete Goal",
            isPresented: $showingDeleteConfirmation
        ) {
            Button("Delete '\(goal.title)'", role: .destructive) {
                Task {
                    await goalStore.deleteGoal(goal)
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this goal? This action cannot be undone.")
        }
        .sheet(isPresented: $showingEditGoal) {
            EditGoalView(goal: goal, goalStore: goalStore)
        }
        .confetti(isActive: showConfetti, duration: 2.0)
        .onAppear {
            wasCompleted = goal.isCompleted
            
            // Animate cards on appear
            withAnimation(.easeInOut(duration: 0.6).delay(0.2)) {
                animateCards = true
            }
            
            // Animate progress after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeInOut(duration: 1.0)) {
                    animateProgress = true
                }
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
    
    // MARK: - Enhanced Goal Header Card
    private var enhancedGoalHeaderCard: some View {
        VStack(spacing: 20) {
            // Enhanced category and completion status
            HStack {
                // Enhanced category display
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(hex: goal.category.color).opacity(0.2),
                                        Color(hex: goal.category.color).opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)
                            .overlay(
                                Circle()
                                    .stroke(Color(hex: goal.category.color).opacity(0.3), lineWidth: 1.5)
                            )
                        
                        Image(systemName: goal.category.icon)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(Color(hex: goal.category.color))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(goal.category.rawValue)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(hex: goal.category.color))
                        
                        Text("Category")
                            .font(.caption)
                            .foregroundColor(.secondaryText)
                    }
                }
                
                Spacer()
                
                // Enhanced completion status
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                goal.isCompleted ? 
                                LinearGradient(
                                    colors: [Color.successGreen, Color.successGreen.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ) :
                                LinearGradient(
                                    colors: [Color.secondaryText.opacity(0.2), Color.secondaryText.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)
                            .overlay(
                                Circle()
                                    .stroke(
                                        goal.isCompleted ? Color.successGreen.opacity(0.4) : Color.secondaryText.opacity(0.3),
                                        lineWidth: 1.5
                                    )
                            )
                        
                        Image(systemName: goal.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(goal.isCompleted ? .white : .secondaryText)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(goal.isCompleted ? "Completed" : "Active")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(goal.isCompleted ? .successGreen : .secondaryText)
                        
                        Text("Status")
                            .font(.caption)
                            .foregroundColor(.secondaryText)
                    }
                }
            }
            
            // Enhanced goal title and description
            VStack(alignment: .leading, spacing: 16) {
                Text(goal.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primaryText)
                    .multilineTextAlignment(.leading)
                
                if !goal.description.isEmpty {
                    Text(goal.description)
                        .font(.body)
                        .foregroundColor(.secondaryText)
                        .multilineTextAlignment(.leading)
                        .lineLimit(nil)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.cardGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            goal.isCompleted ? Color.successGreen.opacity(0.3) : Color.clear,
                            lineWidth: 2
                        )
                )
                .shadow(
                    color: Color.cardShadow,
                    radius: 16,
                    x: 0,
                    y: 8
                )
        )
        .offset(x: animateCards ? 0 : -50)
        .opacity(animateCards ? 1 : 0)
        .animation(.easeOut(duration: 0.6), value: animateCards)
    }
    
    // MARK: - Enhanced Goal Details Card
    private var enhancedGoalDetailsCard: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Goal Details")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primaryText)
                
                Spacer()
            }
            
            VStack(spacing: 16) {
                // Enhanced priority row
                EnhancedGoalDetailRow(
                    icon: "flag.fill",
                    title: "Priority",
                    value: goal.priority.rawValue,
                    valueColor: Color(hex: goal.priority.color),
                    backgroundColor: Color(hex: goal.priority.color).opacity(0.1)
                )
                
                // Enhanced created date row
                EnhancedGoalDetailRow(
                    icon: "calendar",
                    title: "Created",
                    value: formatDate(goal.createdAt),
                    valueColor: .secondaryText,
                    backgroundColor: Color.infoBlue.opacity(0.1)
                )
                
                // Enhanced completed date row (if completed)
                if let completedDate = goal.completedDate {
                    EnhancedGoalDetailRow(
                        icon: "checkmark.circle.fill",
                        title: "Completed",
                        value: formatDate(completedDate),
                        valueColor: .successGreen,
                        backgroundColor: Color.successGreen.opacity(0.1)
                    )
                }
                
                // Enhanced deadline row (if has deadline)
                if let deadline = goal.deadline {
                    EnhancedGoalDetailRow(
                        icon: "clock.fill",
                        title: "Deadline",
                        value: formatDate(deadline),
                        valueColor: .warningOrange,
                        backgroundColor: Color.warningOrange.opacity(0.1)
                    )
                }
                
                // Enhanced goal type row
                EnhancedGoalDetailRow(
                    icon: goalTypeIcon,
                    title: "Goal Type",
                    value: goal.goalType.displayName,
                    valueColor: Color(hex: goal.category.color),
                    backgroundColor: Color(hex: goal.category.color).opacity(0.1)
                )
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.cardGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.2),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: Color.cardShadow,
                    radius: 16,
                    x: 0,
                    y: 8
                )
        )
        .offset(x: animateCards ? 0 : 50)
        .opacity(animateCards ? 1 : 0)
        .animation(.easeOut(duration: 0.6).delay(0.1), value: animateCards)
    }
    
    // MARK: - Enhanced Progress Card
    private var enhancedProgressCard: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Progress")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primaryText)
                
                Spacer()
                
                // Progress percentage
                Text("\(Int(goal.progressPercentage * 100))%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: goal.category.color))
            }
            
            // Enhanced progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: goal.category.color).opacity(0.15))
                        .frame(height: 12)
                    
                    RoundedRectangle(cornerRadius: 8)
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
                        .frame(width: geometry.size.width * (animateProgress ? goal.progressPercentage : 0), height: 12)
                        .animation(.easeInOut(duration: 1.2), value: animateProgress)
                }
            }
            .frame(height: 12)
            
            // Enhanced progress stats
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Progress")
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                    
                    Text("\(goal.currentProgress)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primaryText)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Target")
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                    
                    Text("\(goal.targetValue)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primaryText)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(hex: goal.category.color).opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.cardGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(hex: goal.category.color).opacity(0.3),
                                    Color(hex: goal.category.color).opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: Color.cardShadow,
                    radius: 16,
                    x: 0,
                    y: 8
                )
        )
        .offset(x: animateCards ? 0 : -50)
        .opacity(animateCards ? 1 : 0)
        .animation(.easeOut(duration: 0.6).delay(0.2), value: animateCards)
    }
    
    // MARK: - Enhanced Action Buttons Card
    private var enhancedActionButtonsCard: some View {
        VStack(spacing: 16) {
            // Enhanced completion toggle button
            Button(action: {
                withAnimation(AnimationHelper.Curve.bounce) {
                    completionScale = 1.3
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(AnimationHelper.Curve.smooth) {
                        completionScale = 1.0
                    }
                }
                
                goalStore.toggleGoalCompletion(goal)
                HapticFeedback.shared.habitCompleted()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: goal.isCompleted ? "checkmark.circle.fill" : "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                    
                    Text(goal.isCompleted ? "Mark as Active" : "Mark as Complete")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: goal.isCompleted ? 
                        [Color.secondaryText, Color.secondaryText.opacity(0.8)] :
                        [Color.successGreen, Color.successGreen.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(
                    color: goal.isCompleted ? 
                    Color.secondaryText.opacity(0.3) : 
                    Color.successGreen.opacity(0.3),
                    radius: 8,
                    x: 0,
                    y: 4
                )
            }
            .scaleEffect(completionScale)
            
            // Enhanced increment button (for measurable goals)
            if (goal.goalType == .measurable || goal.goalType == .habit) && !goal.isCompleted {
                Button(action: {
                    goalStore.incrementGoalProgress(goal)
                    HapticFeedback.shared.buttonPress()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(Color(hex: goal.category.color))
                        
                        Text("Increment Progress")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(hex: goal.category.color))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color(hex: goal.category.color).opacity(0.3), lineWidth: 1)
                            )
                    )
                    .shadow(color: Color.cardShadow, radius: 6, x: 0, y: 3)
                }
            }
        }
        .offset(x: animateCards ? 0 : 50)
        .opacity(animateCards ? 1 : 0)
        .animation(.easeOut(duration: 0.6).delay(0.3), value: animateCards)
    }
    
    // MARK: - Helper Methods
    private var goalTypeIcon: String {
        switch goal.goalType {
        case .simple:
            return "checkmark.circle.fill"
        case .measurable:
            return "chart.bar.fill"
        case .habit:
            return "repeat.circle.fill"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Enhanced Goal Detail Row
struct EnhancedGoalDetailRow: View {
    let icon: String
    let title: String
    let value: String
    let valueColor: Color
    let backgroundColor: Color
    
    var body: some View {
        HStack(spacing: 16) {
            // Enhanced icon
            ZStack {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle()
                            .stroke(valueColor.opacity(0.3), lineWidth: 1.5)
                    )
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(valueColor)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondaryText)
                
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(valueColor)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(valueColor.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

#Preview {
    NavigationView {
        GoalDetailView(
            goal: Goal(
                title: "Learn SwiftUI",
                description: "Master SwiftUI framework for iOS development",
                category: .learning,
                priority: .high,
                goalType: .measurable,
                targetValue: 10
            ),
            goalStore: GoalStore()
        )
    }
}

 