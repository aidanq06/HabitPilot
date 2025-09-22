import SwiftUI

struct EditGoalView: View {
    @Environment(\.dismiss) private var dismiss
    let goal: Goal
    @ObservedObject var goalStore: GoalStore
    
    @State private var title: String
    @State private var description: String
    @State private var selectedCategory: Goal.GoalCategory
    @State private var selectedPriority: Goal.GoalPriority
    @State private var selectedGoalType: Goal.GoalType
    @State private var targetValue: Int
    @State private var hasDeadline: Bool
    @State private var deadline: Date
    @State private var showingDatePicker = false
    @State private var animateForm = false
    @State private var formValidation = FormValidation()
    
    struct FormValidation {
        var titleValid = true
        var targetValueValid = true
        var deadlineValid = true
    }
    
    init(goal: Goal, goalStore: GoalStore) {
        self.goal = goal
        self.goalStore = goalStore
        
        // Initialize state with current goal values
        _title = State(initialValue: goal.title)
        _description = State(initialValue: goal.description)
        _selectedCategory = State(initialValue: goal.category)
        _selectedPriority = State(initialValue: goal.priority)
        _selectedGoalType = State(initialValue: goal.goalType)
        _targetValue = State(initialValue: goal.targetValue)
        _hasDeadline = State(initialValue: goal.deadline != nil)
        _deadline = State(initialValue: goal.deadline ?? Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date())
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.secondaryBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Enhanced Header Section
                        enhancedHeaderSection
                        
                        // Enhanced Basic Information
                        enhancedBasicInfoSection
                        
                        // Enhanced Category Selection
                        enhancedCategorySection
                        
                        // Enhanced Goal Type Selection
                        enhancedGoalTypeSection
                        
                        // Enhanced Priority Selection
                        enhancedPrioritySection
                        
                        // Enhanced Deadline Selection
                        enhancedDeadlineSection
                        
                        // Enhanced Save Button
                        enhancedSaveButtonSection
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Edit Goal")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.infoBlue)
                    .fontWeight(.medium)
                }
            }
            .sheet(isPresented: $showingDatePicker) {
                enhancedDatePickerSheet
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 0.6).delay(0.2)) {
                    animateForm = true
                }
            }
        }
    }
    
    // MARK: - Enhanced Header Section
    private var enhancedHeaderSection: some View {
        VStack(spacing: 20) {
            ZStack {
                // Enhanced background circle
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.infoBlue.opacity(0.2),
                                Color.infoBlue.opacity(0.1),
                                Color.infoBlue.opacity(0.05)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 80
                        )
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(animateForm ? 1.1 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 3.0)
                            .repeatForever(autoreverses: true),
                        value: animateForm
                    )
                
                Image(systemName: "pencil.circle")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.infoBlue, Color.infoBlue.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(animateForm ? 1.05 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 2.0)
                            .repeatForever(autoreverses: true),
                        value: animateForm
                    )
            }
            
            VStack(spacing: 12) {
                Text("Edit Your Goal")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primaryText)
                
                Text("Update your goal details and track your progress")
                    .font(.subheadline)
                    .foregroundColor(.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        .padding(.top, 20)
        .offset(x: animateForm ? 0 : -50)
        .opacity(animateForm ? 1 : 0)
        .animation(.easeOut(duration: 0.6), value: animateForm)
    }
    
    // MARK: - Enhanced Basic Information Section
    private var enhancedBasicInfoSection: some View {
        VStack(spacing: 24) {
            enhancedSectionHeader("Basic Information", icon: "pencil.circle.fill")
            
            VStack(spacing: 20) {
                // Enhanced Title Input
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Goal Title")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primaryText)
                        
                        Spacer()
                        
                        if !formValidation.titleValid {
                            Text("Required")
                                .font(.caption)
                                .foregroundColor(.warningOrange)
                        }
                    }
                    
                    EnhancedTextField(
                        text: $title,
                        placeholder: "What do you want to achieve?",
                        icon: "target",
                        isValid: formValidation.titleValid
                    )
                    .onChange(of: title) { _, newValue in
                        formValidation.titleValid = !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    }
                }
                
                // Enhanced Description Input
                VStack(alignment: .leading, spacing: 12) {
                    Text("Description (Optional)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primaryText)
                    
                    EnhancedTextArea(
                        text: $description,
                        placeholder: "Add more details about your goal",
                        icon: "text.alignleft"
                    )
                }
            }
        }
        .padding(.horizontal, 20)
        .offset(x: animateForm ? 0 : 50)
        .opacity(animateForm ? 1 : 0)
        .animation(.easeOut(duration: 0.6).delay(0.1), value: animateForm)
    }
    
    // MARK: - Enhanced Category Section
    private var enhancedCategorySection: some View {
        VStack(spacing: 24) {
            enhancedSectionHeader("Category", icon: "folder.circle.fill")
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                ForEach(Goal.GoalCategory.allCases, id: \.self) { category in
                    EnhancedCategoryCard(
                        category: category,
                        isSelected: selectedCategory == category,
                        onTap: {
                            selectedCategory = category
                            HapticFeedback.shared.buttonPress()
                        }
                    )
                }
            }
        }
        .padding(.horizontal, 20)
        .offset(x: animateForm ? 0 : -50)
        .opacity(animateForm ? 1 : 0)
        .animation(.easeOut(duration: 0.6).delay(0.2), value: animateForm)
    }
    
    // MARK: - Enhanced Goal Type Section
    private var enhancedGoalTypeSection: some View {
        VStack(spacing: 24) {
            enhancedSectionHeader("Goal Type", icon: "chart.line.uptrend.xyaxis.circle.fill")
            
            VStack(spacing: 16) {
                ForEach(Goal.GoalType.allCases, id: \.self) { goalType in
                    EnhancedGoalTypeCard(
                        goalType: goalType,
                        isSelected: selectedGoalType == goalType,
                        onTap: {
                            selectedGoalType = goalType
                            HapticFeedback.shared.buttonPress()
                        }
                    )
                }
                
                // Enhanced target value input for measurable and habit goals
                if selectedGoalType != .simple {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Target Value")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primaryText)
                            
                            Spacer()
                            
                            if !formValidation.targetValueValid {
                                Text("Invalid")
                                    .font(.caption)
                                    .foregroundColor(.warningOrange)
                            }
                        }
                        
                        HStack(spacing: 16) {
                            EnhancedNumberField(
                                value: $targetValue,
                                placeholder: "1",
                                icon: "number.circle.fill",
                                isValid: formValidation.targetValueValid
                            )
                            .onChange(of: targetValue) { _, newValue in
                                formValidation.targetValueValid = newValue > 0
                            }
                            
                            Text(selectedGoalType == .measurable ? "times" : "times")
                                .font(.subheadline)
                                .foregroundColor(.secondaryText)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.infoBlue.opacity(0.2), lineWidth: 1)
                                        )
                                )
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .offset(x: animateForm ? 0 : 50)
        .opacity(animateForm ? 1 : 0)
        .animation(.easeOut(duration: 0.6).delay(0.3), value: animateForm)
    }
    
    // MARK: - Enhanced Priority Section
    private var enhancedPrioritySection: some View {
        VStack(spacing: 24) {
            enhancedSectionHeader("Priority", icon: "flag.circle.fill")
            
            VStack(spacing: 16) {
                ForEach(Goal.GoalPriority.allCases, id: \.self) { priority in
                    EnhancedPriorityCard(
                        priority: priority,
                        isSelected: selectedPriority == priority,
                        onTap: {
                            selectedPriority = priority
                            HapticFeedback.shared.buttonPress()
                        }
                    )
                }
            }
        }
        .padding(.horizontal, 20)
        .offset(x: animateForm ? 0 : -50)
        .opacity(animateForm ? 1 : 0)
        .animation(.easeOut(duration: 0.6).delay(0.4), value: animateForm)
    }
    
    // MARK: - Enhanced Deadline Section
    private var enhancedDeadlineSection: some View {
        VStack(spacing: 24) {
            enhancedSectionHeader("Deadline", icon: "calendar.circle.fill")
            
            VStack(spacing: 16) {
                // Enhanced deadline toggle
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Set Deadline")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primaryText)
                        
                        Text("Add a target completion date")
                            .font(.caption)
                            .foregroundColor(.secondaryText)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $hasDeadline)
                        .toggleStyle(EnhancedToggleStyle())
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.infoBlue.opacity(0.2), lineWidth: 1)
                        )
                )
                
                // Enhanced date picker button
                if hasDeadline {
                    Button(action: {
                        showingDatePicker = true
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "calendar")
                                .font(.title3)
                                .foregroundColor(.infoBlue)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Deadline")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primaryText)
                                
                                Text(formatDate(deadline))
                                    .font(.caption)
                                    .foregroundColor(.secondaryText)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondaryText)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.infoBlue.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(.horizontal, 20)
        .offset(x: animateForm ? 0 : 50)
        .opacity(animateForm ? 1 : 0)
        .animation(.easeOut(duration: 0.6).delay(0.5), value: animateForm)
    }
    
    // MARK: - Enhanced Save Button Section
    private var enhancedSaveButtonSection: some View {
        VStack(spacing: 16) {
            // Enhanced save button
            Button(action: saveGoal) {
                HStack(spacing: 12) {
                    if isFormValid {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "pencil.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    
                    Text(isFormValid ? "Save Changes" : "Complete Form")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(
                        colors: isFormValid ? 
                        [Color.successGreen, Color.successGreen.opacity(0.8)] :
                        [Color.secondaryText, Color.secondaryText.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .shadow(
                    color: isFormValid ? 
                    Color.successGreen.opacity(0.3) : 
                    Color.secondaryText.opacity(0.3),
                    radius: 8,
                    x: 0,
                    y: 4
                )
            }
            .disabled(!isFormValid)
            
            // Enhanced form validation message
            if !isFormValid {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .font(.caption)
                        .foregroundColor(.warningOrange)
                    
                    Text("Please complete all required fields")
                        .font(.caption)
                        .foregroundColor(.warningOrange)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.warningOrange.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.warningOrange.opacity(0.3), lineWidth: 1)
                        )
                )
            }
        }
        .padding(.horizontal, 20)
        .offset(x: animateForm ? 0 : -50)
        .opacity(animateForm ? 1 : 0)
        .animation(.easeOut(duration: 0.6).delay(0.6), value: animateForm)
    }
    
    // MARK: - Enhanced Date Picker Sheet
    private var enhancedDatePickerSheet: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Select Deadline")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primaryText)
                    .padding(.top, 20)
                
                DatePicker(
                    "Deadline",
                    selection: $deadline,
                    in: Date()...,
                    displayedComponents: [.date]
                )
                .datePickerStyle(WheelDatePickerStyle())
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Enhanced done button
                Button("Done") {
                    showingDatePicker = false
                }
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color.infoBlue, Color.infoBlue.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .background(Color.secondaryBackground)
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - Helper Methods
    private var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        (selectedGoalType == .simple || targetValue > 0)
    }
    
    private func saveGoal() {
        guard isFormValid else { return }
        var updatedGoal = goal
        updatedGoal.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedGoal.description = description.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedGoal.category = selectedCategory
        updatedGoal.priority = selectedPriority
        updatedGoal.goalType = selectedGoalType
        updatedGoal.targetValue = targetValue
        updatedGoal.deadline = hasDeadline ? deadline : nil
        Task {
            await goalStore.updateGoal(updatedGoal)
            HapticFeedback.shared.habitCompleted()
            dismiss()
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func enhancedSectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.infoBlue)
            
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primaryText)
            
            Spacer()
        }
    }
}

#Preview {
    EditGoalView(
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