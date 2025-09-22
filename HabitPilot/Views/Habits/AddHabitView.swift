import SwiftUI

struct AddHabitView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var habitStore: HabitStore
    @ObservedObject var purchaseManager: PurchaseService
    @ObservedObject var achievementManager: AchievementManager
    var onHabitCreated: ((Habit) -> Void)?
    
    @State private var name = ""
    @State private var description = ""
    @State private var notificationTime = Date()
    @State private var isEnabled = true
    @State private var color: Color = AddHabitView.nextDefaultColor()
    @State private var showingUpgrade = false
    @State private var selectedDays: [Weekday] = Weekday.allCases
    @State private var reminderMessage: String = "Time for your habit!"
    @State private var frequency: HabitFrequency = .daily
    @State private var customFrequency: Int = 3
    @State private var multipleReminders: [Date] = []
    @State private var showingFrequencyUpgrade = false
    @State private var dailyTarget: Int = 1
    @State private var habitType: HabitType = .simple
    @State private var pulseAnimation = false
    @State private var currentStep = 0
    @State private var animateForm = false
    @State private var selectedColorIndex = 0
    
    // Color palette for cycling
    static var colorIndex: Int = 0
    static func nextDefaultColor() -> Color {
        let color = Color.modernPalette[colorIndex % Color.modernPalette.count]
        colorIndex += 1
        return color
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Unique animated background with morphing gradients
                LinearGradient(
                    colors: [
                        color.opacity(0.15),
                        color.opacity(0.08),
                        color.opacity(0.03)
                    ],
                    startPoint: pulseAnimation ? .topLeading : .bottomTrailing,
                    endPoint: pulseAnimation ? .bottomTrailing : .topLeading
                )
                .ignoresSafeArea()
                .animation(
                    Animation.easeInOut(duration: 4.0)
                        .repeatForever(autoreverses: true),
                    value: pulseAnimation
                )
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Enhanced header section with animated elements
                        enhancedHeaderSection
                            .offset(x: animateForm ? 0 : -50)
                            .opacity(animateForm ? 1 : 0)
                            .animation(Animation.easeOut(duration: 0.6), value: animateForm)
                        
                        // Step-by-step form with modern design
                        stepByStepForm
                            .offset(x: animateForm ? 0 : 50)
                            .opacity(animateForm ? 1 : 0)
                            .animation(Animation.easeOut(duration: 0.6).delay(0.1), value: animateForm)
                        
                        // Enhanced action buttons
                        enhancedActionButtons
                            .offset(x: animateForm ? 0 : -50)
                            .opacity(animateForm ? 1 : 0)
                            .animation(Animation.easeOut(duration: 0.6).delay(0.2), value: animateForm)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 80) // Add extra bottom padding to ensure content can scroll past navigation bar
                }
            }
            .navigationTitle("Create Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                }
            }
            .onAppear {
                pulseAnimation = true
                withAnimation(Animation.easeOut(duration: 0.8)) {
                    animateForm = true
                }
            }
        }
        .sheet(isPresented: $showingUpgrade) {
            UpgradeView(purchaseManager: purchaseManager, habitStore: habitStore)
        }
    }
    
    // MARK: - Enhanced Header Section
    private var enhancedHeaderSection: some View {
        VStack(spacing: 24) {
            // Animated color preview with morphing effects
            ZStack {
                // Outer animated ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                color.opacity(0.6),
                                color.opacity(0.3),
                                color.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 2.0)
                            .repeatForever(autoreverses: true),
                        value: pulseAnimation
                    )
                
                // Inner animated circle
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                color.opacity(0.8),
                                color.opacity(0.4),
                                color.opacity(0.1)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 50
                        )
                    )
                    .frame(width: 80, height: 80)
                    .scaleEffect(pulseAnimation ? 1.05 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 3.0)
                            .repeatForever(autoreverses: true),
                        value: pulseAnimation
                    )
                
                // Main icon
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 12) {
                Text("Create New Habit")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("Build positive routines with smart reminders")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .offset(y: animateForm ? 0 : -20)
        .opacity(animateForm ? 1 : 0)
        .animation(Animation.easeOut(duration: 0.8), value: animateForm)
    }
    
    // MARK: - Step-by-Step Form
    private var stepByStepForm: some View {
        VStack(spacing: 24) {
            // Step indicator
            stepIndicator
            
            // Form content based on current step
            SwiftUI.Group {
                switch currentStep {
                case 0:
                    basicDetailsStep
                case 1:
                    habitTypeStep
                case 2:
                    notificationStep
                case 3:
                    advancedSettingsStep
                default:
                    basicDetailsStep
                }
            }
            .offset(x: animateForm ? 0 : 30)
            .opacity(animateForm ? 1 : 0)
            .animation(Animation.easeOut(duration: 0.6), value: animateForm)
        }
    }
    
    // MARK: - Step Indicator
    private var stepIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<4, id: \.self) { step in
                Circle()
                    .fill(
                        step <= currentStep 
                        ? LinearGradient(
                            colors: [color, color.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        : LinearGradient(
                            colors: [Color.secondary.opacity(0.3), Color.secondary.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 12, height: 12)
                    .scaleEffect(step == currentStep ? 1.2 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: currentStep)
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Step Views
    private var basicDetailsStep: some View {
        VStack(spacing: 20) {
            // Color picker with enhanced design
            VStack(alignment: .leading, spacing: 12) {
                Text("Choose Color")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                    ForEach(Array(Color.modernPalette.enumerated()), id: \.offset) { index, paletteColor in
                        Button(action: {
                            color = paletteColor
                            selectedColorIndex = index
                        }) {
                            ZStack {
                                Circle()
                                    .fill(paletteColor)
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                selectedColorIndex == index ? color : Color.clear,
                                                lineWidth: 3
                                            )
                                    )
                                    .shadow(
                                        color: paletteColor.shadowColor(0.3),
                                        radius: 6,
                                        x: 0,
                                        y: 3
                                    )
                                
                                if selectedColorIndex == index {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            
            // Name and description fields
            VStack(spacing: 16) {
                ModernTextField(
                    title: "Habit Name",
                    text: $name,
                    placeholder: "e.g., Morning Exercise",
                    icon: "textformat",
                    color: color
                )
                
                ModernTextField(
                    title: "Description (Optional)",
                    text: $description,
                    placeholder: "Add a description...",
                    icon: "text.quote",
                    color: color,
                    isMultiline: true
                )
            }
        }
    }
    
    private var habitTypeStep: some View {
        VStack(spacing: 20) {
            Text("Habit Type")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 16) {
                HabitTypeCard(
                    type: .simple,
                    isSelected: habitType == .simple,
                    color: color,
                    action: { habitType = .simple }
                )
                
                HabitTypeCard(
                    type: .incremental,
                    isSelected: habitType == .incremental,
                    color: color,
                    action: { habitType = .incremental }
                )
            }
            
            if habitType == .incremental {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Daily Target")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.primary)
                    
                    HStack {
                        Stepper(value: $dailyTarget, in: 1...100) {
                            Text("\(dailyTarget)")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(color)
                        }
                        .labelsHidden()
                        
                        Spacer()
                        
                        Text("times per day")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.secondary.opacity(0.1))
                    )
                }
            }
        }
    }
    
    private var notificationStep: some View {
        VStack(spacing: 20) {
            Text("Reminder Settings")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 16) {
                // Notification time
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(color)
                            .frame(width: 24)
                        
                        Text("Reminder Time")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.primary)
                    }
                    
                    DatePicker("", selection: $notificationTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.secondary.opacity(0.1))
                        )
                }
                
                // Enable/disable toggle
                HStack {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(color)
                        .frame(width: 24)
                    
                    Text("Enable Notifications")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Toggle("", isOn: $isEnabled)
                        .labelsHidden()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.secondary.opacity(0.1))
                )
            }
        }
    }
    
    private var advancedSettingsStep: some View {
        VStack(spacing: 20) {
            Text("Advanced Settings")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 16) {
                // Frequency settings (Premium)
                if purchaseManager.isUnlimitedPurchased {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Frequency")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Picker("Frequency", selection: $frequency) {
                            ForEach(HabitFrequency.allCases, id: \.self) { freq in
                                HStack {
                                    Image(systemName: freq.icon)
                                    Text(freq.rawValue)
                                }
                                .tag(freq)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.secondary.opacity(0.1))
                        )
                    }
                    
                    // Custom Frequency Input
                    if frequency == .custom {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Every X days")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(.primary)
                            
                            HStack {
                                Image(systemName: "calendar.badge.gearshape")
                                    .foregroundColor(color)
                                    .frame(width: 24)
                                
                                Stepper("Every \(customFrequency) days", value: $customFrequency, in: 2...30)
                                    .labelsHidden()
                                
                                Text("\(customFrequency)")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(color)
                                    .frame(minWidth: 30)
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.secondary.opacity(0.1))
                            )
                        }
                    }
                    
                    // Multiple Reminders (Premium)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Multiple Reminders")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Button("Add Reminder") {
                                multipleReminders.append(Date())
                            }
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(color)
                            )
                        }
                        
                        if multipleReminders.isEmpty {
                            Text("Add multiple reminder times for better habit formation")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(multipleReminders.indices, id: \.self) { index in
                                HStack {
                                    DatePicker("", selection: $multipleReminders[index], displayedComponents: .hourAndMinute)
                                        .labelsHidden()
                                    
                                    Spacer()
                                    
                                    Button("Remove") {
                                        multipleReminders.remove(at: index)
                                    }
                                    .foregroundColor(.red)
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.secondary.opacity(0.1))
                                )
                            }
                        }
                    }
                } else {
                    Button(action: { showingUpgrade = true }) {
                        HStack {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.yellow)
                            
                            Text("Upgrade for Advanced Settings")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.secondary.opacity(0.1))
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Enhanced Action Buttons
    private var enhancedActionButtons: some View {
        VStack(spacing: 16) {
            // Navigation buttons
            HStack(spacing: 16) {
                if currentStep > 0 {
                    Button("Back") {
                        withAnimation(Animation.easeInOut(duration: 0.3)) {
                            currentStep -= 1
                        }
                    }
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.secondary.opacity(0.1))
                    )
                }
                
                Spacer()
                
                if currentStep < 3 {
                    Button("Next") {
                        withAnimation(Animation.easeInOut(duration: 0.3)) {
                            currentStep += 1
                        }
                    }
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [color, color.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: color.shadowColor(0.3), radius: 8, x: 0, y: 4)
                    )
                } else {
                    Button("Create Habit") {
                        createHabit()
                    }
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [color, color.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: color.shadowColor(0.3), radius: 8, x: 0, y: 4)
                    )
                    .disabled(name.isEmpty)
                    .opacity(name.isEmpty ? 0.6 : 1.0)
                }
            }
        }
        .padding(.bottom, 20)
    }
    
    // MARK: - Helper Methods
    private func createHabit() {
        
        let habit = Habit(
            name: name,
            description: description,
            notificationTime: notificationTime,
            isEnabled: isEnabled,
            colorHex: color.toHex(),
            scheduledDays: selectedDays,
            reminderMessage: reminderMessage,
            frequency: frequency,
            customFrequency: frequency == .custom ? customFrequency : nil,
            multipleReminders: multipleReminders,
            type: habitType,
            dailyTarget: habitType == .incremental ? dailyTarget : 1
        )
        
        habitStore.addHabit(habit)
        achievementManager.checkAchievements(for: habitStore)
        
        
        // Call completion handler if provided
        onHabitCreated?(habit)
        
        dismiss()
    }
}

// MARK: - Supporting Views

struct HabitTypeCard: View {
    let type: HabitType
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            isSelected 
                            ? LinearGradient(
                                colors: [color, color.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [Color.secondary.opacity(0.1), Color.secondary.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: type.icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(isSelected ? .white : .secondary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(type.rawValue)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text(type.description)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(color)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isSelected 
                        ? color.opacity(0.1)
                        : Color.secondary.opacity(0.05)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? color.opacity(0.3) : Color.clear,
                                lineWidth: 2
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ModernTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let icon: String
    let color: Color
    var isMultiline: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(color)
                    .frame(width: 24)
                
                Text(title)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.primary)
            }
            
            if isMultiline {
                TextEditor(text: $text)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .frame(minHeight: 80)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.secondary.opacity(0.1))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
            } else {
                TextField(placeholder, text: $text)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.secondary.opacity(0.1))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
            }
        }
    }
}

// MARK: - Extensions
extension HabitType {
    var icon: String {
        switch self {
        case .simple: return "checkmark.circle"
        case .incremental: return "plus.circle"
        }
    }
    
    var description: String {
        switch self {
        case .simple: return "Complete once per day"
        case .incremental: return "Track multiple times per day"
        }
    }
} 