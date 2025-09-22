import SwiftUI

// MARK: - Modern Stat Card Component
struct ModernStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    let gradient: LinearGradient
    
    var body: some View {
        VStack(spacing: 12) {
            // Icon with gradient background
            ZStack {
                Circle()
                    .fill(gradient)
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.secondary.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct HabitDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var habitStore: HabitStore
    let habitID: UUID
    
    private var habit: Habit? {
        habitStore.habits.first(where: { $0.id == habitID })
    }
    
    @State private var name: String = ""
    @State private var description: String = ""
    @State private var notificationTime: Date? = nil
    @State private var isEnabled: Bool = true
    @State private var color: Color = .blue
    @State private var isEditing = false
    @State private var showingDeleteConfirmation = false
    @State private var showingShareSheet = false
    @State private var pulseAnimation = false
    
    init(habitID: UUID, habitStore: HabitStore) {
        self.habitID = habitID
        self.habitStore = habitStore
        // State vars will be set in .onAppear
    }
    
    var body: some View {
        let habit = self.habit
        let habitColor = Color(hex: habit?.colorHex ?? "#007AFF")
        let gradientColors: [Color] = [
            habitColor.opacity(0.1),
            habitColor.opacity(0.05)
        ]
        ZStack {
            // Modern gradient background
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Modern header with habit icon and info
                    HabitDetailHeader(
                        habit: habit,
                        habitColor: habitColor,
                        name: $name,
                        description: $description,
                        isEditing: $isEditing,
                        pulseAnimation: $pulseAnimation
                    )
                    .padding(.top, 20)
                    
                    // Modern statistics cards
                    HabitDetailStats(habit: habit)
                        .padding(.horizontal, 20)
                    
                    // Linked Challenges Section
                    if let habit = habit {
                        LinkedChallengesSection(habitId: habit.id.uuidString)
                            .padding(.horizontal, 20)
                    }
                    
                    // Progress section for incremental habits
                    HabitDetailProgress(
                        habit: habit,
                        habitColor: habitColor,
                        habitStore: habitStore
                    )
                    .padding(.horizontal, 20)
                    
                    // Settings section
                    VStack(spacing: 16) {
                        Text("Settings")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(spacing: 12) {
                            // Notification time setting
                            HStack {
                                Image(systemName: "clock.fill")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(habitColor)
                                    .frame(width: 24)
                                
                                Text("Notification Time")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                if isEditing {
                                    DatePicker(
                                        "",
                                        selection: Binding(
                                            get: { notificationTime ?? Date() },
                                            set: { notificationTime = $0 }
                                        ),
                                        displayedComponents: .hourAndMinute
                                    )
                                        .labelsHidden()
                                } else {
                                    Text(notificationTime?.formatted(date: .omitted, time: .shortened) ?? "N/A")
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                        .foregroundColor(habitColor)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ultraThinMaterial)
                            )
                            
                            // Enable/disable toggle
                            HStack {
                                Image(systemName: isEnabled ? "bell.fill" : "bell.slash")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(isEnabled ? habitColor : .gray)
                                    .frame(width: 24)
                                
                                Text("Notifications")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                if isEditing {
                                    Toggle("", isOn: $isEnabled)
                                        .labelsHidden()
                                } else {
                                    Text(isEnabled ? "Enabled" : "Disabled")
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                        .foregroundColor(isEnabled ? .green : .red)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ultraThinMaterial)
                            )
                            
                            // Color picker
                            if isEditing {
                                HStack {
                                    Image(systemName: "paintbrush.fill")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(habitColor)
                                        .frame(width: 24)
                                    
                                    Text("Habit Color")
                                        .font(.system(size: 16, weight: .medium, design: .rounded))
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    ColorPicker("", selection: $color, supportsOpacity: false)
                                        .labelsHidden()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.ultraThinMaterial)
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Action buttons
                    VStack(spacing: 12) {
                        if !isEditing {
                            Button(action: { showingShareSheet = true }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 16, weight: .medium))
                                    Text("Share Progress")
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(habitColor)
                                )
                                .shadow(color: habitColor.shadowColor(opacity: 0.3), radius: 8, x: 0, y: 4)
                            }
                        }
                        
                        Button("Delete Habit") {
                            showingDeleteConfirmation = true
                        }
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.red)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.red.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(.red.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40) // Add extra bottom padding to ensure content can scroll past navigation bar
                }
            }
        }
        .onAppear {
            if let habit = habit {
                name = habit.name
                description = habit.description
                notificationTime = habit.notificationTime
                isEnabled = habit.isEnabled
                color = Color(hex: habit.colorHex)
            }
            pulseAnimation = true
        }
        .navigationTitle("Habit Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Done") {
                    dismiss()
                }
                .font(.system(size: 16, weight: .semibold, design: .rounded))
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditing ? "Save" : "Edit") {
                    if isEditing {
                        saveChanges()
                    }
                    isEditing.toggle()
                }
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(habitColor)
            }
        }
        .confirmationDialog(
            "Delete Habit",
            isPresented: $showingDeleteConfirmation
        ) {
            Button("Delete '\(habit?.name ?? "")'", role: .destructive) {
                deleteHabit()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this habit? This action cannot be undone.")
        }
        .sheet(isPresented: $showingShareSheet) {
            ActivityView(activityItems: [shareText])
        }
    }
    
    private func saveChanges() {
        guard var updatedHabit = habit else { return }
        updatedHabit.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedHabit.description = description.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedHabit.notificationTime = notificationTime
        updatedHabit.isEnabled = isEnabled
        updatedHabit.colorHex = color.toHex()
        
        // Update the multipleReminders array with the new notification time
        // This ensures notifications are scheduled for the correct time
        if updatedHabit.multipleReminders.count == 1 {
            // If there's only one reminder (the default), update it
            if let notificationTime = notificationTime {
                updatedHabit.multipleReminders = [notificationTime]
            } else {
                updatedHabit.multipleReminders = []
            }
        } else {
            // If there are multiple reminders, update the first one (primary reminder)
            var newReminders = updatedHabit.multipleReminders ?? []
            if !newReminders.isEmpty {
                if let notificationTime = notificationTime {
                    newReminders[0] = notificationTime
                }
                updatedHabit.multipleReminders = newReminders
            }
        }
        
        habitStore.updateHabit(updatedHabit)
    }
    
    private func deleteHabit() {
        if let habit = habit {
            habitStore.deleteHabit(habit)
        }
        dismiss()
    }
    
    private var shareText: String {
        "I've kept my ''\(habit?.name ?? "")' habit for \(habit?.streak ?? 0) days using HabitPilot AI! 🚀"
    }
}

// UIKit wrapper for UIActivityViewController
struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
} 

struct HabitDetailHeader: View {
    let habit: Habit?
    let habitColor: Color
    @Binding var name: String
    @Binding var description: String
    @Binding var isEditing: Bool
    @Binding var pulseAnimation: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            // Animated habit icon
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                habitColor.opacity(0.8),
                                habitColor.opacity(0.4),
                                habitColor.opacity(0.1)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 50
                        )
                    )
                    .frame(width: 100, height: 100)
                    .scaleEffect(pulseAnimation ? 1.05 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 2.0)
                            .repeatForever(autoreverses: true),
                        value: pulseAnimation
                    )
                
                Image(systemName: habit?.isCompletedToday() == true ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(
                        habit?.isCompletedToday() == true 
                        ? Color.successGradient 
                        : LinearGradient(
                            colors: [habitColor, habitColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 8) {
                if isEditing {
                    TextField("Habit Name", text: $name)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.secondary.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(habitColor.opacity(0.3), lineWidth: 1)
                                )
                        )
                } else {
                    Text(name)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                }
                
                if !description.isEmpty || isEditing {
                    if isEditing {
                        TextField("Description", text: $description)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.secondary.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(habitColor.opacity(0.3), lineWidth: 1)
                                    )
                            )
                    } else {
                        Text(description)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                }
            }
        }
    }
} 

struct HabitDetailStats: View {
    let habit: Habit?
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            // Streak card
            ModernStatCard(
                title: "Current Streak",
                value: "\(habit?.streak ?? 0)",
                subtitle: "days",
                icon: "flame.fill",
                color: Color.orange,
                gradient: LinearGradient(
                    colors: [Color.orange, Color.orange.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            
            // Today's status card
            let isCompleted = habit?.isCompletedToday() == true
            let statusColor: Color = isCompleted ? .green : .blue
            let statusGradient: LinearGradient = isCompleted 
                ? Color.successGradient 
                : LinearGradient(
                    colors: [Color.blue, Color.blue.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            
            ModernStatCard(
                title: "Today's Status",
                value: isCompleted ? "Completed" : "Incomplete",
                subtitle: "",
                icon: isCompleted ? "checkmark.circle.fill" : "clock.fill",
                color: statusColor,
                gradient: statusGradient
            )
        }
    }
}

struct HabitDetailProgress: View {
    let habit: Habit?
    let habitColor: Color
    let habitStore: HabitStore
    
    var body: some View {
        if let habit = habit {
            if habit.type == .incremental {
                IncrementalHabitProgress(habit: habit, habitColor: habitColor, habitStore: habitStore)
            } else if habit.type == .simple {
                SimpleHabitProgress(habit: habit, habitColor: habitColor, habitStore: habitStore)
            }
        }
    }
}

struct IncrementalHabitProgress: View {
    let habit: Habit
    let habitColor: Color
    let habitStore: HabitStore
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Today's Progress")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            VStack(spacing: 16) {
                HStack {
                    Text("\(habit.todayProgress)/\(habit.dailyTarget)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Spacer()
                    Text("\(Int(habit.progressFraction * 100))%")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                }
                
                ProgressBar(
                    progress: habit.progressFraction,
                    backgroundColor: habitColor.opacity(0.2),
                    progressColor: habitColor,
                    height: 12,
                    animated: true
                )
                
                IncrementButton(
                    habit: habit,
                    habitColor: habitColor,
                    habitStore: habitStore
                )
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.secondary.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(habitColor.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }
}

struct IncrementButton: View {
    let habit: Habit
    let habitColor: Color
    let habitStore: HabitStore
    
    var body: some View {
        let buttonBackground: LinearGradient = habit.isAtTarget 
            ? Color.successGradient 
            : LinearGradient(
                colors: [habitColor, habitColor.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        let buttonShadow = habitColor.shadowColor(opacity: 0.3)
        
        Button(action: {
            if habit.canIncrement {
                habitStore.incrementHabitProgress(habit)
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
                Text(habit.canIncrement ? "Increment Progress" : "Completed!")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(buttonBackground)
            )
            .shadow(color: buttonShadow, radius: 10, x: 0, y: 5)
        }
        .disabled(habit.isAtTarget)
    }
}

struct SimpleHabitProgress: View {
    let habit: Habit
    let habitColor: Color
    let habitStore: HabitStore
    
    var body: some View {
        let buttonBackground = habit.isAtTarget ? Color.gray.opacity(0.3) : habitColor
        let buttonShadow = habit.isAtTarget ? Color.clear : habitColor.shadowColor(opacity: 0.3)
        
        VStack(spacing: 16) {
            Button(habit.isAtTarget ? "Already Completed Today" : "Mark as Completed") {
                habitStore.toggleHabitCompletion(habit)
            }
            .font(.system(size: 18, weight: .semibold, design: .rounded))
            .foregroundColor(habit.isAtTarget ? .secondary : .white)
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(buttonBackground)
            )
            .disabled(habit.isAtTarget)
            .shadow(color: buttonShadow, radius: 10, x: 0, y: 5)
        }
    }
} 