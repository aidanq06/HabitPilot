import SwiftUI

struct ChallengeCreationView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var habitStore: HabitStore
    
    @StateObject private var challengeManager = ChallengeManager.shared
    @State private var currentStep: CreationStep = .details
    @State private var hapticFeedback = UIImpactFeedbackGenerator(style: .medium)
    @State private var progressAnimation: Double = 0
    @State private var stepTransition: AnyTransition = .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading))
    
    // Form data with validation
    @State private var selectedType: ChallengeType = .habit
    @State private var selectedCategory: ChallengeCategory = .fitness
    @State private var title = ""
    @State private var description = ""
    @State private var targetValue = 30
    @State private var duration = 30
    @State private var startDate = Date()
    @State private var isPrivate = false
    
    // Validation states
    @State private var titleError: String?
    @State private var isValidating = false
    
    // Linked habit data
    @State private var linkedHabitId: String?
    @State private var habitName = ""
    @State private var habitDescription = ""
    @State private var habitColor = "#DC143C"
    @State private var habitIcon = "star.fill"
    
    @State private var showingItemCreation = false
    @State private var isCreating = false
    
    enum CreationStep: String, CaseIterable {
        case details = "Details"
        case settings = "Settings"
        case review = "Review"
        
        var icon: String {
            switch self {
            case .details: return "pencil.and.outline"
            case .settings: return "gearshape.2"
            case .review: return "checkmark.seal"
            }
        }
        
        var stepNumber: Int {
            switch self {
            case .details: return 1
            case .settings: return 2
            case .review: return 3
            }
        }
        
        var description: String {
            switch self {
            case .details: return "Add a compelling title and description for your habit challenge"
            case .settings: return "Configure duration and privacy settings"
            case .review: return "Review and create your habit challenge"
            }
        }
    }
    
    var canProceed: Bool {
        switch currentStep {
        case .details:
            return !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && 
                   title.count >= 3 && targetValue > 0 && titleError == nil
        case .settings:
            return duration > 0 && Calendar.current.isDate(startDate, inSameDayAs: Date()) || startDate > Date()
        case .review:
            return true
        }
    }
    
    var endDate: Date {
        Calendar.current.date(byAdding: .day, value: duration, to: startDate) ?? Date()
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Enhanced background with animated gradient
                LinearGradient(
                    colors: [
                        Color(hex: selectedCategory.color).opacity(0.08),
                        Color(hex: selectedCategory.color).opacity(0.03),
                        Color(.systemBackground)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.8), value: selectedCategory.color)
                
                VStack(spacing: 0) {
                    // Enhanced progress indicator
                    progressIndicator
                    
                    // Content with improved transitions
                    ScrollView {
                        VStack(spacing: 28) {
                            // Enhanced step header
                            stepHeader
                            
                            // Step content with transition
                            stepContent
                                .transition(stepTransition)
                                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: currentStep)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 140)
                    }
                    
                    // Enhanced navigation buttons
                    navigationButtons
                }
            }
            .navigationTitle("Create Challenge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
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
                            Text("Cancel")
                                .font(.system(size: 15, weight: .medium))
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .sheet(isPresented: $showingItemCreation) {
                // Item creation sheets based on challenge type
            }
        }
        .onAppear {
            initializeProgressAnimation()
        }
    }
    
    // MARK: - Animation Initialization
    private func initializeProgressAnimation() {
        withAnimation(.easeOut(duration: 1.2).delay(0.3)) {
            progressAnimation = Double(currentStep.stepNumber) / Double(CreationStep.allCases.count)
        }
    }
    
    // MARK: - Enhanced Progress Indicator
    private var progressIndicator: some View {
        VStack(spacing: 16) {
            // Progress bar
            HStack {
                ForEach(CreationStep.allCases, id: \.self) { step in
                    HStack(spacing: 8) {
                        // Enhanced step circle
                        ZStack {
                            Circle()
                                .fill(
                                    currentStep.stepNumber >= step.stepNumber
                                    ? LinearGradient(
                                        colors: [Color(hex: selectedCategory.color), Color(hex: selectedCategory.color).opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                    : LinearGradient(colors: [Color(.systemGray5)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                                .frame(width: 36, height: 36)
                                .shadow(
                                    color: currentStep.stepNumber >= step.stepNumber 
                                    ? Color(hex: selectedCategory.color).opacity(0.3) 
                                    : .clear, 
                                    radius: 6, x: 0, y: 3
                                )
                            
                            if currentStep.stepNumber > step.stepNumber {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                                    .symbolRenderingMode(.hierarchical)
                            } else {
                                Image(systemName: step.icon)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(
                                        currentStep.stepNumber >= step.stepNumber
                                        ? .white
                                        : .secondary
                                    )
                                    .symbolRenderingMode(.hierarchical)
                            }
                        }
                        .scaleEffect(currentStep == step ? 1.1 : 1.0)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentStep)
                        
                        // Connection line
                        if step != CreationStep.allCases.last {
                            Rectangle()
                                .fill(
                                    currentStep.stepNumber > step.stepNumber
                                    ? LinearGradient(
                                        colors: [Color(hex: selectedCategory.color), Color(hex: selectedCategory.color).opacity(0.6)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                    : LinearGradient(colors: [Color(.systemGray5)], startPoint: .leading, endPoint: .trailing)
                                )
                                .frame(height: 3)
                                .frame(maxWidth: .infinity)
                                .cornerRadius(1.5)
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            
            // Step info
            VStack(spacing: 6) {
                Text(currentStep.rawValue)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("Step \(currentStep.stepNumber) of \(CreationStep.allCases.count)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .kerning(0.5)
            }
        }
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .padding(.horizontal, 20)
    }
    
    // MARK: - Enhanced Step Header
    private var stepHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                // Animated background circles
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .stroke(
                            Color(hex: selectedCategory.color).opacity(0.1 - Double(index) * 0.03),
                            lineWidth: 2
                        )
                        .frame(width: 80 + CGFloat(index * 15), height: 80 + CGFloat(index * 15))
                        .scaleEffect(1.0 + sin(Date().timeIntervalSince1970 + Double(index)) * 0.05)
                        .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: UUID())
                }
                
                Image(systemName: currentStep.icon)
                    .font(.system(size: 32, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundColor(Color(hex: selectedCategory.color))
                    .scaleEffect(1.0 + sin(Date().timeIntervalSince1970 * 1.5) * 0.05)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: UUID())
            }
            
            Text(currentStep.description)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .padding(.horizontal, 20)
        }
        .padding(.top, 24)
    }
    
    // MARK: - Enhanced Step Content
    private var stepContent: some View {
        SwiftUI.Group {
            switch currentStep {
            case .details:
                detailsContent
            case .settings:
                settingsContent
            case .review:
                reviewContent
            }
        }
    }
    

    
    // MARK: - Enhanced Details Content
    private var detailsContent: some View {
        VStack(spacing: 28) {
            // Enhanced category selection
            VStack(alignment: .leading, spacing: 16) {
                Text("Category")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(ChallengeCategory.allCases, id: \.self) { category in
                            EnhancedCategoryChip(
                                category: category,
                                isSelected: selectedCategory == category
                            ) {
                                hapticFeedback.impactOccurred()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    selectedCategory = category
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            
            // Enhanced title input
            VStack(alignment: .leading, spacing: 12) {
                Text("Challenge Title")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Enter an inspiring title...", text: $title)
                        .font(.system(size: 16, weight: .regular))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemGray6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(
                                            titleError != nil ? Color.red.opacity(0.5) :
                                            !title.isEmpty ? Color(hex: selectedCategory.color).opacity(0.5) : 
                                            Color.clear,
                                            lineWidth: 2
                                        )
                                )
                        )
                        .onChange(of: title) { newValue in
                            validateTitle(newValue)
                        }
                    
                    if let error = titleError {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 12))
                                .symbolRenderingMode(.hierarchical)
                            Text(error)
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(.red)
                        .transition(.scale.combined(with: .opacity))
                    } else if !title.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                                .symbolRenderingMode(.hierarchical)
                            Text("Looks great!")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(.green)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            
            // Enhanced description
            VStack(alignment: .leading, spacing: 12) {
                Text("Description (Optional)")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                TextField("Describe your challenge...", text: $description, axis: .vertical)
                    .font(.system(size: 16, weight: .regular))
                    .lineLimit(3...6)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemGray6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        !description.isEmpty ? Color(hex: selectedCategory.color).opacity(0.3) : Color.clear,
                                        lineWidth: 1
                                    )
                            )
                    )
            }
            
            // Enhanced target value
            VStack(alignment: .leading, spacing: 16) {
                Text("Target Value")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                VStack(spacing: 16) {
                    HStack {
                        Text("\(targetValue)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: selectedCategory.color))
                            .contentTransition(.numericText())
                        
                        Text(selectedType.unit)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                    
                    HStack(spacing: 16) {
                        Button(action: {
                            hapticFeedback.impactOccurred()
                            if targetValue > 1 {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    targetValue -= 1
                                }
                            }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.title2)
                                .symbolRenderingMode(.hierarchical)
                                .foregroundColor(Color(hex: selectedCategory.color))
                        }
                        .disabled(targetValue <= 1)
                        
                        Slider(value: Binding(
                            get: { Double(targetValue) },
                            set: { targetValue = Int($0) }
                        ), in: 1...100, step: 1)
                        .tint(Color(hex: selectedCategory.color))
                        
                        Button(action: {
                            hapticFeedback.impactOccurred()
                            if targetValue < 100 {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    targetValue += 1
                                }
                            }
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .symbolRenderingMode(.hierarchical)
                                .foregroundColor(Color(hex: selectedCategory.color))
                        }
                        .disabled(targetValue >= 100)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(hex: selectedCategory.color).opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(hex: selectedCategory.color).opacity(0.2), lineWidth: 1)
                        )
                )
            }
        }
    }
    
    // MARK: - Enhanced Settings Content
    private var settingsContent: some View {
        VStack(spacing: 28) {
            // Enhanced duration
            VStack(alignment: .leading, spacing: 16) {
                Text("Challenge Duration")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                VStack(spacing: 16) {
                    HStack {
                        Text("\(duration)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: selectedCategory.color))
                            .contentTransition(.numericText())
                        
                        Text("days")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Ends:")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                            Text(endDate.formatted(date: .abbreviated, time: .omitted))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                    }
                    
                    HStack(spacing: 16) {
                        Button(action: {
                            hapticFeedback.impactOccurred()
                            if duration > 1 {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    duration -= 1
                                }
                            }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.title2)
                                .symbolRenderingMode(.hierarchical)
                                .foregroundColor(Color(hex: selectedCategory.color))
                        }
                        .disabled(duration <= 1)
                        
                        Slider(value: Binding(
                            get: { Double(duration) },
                            set: { duration = Int($0) }
                        ), in: 1...90, step: 1)
                        .tint(Color(hex: selectedCategory.color))
                        
                        Button(action: {
                            hapticFeedback.impactOccurred()
                            if duration < 90 {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    duration += 1
                                }
                            }
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .symbolRenderingMode(.hierarchical)
                                .foregroundColor(Color(hex: selectedCategory.color))
                        }
                        .disabled(duration >= 90)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(hex: selectedCategory.color).opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(hex: selectedCategory.color).opacity(0.2), lineWidth: 1)
                        )
                )
            }
            
            // Enhanced start date
            VStack(alignment: .leading, spacing: 12) {
                Text("Start Date")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                DatePicker(
                    "Start Date",
                    selection: $startDate,
                    in: Date()...,
                    displayedComponents: .date
                )
                .datePickerStyle(.compact)
                .tint(Color(hex: selectedCategory.color))
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6))
                )
            }
            
            // Enhanced privacy
            VStack(alignment: .leading, spacing: 12) {
                Text("Privacy Settings")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Image(systemName: isPrivate ? "lock.fill" : "globe")
                                .font(.system(size: 16, weight: .medium))
                                .symbolRenderingMode(.hierarchical)
                                .foregroundColor(Color(hex: selectedCategory.color))
                            
                            Text(isPrivate ? "Private Challenge" : "Public Challenge")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                        
                        Text(isPrivate ? "Only people you invite can join" : "Everyone can discover and join")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.secondary)
                            .lineSpacing(2)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $isPrivate)
                        .tint(Color(hex: selectedCategory.color))
                        .scaleEffect(1.1)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6))
                )
            }
        }
    }
    
    // MARK: - Enhanced Review Content
    private var reviewContent: some View {
        VStack(spacing: 24) {
            // Enhanced preview card
            VStack(spacing: 20) {
                // Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(title)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .lineLimit(3)
                        
                        HStack(spacing: 8) {
                            Image(systemName: selectedType.defaultIcon)
                                .font(.system(size: 14, weight: .medium))
                                .symbolRenderingMode(.hierarchical)
                            Text(selectedType.displayName)
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 4) {
                        Text("\(targetValue)")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: selectedCategory.color))
                        
                        Text(selectedType.unit)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                            .kerning(0.5)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(hex: selectedCategory.color).opacity(0.15))
                    )
                }
                
                if !description.isEmpty {
                    Text(description)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineSpacing(3)
                }
                
                // Enhanced details grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    EnhancedDetailRowPreview(
                        icon: selectedCategory.icon, 
                        title: "Category", 
                        value: selectedCategory.displayName, 
                        color: Color(hex: selectedCategory.color)
                    )
                    
                    EnhancedDetailRowPreview(
                        icon: "calendar", 
                        title: "Duration", 
                        value: "\(duration) days", 
                        color: .blue
                    )
                    
                    EnhancedDetailRowPreview(
                        icon: "calendar.badge.clock", 
                        title: "Starts", 
                        value: startDate.formatted(date: .abbreviated, time: .omitted), 
                        color: .green
                    )
                    
                    EnhancedDetailRowPreview(
                        icon: "flag.checkered", 
                        title: "Ends", 
                        value: endDate.formatted(date: .abbreviated, time: .omitted), 
                        color: .red
                    )
                    
                    EnhancedDetailRowPreview(
                        icon: isPrivate ? "lock.fill" : "globe", 
                        title: "Visibility", 
                        value: isPrivate ? "Private" : "Public", 
                        color: isPrivate ? .red : .blue
                    )
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color(hex: selectedCategory.color).opacity(0.15), radius: 12, x: 0, y: 6)
            )
            
            VStack(spacing: 12) {
                Text("Ready to create your challenge?")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("Once created, you can invite friends and start tracking progress together!")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
            .padding(.top, 8)
        }
    }
    
    // MARK: - Enhanced Navigation Buttons
    private var navigationButtons: some View {
        HStack(spacing: 16) {
            if currentStep != .details {
                Button(action: {
                    hapticFeedback.impactOccurred()
                    goToPreviousStep()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                        Text("Back")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(Color(hex: selectedCategory.color))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(hex: selectedCategory.color).opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color(hex: selectedCategory.color).opacity(0.3), lineWidth: 1)
                            )
                    )
                }
            }
            
            Button(action: {
                hapticFeedback.impactOccurred()
                
                if currentStep == .review {
                    createChallenge()
                } else {
                    goToNextStep()
                }
            }) {
                HStack(spacing: 10) {
                    if isCreating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.9)
                    } else {
                        if currentStep != .review {
                            Text("Continue")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 16, weight: .medium))
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18, weight: .medium))
                                .symbolRenderingMode(.hierarchical)
                            Text("Create Challenge")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                        }
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(
                        colors: canProceed && !isCreating ? [
                            Color(hex: selectedCategory.color),
                            Color(hex: selectedCategory.color).opacity(0.8)
                        ] : [Color.gray, Color.gray.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(20)
                .shadow(
                    color: canProceed && !isCreating ? Color(hex: selectedCategory.color).opacity(0.4) : .clear,
                    radius: 12, x: 0, y: 6
                )
            }
            .disabled(!canProceed || isCreating)
            .scaleEffect(canProceed && !isCreating ? 1.0 : 0.95)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: canProceed)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: -4)
        )
    }
    
    // MARK: - Navigation Functions
    private func goToNextStep() {
        let nextStepIndex = currentStep.stepNumber
        if nextStepIndex < CreationStep.allCases.count {
            stepTransition = .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading))
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                currentStep = CreationStep.allCases[nextStepIndex]
            }
        }
    }
    
    private func goToPreviousStep() {
        let previousStepIndex = currentStep.stepNumber - 2
        if previousStepIndex >= 0 {
            stepTransition = .asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing))
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                currentStep = CreationStep.allCases[previousStepIndex]
            }
        }
    }
    
    // MARK: - Validation
    private func validateTitle(_ newTitle: String) {
        let trimmedTitle = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        
        withAnimation(.easeInOut(duration: 0.2)) {
            if trimmedTitle.isEmpty {
                titleError = nil
            } else if trimmedTitle.count < 3 {
                titleError = "Title must be at least 3 characters"
            } else if trimmedTitle.count > 100 {
                titleError = "Title must be less than 100 characters"
            } else {
                titleError = nil
            }
        }
    }
    
    // MARK: - Create Challenge
    private func createChallenge() {
        isCreating = true
        
        Task {
            let request = CreateChallengeRequest(
                title: title,
                description: description,
                endDate: endDate,
                challengeType: selectedType,
                category: selectedCategory,
                targetValue: targetValue,
                habitName: habitName.isEmpty ? title : habitName,
                habitDescription: habitDescription.isEmpty ? description : habitDescription,
                habitIcon: habitIcon,
                habitColor: habitColor,
                linkedHabitId: linkedHabitId
            )
            
            let success = await challengeManager.createChallenge(request)
            
            await MainActor.run {
                isCreating = false
                if success {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Enhanced Supporting Views



struct EnhancedCategoryChip: View {
    let category: ChallengeCategory
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.system(size: 14, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                
                Text(category.displayName)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
            }
            .foregroundColor(isSelected ? .white : Color(hex: category.color))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        isSelected
                        ? LinearGradient(
                            colors: [Color(hex: category.color), Color(hex: category.color).opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        : LinearGradient(colors: [Color(hex: category.color).opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            )
            .shadow(
                color: isSelected ? Color(hex: category.color).opacity(0.3) : .clear,
                radius: 6, x: 0, y: 3
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EnhancedDetailRowPreview: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .kerning(0.5)
            }
            
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.08))
        )
    }
} 