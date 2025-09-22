import SwiftUI

struct AddGoalView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var goalStore: GoalStore
    @ObservedObject var habitStore: HabitStore
    var onGoalCreated: ((Goal) -> Void)?
    @State private var showingUpgrade = false
    
    @State private var title = ""
    @State private var description = ""
    @State private var selectedCategory: Goal.GoalCategory = .other
    @State private var selectedPriority: Goal.GoalPriority = .medium
    @State private var selectedGoalType: Goal.GoalType = .simple
    @State private var targetValue = 1
    @State private var hasDeadline = false
    @State private var deadline: Date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var showingDatePicker = false
    @State private var animateForm = false
    @State private var formValidation = FormValidation()
    
    struct FormValidation {
        var titleValid = true
        var targetValueValid = true
        var deadlineValid = true
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
                        
                        // Enhanced Create Button
                        enhancedCreateButtonSection
                    }
                    .padding(.bottom, 80) // Add extra bottom padding to ensure content can scroll past navigation bar
                }
            }
            .navigationTitle("New Goal")
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
            .sheet(isPresented: $showingUpgrade) {
                UpgradeView(purchaseManager: PurchaseService.shared, habitStore: habitStore)
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
                
                Image(systemName: "target")
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
                Text("Create Your Goal")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primaryText)
                
                Text("Set a clear, achievable goal to stay motivated and track your progress")
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
    
    // MARK: - Enhanced Create Button Section
    private var enhancedCreateButtonSection: some View {
        VStack(spacing: 16) {
            // Enhanced create button
            Button(action: createGoal) {
                HStack(spacing: 12) {
                    if isFormValid {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    
                    Text(isFormValid ? "Create Goal" : "Complete Form")
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
    
    private func createGoal() {
        guard isFormValid else { return }
        let newGoal = Goal(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
            category: selectedCategory,
            priority: selectedPriority,
            goalType: selectedGoalType,
            targetValue: targetValue,
            deadline: hasDeadline ? deadline : nil
        )
        Task {
            await goalStore.addGoal(newGoal)
            HapticFeedback.shared.habitCompleted()
            onGoalCreated?(newGoal)
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

// MARK: - Enhanced UI Components
struct EnhancedNumberField: View {
    @Binding var value: Int
    let placeholder: String
    let icon: String
    let isValid: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(isValid ? .infoBlue : .warningOrange)
                .frame(width: 24)
            
            TextField(placeholder, value: $value, format: .number)
                .font(.body)
                .foregroundColor(.primaryText)
                .keyboardType(.numberPad)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isValid ? Color.infoBlue.opacity(0.3) : Color.warningOrange.opacity(0.3),
                            lineWidth: 1.5
                        )
                )
        )
    }
}

struct EnhancedCategoryCard: View {
    let category: Goal.GoalCategory
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            isSelected ?
                            LinearGradient(
                                colors: [
                                    Color(hex: category.color),
                                    Color(hex: category.color).opacity(0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [
                                    Color(hex: category.color).opacity(0.15),
                                    Color(hex: category.color).opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                        .overlay(
                            Circle()
                                .stroke(
                                    isSelected ? Color(hex: category.color) : Color(hex: category.color).opacity(0.3),
                                    lineWidth: isSelected ? 2.5 : 1.5
                                )
                        )
                    
                    Image(systemName: category.icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(isSelected ? .white : Color(hex: category.color))
                }
                
                Text(category.rawValue)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? Color(hex: category.color) : .primaryText)
            }
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? Color(hex: category.color).opacity(0.4) : Color.clear,
                                lineWidth: 2
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EnhancedGoalTypeCard: View {
    let goalType: Goal.GoalType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            isSelected ?
                            LinearGradient(
                                colors: [Color.infoBlue, Color.infoBlue.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [Color.infoBlue.opacity(0.15), Color.infoBlue.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle()
                                .stroke(
                                    isSelected ? Color.infoBlue : Color.infoBlue.opacity(0.3),
                                    lineWidth: isSelected ? 2.5 : 1.5
                                )
                        )
                    
                    Image(systemName: goalTypeIcon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(isSelected ? .white : .infoBlue)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(goalType.displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? .infoBlue : .primaryText)
                    
                    Text(goalTypeDescription)
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.successGreen)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? Color.infoBlue.opacity(0.4) : Color.clear,
                                lineWidth: 2
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var goalTypeIcon: String {
        switch goalType {
        case .simple:
            return "checkmark.circle.fill"
        case .measurable:
            return "chart.bar.fill"
        case .habit:
            return "repeat.circle.fill"
        }
    }
    
    private var goalTypeDescription: String {
        switch goalType {
        case .simple:
            return "A simple goal to complete"
        case .measurable:
            return "Track progress towards a target"
        case .habit:
            return "Build a recurring habit"
        }
    }
}

struct EnhancedPriorityCard: View {
    let priority: Goal.GoalPriority
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            isSelected ?
                            LinearGradient(
                                colors: [
                                    Color(hex: priority.color),
                                    Color(hex: priority.color).opacity(0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [
                                    Color(hex: priority.color).opacity(0.15),
                                    Color(hex: priority.color).opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle()
                                .stroke(
                                    isSelected ? Color(hex: priority.color) : Color(hex: priority.color).opacity(0.3),
                                    lineWidth: isSelected ? 2.5 : 1.5
                                )
                        )
                    
                    Image(systemName: priorityIcon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(isSelected ? .white : Color(hex: priority.color))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(priority.rawValue)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? Color(hex: priority.color) : .primaryText)
                    
                    Text(priorityDescription)
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.successGreen)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? Color(hex: priority.color).opacity(0.4) : Color.clear,
                                lineWidth: 2
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var priorityIcon: String {
        switch priority {
        case .low:
            return "arrow.down.circle.fill"
        case .medium:
            return "minus.circle.fill"
        case .high:
            return "arrow.up.circle.fill"
        }
    }
    
    private var priorityDescription: String {
        switch priority {
        case .low:
            return "Low priority goal"
        case .medium:
            return "Medium priority goal"
        case .high:
            return "High priority goal"
        }
    }
}

struct EnhancedToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Spacer()
            RoundedRectangle(cornerRadius: 16)
                .fill(configuration.isOn ? Color.infoBlue : Color.secondaryText.opacity(0.3))
                .frame(width: 50, height: 30)
                .overlay(
                    Circle()
                        .fill(.white)
                        .frame(width: 26, height: 26)
                        .offset(x: configuration.isOn ? 10 : -10)
                        .animation(.easeInOut(duration: 0.2), value: configuration.isOn)
                )
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        configuration.isOn.toggle()
                    }
                }
        }
    }
}

#Preview {
    AddGoalView(goalStore: GoalStore(), habitStore: HabitStore())
} 