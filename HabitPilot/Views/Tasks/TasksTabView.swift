import SwiftUI
import UIKit

enum TaskSection: String, CaseIterable, Identifiable {
    case today = "Today"
    case thisWeek = "This week"
    case later = "Later"
    var id: String { rawValue }
}

// MARK: - Drag State Manager
class DragStateManager: ObservableObject {
    @Published var isDragging = false
    @Published var draggedTask: TaskItem?
    @Published var dragOffset: CGSize = .zero
    @Published var originalPosition: CGPoint = .zero
    @Published var activeDropTarget: TaskSection?
    
    func startDrag(task: TaskItem, originalPosition: CGPoint) {
        isDragging = true
        draggedTask = task
        self.originalPosition = originalPosition
        dragOffset = .zero
    }
    
    func updateDrag(offset: CGSize) {
        dragOffset = offset
        updateDropTarget()
    }
    
    func endDrag() {
        isDragging = false
        draggedTask = nil
        activeDropTarget = nil
        dragOffset = .zero
        originalPosition = .zero
    }
    
    private func updateDropTarget() {
        let screenWidth = UIScreen.main.bounds.width
        
        // Calculate the column widths for full-height drop zones
        let horizontalPadding: CGFloat = 20
        let buttonSpacing: CGFloat = 12
        let columnWidth = (screenWidth - (horizontalPadding * 2) - (buttonSpacing * 2)) / 3
        
        // Calculate column boundaries
        let column1X = horizontalPadding
        let column2X = horizontalPadding + columnWidth + buttonSpacing
        let column3X = horizontalPadding + (columnWidth + buttonSpacing) * 2
        
        // Use the center of the screen as reference point for drag detection
        let dragX = screenWidth / 2 + dragOffset.width
        
        // Check if drag is in any of the three columns (full height)
        if dragX >= column1X && dragX < column1X + columnWidth {
            activeDropTarget = .today
        } else if dragX >= column2X && dragX < column2X + columnWidth {
            activeDropTarget = .thisWeek
        } else if dragX >= column3X && dragX < column3X + columnWidth {
            activeDropTarget = .later
        } else {
            activeDropTarget = nil
        }
    }
}

struct TasksTabView: View {
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var suggestionManager: SuggestionHelper
    @State private var newTaskTitle = ""
    @State private var showingAddTask = false
    @State private var showingTemplates = false
    @State private var selectedTab: TaskSection = .today
    @StateObject private var dragStateManager = DragStateManager()
    @State private var forceRefresh = false
    @StateObject private var purchaseManager = PurchaseService.shared
    @State private var showingUpgrade = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.secondaryBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Clean Header with improved spacing
                    HStack(alignment: .center) {
                        Text("Tasks")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        // Clean action buttons with better spacing
                        HStack(spacing: 12) {
                            Button(action: { 
                                if taskStore.canAddMoreTasks {
                                    showingAddTask = true
                                } else {
                                    showingUpgrade = true
                                }
                            }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.white)
                                    .frame(width: 48, height: 48)
                                    .background(
                                        Circle()
                                            .fill(Color.infoBlue)
                                    )
                                    .shadow(color: Color.infoBlue.opacity(0.3), radius: 6, x: 0, y: 3)
                            }
                            
                            Button(action: { 
                                if taskStore.canAddMoreTasks {
                                    showingTemplates = true
                                } else {
                                    showingUpgrade = true
                                }
                            }) {
                                Image(systemName: "doc.text")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                    .frame(width: 48, height: 48)
                                    .background(
                                        Circle()
                                            .fill(Color.blue)
                                    )
                                    .shadow(color: Color.blue.opacity(0.3), radius: 6, x: 0, y: 3)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                    
                    // Enhanced task limit indicator for freemium users
                    if !taskStore.canAddMoreTasks && taskStore.tasks.count >= 5 {
                        HStack(spacing: 12) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.infoBlue)
                                .font(.title3)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Free Plan Limit")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                Text("\(taskStore.remainingFreeTasks) tasks remaining")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button("Upgrade") {
                                showingUpgrade = true
                            }
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.infoBlue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.infoBlue.opacity(0.1))
                            )
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.infoBlue.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.infoBlue.opacity(0.2), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal, 24)
                        .padding(.bottom, 8)
                    }
                    
                    if taskStore.isLoading {
                        loadingView
                    } else if taskStore.tasks.isEmpty {
                        emptyStateView
                    } else {
                        tasksListView
                    }
                }
                
                // Visual feedback overlay for drag state (minimal)
                if dragStateManager.isDragging {
                    Color.black.opacity(0.02)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAddTask) {
                AddTaskView(taskStore: taskStore)
            }
            .sheet(isPresented: $showingTemplates) {
                TaskTemplatesView(taskStore: taskStore)
            }
            .sheet(isPresented: $showingUpgrade) {
                UpgradeView(purchaseManager: purchaseManager, habitStore: HabitStore())
            }
            .environmentObject(dragStateManager)
            .id(forceRefresh)
            .onAppear {
                Task {
                    await suggestionManager.checkForSuggestion(
                        contentType: .task,
                        taskStore: taskStore
                    )
                }
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Clean loading content
            VStack(spacing: 32) {
                VStack(spacing: 24) {
                    // Enhanced loading animation
                    ZStack {
                        Circle()
                            .fill(Color.infoBlue.opacity(0.1))
                            .frame(width: 120, height: 120)
                        
                        Circle()
                            .stroke(Color.infoBlue.opacity(0.3), lineWidth: 1)
                            .frame(width: 120, height: 120)
                        
                        // Animated progress ring
                        Circle()
                            .trim(from: 0, to: 0.7)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.infoBlue, Color.cyan.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 3, lineCap: .round)
                            )
                            .frame(width: 80, height: 80)
                            .rotationEffect(.degrees(-90))
                            .animation(
                                Animation.linear(duration: 1.5)
                                    .repeatForever(autoreverses: false),
                                value: UUID()
                            )
                        
                        // Center loading icon
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.infoBlue, Color.cyan.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .animation(
                                Animation.linear(duration: 2)
                                    .repeatForever(autoreverses: false),
                                value: UUID()
                            )
                    }
                    
                    VStack(spacing: 12) {
                        Text("Loading your tasks")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color.primary,
                                        Color.infoBlue.opacity(0.8)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("Connecting to server...")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                
                // Loading tips
                VStack(spacing: 16) {
                    ForEach(0..<3, id: \.self) { index in
                        let tips = [
                            ("wifi", "Checking network connection", Color.teal),
                            ("icloud", "Syncing with server", Color.infoBlue),
                            ("checkmark.seal", "Almost ready!", Color.mint)
                        ]
                        
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(tips[index].2.opacity(0.15))
                                    .frame(width: 40, height: 40)
                                
                                Image(systemName: tips[index].0)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(tips[index].2)
                            }
                            
                            Text(tips[index].1)
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundColor(.secondaryText)
                            
                            Spacer()
                            
                            // Animated dots
                            HStack(spacing: 4) {
                                ForEach(0..<3) { dotIndex in
                                    Circle()
                                        .fill(tips[index].2.opacity(0.6))
                                        .frame(width: 4, height: 4)
                                        .scaleEffect(1.0)
                                        .animation(
                                            Animation.easeInOut(duration: 0.6)
                                                .repeatForever(autoreverses: true)
                                                .delay(Double(dotIndex) * 0.2),
                                            value: UUID()
                                        )
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.cardBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(tips[index].2.opacity(0.2), lineWidth: 1)
                                )
                        )
                        .opacity(0.8)
                    }
                }
                .padding(.horizontal, 24)
            }
            
            Spacer()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Clean text content without middle illustration
            VStack(spacing: 32) {
                VStack(spacing: 16) {
                    Text("No tasks yet")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color.primary,
                                    Color.infoBlue.opacity(0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("Start organizing your day by creating\nyour first task")
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                }
                
                // Feature highlights with more space
                VStack(spacing: 12) {
                    ForEach(0..<3, id: \.self) { index in
                        let features = [
                            ("timer", "Stay focused and productive", Color.teal),
                            ("list.bullet.clipboard.fill", "Organize your priorities", Color.infoBlue),
                            ("checkmark.seal.fill", "Complete with satisfaction", Color.mint)
                        ]
                        
                        HStack(spacing: 16) {
                            Circle()
                                .fill(features[index].2.opacity(0.15))
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Image(systemName: features[index].0)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(features[index].2)
                                )
                            
                            Text(features[index].1)
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(.secondaryText)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.cardBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(features[index].2.opacity(0.2), lineWidth: 1)
                                )
                        )
                    }
                }
                .padding(.horizontal, 24)
            }
            
            Spacer()
            
            // Single action button
            Button(action: { 
                if taskStore.canAddMoreTasks {
                    showingAddTask = true
                } else {
                    showingUpgrade = true
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text("Create Your First Task")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [
                            Color.infoBlue,
                            Color.cyan.opacity(0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(
                    color: Color.infoBlue.opacity(0.3),
                    radius: 8,
                    x: 0,
                    y: 4
                )
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 100)
        }
    }
    
    private var tasksListView: some View {
        ZStack {
            VStack(spacing: 0) {
                // Enhanced section picker with better spacing
                HStack(spacing: 16) {
                    ForEach(TaskSection.allCases) { section in
                        TaskSectionButton(
                            section: section,
                            isSelected: selectedTab == section,
                            onTap: {
                                selectedTab = section
                                HapticFeedback.shared.buttonPress()
                            },
                            isDragTarget: dragStateManager.isDragging && dragStateManager.activeDropTarget == section
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 20)
                
                // Tasks list with improved empty states
                if filteredTasksForSelectedTab.isEmpty {
                    Spacer()
                    VStack(spacing: 24) {
                        // Enhanced empty state icon with background
                        ZStack {
                            Circle()
                                .fill(Color.secondary.opacity(0.1))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: emptyStateIcon)
                                .font(.system(size: 36, weight: .light))
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(spacing: 8) {
                            Text(emptyStateTitle)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text(emptyStateSubtitle)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                    }
                    .padding(.horizontal, 32)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredTasksForSelectedTab) { task in
                                CleanTaskRowView(taskStore: taskStore, task: task)
                            }
                            
                            // AI Suggestion with better spacing
                            if suggestionManager.showingSuggestion,
                               let suggestion = suggestionManager.currentSuggestion {
                                UniversalSuggestionView(
                                    suggestion: suggestion,
                                    onConfirm: {
                                        suggestionManager.confirmSuggestion(
                                            suggestion,
                                            habitStore: nil,
                                            taskStore: taskStore,
                                            goalStore: nil
                                        )
                                    },
                                    onDismiss: {
                                        suggestionManager.dismissSuggestion(suggestion)
                                        
                                        Task {
                                            try? await Task.sleep(nanoseconds: 500_000_000)
                                            await suggestionManager.checkForSuggestion(
                                                contentType: .task,
                                                taskStore: taskStore
                                            )
                                        }
                                    }
                                )
                                .padding(.top, 20)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 100) // Increased bottom padding for better spacing
                    }
                }
            }
            
            // Dragged item overlay - positioned above everything
            if dragStateManager.isDragging, let draggedTask = dragStateManager.draggedTask {
                DraggedTaskOverlay(
                    task: draggedTask, 
                    dragOffset: dragStateManager.dragOffset
                )
                .position(
                    x: dragStateManager.originalPosition.x,
                    y: dragStateManager.originalPosition.y
                )
                .zIndex(1000) // Ensure it's above everything
            }
        }
    }
    
    private var tasksForSelectedTab: [TaskItem] {
        switch selectedTab {
        case .today:
            return todayTasks
        case .thisWeek:
            return thisWeekTasks
        case .later:
            return laterTasks
        }
    }
    
    private var filteredTasksForSelectedTab: [TaskItem] {
        return sortTasks(tasksForSelectedTab)
    }
    
    private func sortTasks(_ tasks: [TaskItem]) -> [TaskItem] {
        return tasks.sorted { (task1: TaskItem, task2: TaskItem) in
            // First sort by completion status (uncompleted first)
            if task1.isCompleted != task2.isCompleted {
                return !task1.isCompleted
            }
            // Then sort by priority (high to low)
            if task1.priority.sortOrder != task2.priority.sortOrder {
                return task1.priority.sortOrder < task2.priority.sortOrder
            }
            // Finally sort by creation date (newest first)
            return task1.createdAt > task2.createdAt
        }
    }
    
    private var todayTasks: [TaskItem] {
        return taskStore.tasks.filter { $0.category == .today }
    }
    
    private var thisWeekTasks: [TaskItem] {
        return taskStore.tasks.filter { $0.category == .thisWeek }
    }
    
    private var laterTasks: [TaskItem] {
        return taskStore.tasks.filter { $0.category == .later }
    }
    
    private var emptyStateIcon: String {
        switch selectedTab {
        case .today: return "sun.max"
        case .thisWeek: return "calendar"
        case .later: return "clock.arrow.circlepath"
        }
    }
    
    private var emptyStateTitle: String {
        switch selectedTab {
        case .today: return "No tasks for today!"
        case .thisWeek: return "No tasks this week!"
        case .later: return "No upcoming tasks!"
        }
    }
    
    private var emptyStateSubtitle: String {
        switch selectedTab {
        case .today: return "You're all caught up for today."
        case .thisWeek: return "Nothing scheduled for this week."
        case .later: return "No tasks planned for later."
        }
    }
    
    private func moveTaskToSection(_ task: TaskItem, section: TaskSection) {
        let newCategory: TaskItem.TaskCategory
        
        switch section {
        case .today:
            newCategory = .today
        case .thisWeek:
            newCategory = .thisWeek
        case .later:
            newCategory = .later
        }
        
        Task {
            await taskStore.updateTaskCategory(task, newCategory: newCategory)
        }
        
        DispatchQueue.main.async {
            self.taskStore.objectWillChange.send()
            self.forceRefresh.toggle()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.taskStore.objectWillChange.send()
            }
        }
        
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
    }
}

// MARK: - Clean Task Row View
struct CleanTaskRowView: View {
    @ObservedObject var taskStore: TaskStore
    @EnvironmentObject var dragStateManager: DragStateManager
    let task: TaskItem
    
    @State private var showingEditTask = false
    @State private var isDragging = false
    @State private var itemPosition: CGPoint = .zero
    
    private var isCurrentTaskDragging: Bool {
        dragStateManager.isDragging && dragStateManager.draggedTask?.id == task.id
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Enhanced completion toggle with better visual feedback
            Button(action: {
                Task {
                    await taskStore.toggleTaskCompletion(task)
                    HapticFeedback.shared.habitCompleted()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(task.isCompleted ? Color.successGreen : Color.clear)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Circle()
                                .stroke(
                                    task.isCompleted ? Color.successGreen : Color(hex: task.colorHex).opacity(0.4),
                                    lineWidth: 2.5
                                )
                        )
                        .shadow(
                            color: task.isCompleted ? Color.successGreen.opacity(0.3) : Color.clear,
                            radius: 4,
                            x: 0,
                            y: 2
                        )
                    
                    if task.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Enhanced task content with better layout
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    Text(task.title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .strikethrough(task.isCompleted)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    // Enhanced priority badge with better styling
                    Text(task.priority.rawValue)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color(hex: task.priority.color))
                        )
                        .shadow(color: Color(hex: task.priority.color).opacity(0.3), radius: 2, x: 0, y: 1)
                }
                
                HStack {
                    // Enhanced category indicator
                    HStack(spacing: 6) {
                        Image(systemName: categoryIcon)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(hex: categoryColor))
                        
                        Text(task.category.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(hex: categoryColor).opacity(0.1))
                    )
                    
                    Spacer()
                    
                    // Enhanced edit button
                    Button(action: {
                        showingEditTask = true
                        HapticFeedback.shared.buttonPress()
                    }) {
                        Image(systemName: "pencil")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(width: 28, height: 28)
                            .background(
                                Circle()
                                    .fill(Color.secondary.opacity(0.1))
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(hex: task.colorHex).opacity(0.3),
                                    Color(hex: task.colorHex).opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(
                    color: Color.black.opacity(0.08),
                    radius: 8,
                    x: 0,
                    y: 3
                )
        )
        .opacity(task.isCompleted ? 0.7 : (isCurrentTaskDragging ? 0.3 : 1.0))
        .animation(.easeInOut(duration: 0.2), value: isCurrentTaskDragging)
        .background(
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        itemPosition = CGPoint(
                            x: geometry.frame(in: .global).midX,
                            y: geometry.frame(in: .global).midY - 10 // Adjust for visual center
                        )
                    }
                    .onChange(of: geometry.frame(in: .global)) { newFrame in
                        itemPosition = CGPoint(
                            x: newFrame.midX,
                            y: newFrame.midY - 10 // Adjust for visual center
                        )
                    }
            }
        )
        .gesture(
            DragGesture(minimumDistance: 10)
                .onChanged { drag in
                    if !dragStateManager.isDragging {
                        // Use the item's center position for exact layering
                        dragStateManager.startDrag(task: task, originalPosition: itemPosition)
                        isDragging = true
                    }
                    if isCurrentTaskDragging {
                        dragStateManager.updateDrag(offset: drag.translation)
                    }
                }
                .onEnded { drag in
                    if isCurrentTaskDragging {
                        if let activeDropTarget = dragStateManager.activeDropTarget {
                            moveTaskToSection(task, section: activeDropTarget)
                        }
                        withAnimation(.easeOut(duration: 0.3)) {
                            dragStateManager.endDrag()
                            isDragging = false
                        }
                    }
                }
        )
        .sheet(isPresented: $showingEditTask) {
            EditTaskView(task: task, taskStore: taskStore)
        }
    }
    
    private var categoryIcon: String {
        switch task.category {
        case .today: return "sun.max"
        case .thisWeek: return "calendar.badge.clock"
        case .later: return "clock.arrow.circlepath"
        }
    }
    
    private var categoryColor: String {
        switch task.category {
        case .today: return "#34C759"
        case .thisWeek: return "#FF9500"
        case .later: return "#007AFF"
        }
    }
    
    private func moveTaskToSection(_ task: TaskItem, section: TaskSection) {
        let newCategory: TaskItem.TaskCategory
        
        switch section {
        case .today:
            newCategory = .today
        case .thisWeek:
            newCategory = .thisWeek
        case .later:
            newCategory = .later
        }
        
        Task {
            await taskStore.updateTaskCategory(task, newCategory: newCategory)
        }
        
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
    }
}

// MARK: - TaskSectionButton
struct TaskSectionButton: View {
    let section: TaskSection
    let isSelected: Bool
    let onTap: () -> Void
    let isDragTarget: Bool
    
    init(section: TaskSection, isSelected: Bool, onTap: @escaping () -> Void, isDragTarget: Bool = false) {
        self.section = section
        self.isSelected = isSelected
        self.onTap = onTap
        self.isDragTarget = isDragTarget
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Image(systemName: sectionIcon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isSelected ? .white : Color(hex: sectionColor))
                
                Text(section.rawValue)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .white : .primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        isDragTarget ?
                        LinearGradient(
                            colors: [
                                Color(hex: sectionColor).opacity(0.4),
                                Color(hex: sectionColor).opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        isSelected ?
                        LinearGradient(
                            colors: [
                                Color(hex: sectionColor),
                                Color(hex: sectionColor).opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [
                                Color(hex: sectionColor).opacity(0.12),
                                Color(hex: sectionColor).opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isDragTarget ? Color(hex: sectionColor) : (isSelected ? Color(hex: sectionColor) : Color(hex: sectionColor).opacity(0.3)),
                        lineWidth: isDragTarget ? 2 : (isSelected ? 0 : 1.5)
                    )
            )
            .shadow(
                color: isDragTarget ? Color(hex: sectionColor).opacity(0.4) : (isSelected ? Color(hex: sectionColor).opacity(0.3) : Color.clear),
                radius: isDragTarget ? 8 : 6,
                x: 0,
                y: isDragTarget ? 4 : 2
            )
            .scaleEffect(isDragTarget ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isDragTarget)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var sectionIcon: String {
        switch section {
        case .today: return "sun.max"
        case .thisWeek: return "calendar.badge.clock"
        case .later: return "clock.arrow.circlepath"
        }
    }
    
    private var sectionColor: String {
        switch section {
        case .today: return "#34C759"
        case .thisWeek: return "#FF9500"
        case .later: return "#007AFF"
        }
    }
}

// MARK: - Add Task View
struct AddTaskView: View {
    @ObservedObject var taskStore: TaskStore
    @Environment(\.dismiss) private var dismiss
    @StateObject private var purchaseManager = PurchaseService.shared
    @State private var showingUpgrade = false
    
    @State private var taskTitle = ""
    @State private var selectedCategory: TaskItem.TaskCategory = .today
    @State private var selectedColor: Color = AddTaskView.nextDefaultColor()
    @State private var selectedPriority: TaskItem.TaskPriority = .medium
    @State private var animateForm = false
    
    // Color palette for cycling
    static var colorIndex: Int = 0
    static func nextDefaultColor() -> Color {
        let color = Color.modernPalette[colorIndex % Color.modernPalette.count]
        colorIndex += 1
        return color
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Enhanced header section
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(selectedColor.opacity(0.1))
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Circle()
                                        .stroke(selectedColor.opacity(0.3), lineWidth: 1)
                                )
                            
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 40, weight: .light))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [selectedColor, selectedColor.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        
                        VStack(spacing: 8) {
                            Text("Create New Task")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text("Stay organized with timely reminders")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Enhanced form sections
                    VStack(spacing: 16) {
                        // Task Details Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "pencil.circle.fill")
                                    .foregroundColor(.infoBlue)
                                    .font(.title3)
                                
                                Text("Task Details")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                            }
                            
                            TextField("e.g., Submit report", text: $taskTitle)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.cardBackground)
                                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                        )
                        
                        // Category Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "calendar.circle.fill")
                                    .foregroundColor(.infoBlue)
                                    .font(.title3)
                                
                                Text("When")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                            }
                            
                            HStack(spacing: 12) {
                                ForEach(TaskItem.TaskCategory.allCases, id: \.self) { category in
                                    CleanDueTimeButton(
                                        dueTime: category,
                                        isSelected: selectedCategory == category,
                                        onTap: {
                                            selectedCategory = category
                                            HapticFeedback.shared.buttonPress()
                                        }
                                    )
                                }
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.cardBackground)
                                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                        )
                        
                        // Priority Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "flag.circle.fill")
                                    .foregroundColor(.infoBlue)
                                    .font(.title3)
                                
                                Text("Priority")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                            }
                            
                            HStack(spacing: 12) {
                                ForEach(TaskItem.TaskPriority.allCases, id: \.self) { priority in
                                    CleanPriorityButton(
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
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.cardBackground)
                                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                        )
                        
                        // Color Selection Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "paintpalette.circle.fill")
                                    .foregroundColor(.infoBlue)
                                    .font(.title3)
                                
                                Text("Color")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                            }
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                                ForEach(Array(Color.modernPalette.enumerated()), id: \.offset) { index, paletteColor in
                                    CleanColorButton(
                                        color: paletteColor,
                                        isSelected: selectedColor == paletteColor,
                                        onTap: { selectedColor = paletteColor }
                                    )
                                }
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.cardBackground)
                                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // Enhanced Create Button
                    Button(action: {
                        if !taskTitle.isEmpty {
                            if taskStore.canAddMoreTasks {
                                Task {
                                    await taskStore.addTask(
                                        title: taskTitle,
                                        category: selectedCategory,
                                        colorHex: selectedColor.toHex() ?? "#007AFF",
                                        priority: selectedPriority
                                    )
                                }
                                Self.colorIndex = (Self.colorIndex + 1) % Color.modernPalette.count
                                dismiss()
                            } else {
                                showingUpgrade = true
                            }
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .medium))
                            Text("Create Task")
                                .fontWeight(.semibold)
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color.infoBlue,
                                    Color.infoBlue.opacity(0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: Color.infoBlue.opacity(0.3), radius: 6, x: 0, y: 3)
                    }
                    .disabled(taskTitle.isEmpty)
                    .opacity(taskTitle.isEmpty ? 0.6 : 1.0)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
            .background(Color.secondaryBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
            }
            .sheet(isPresented: $showingUpgrade) {
                UpgradeView(purchaseManager: purchaseManager, habitStore: HabitStore())
            }
        }
    }
}

// MARK: - Edit Task View
struct EditTaskView: View {
    @ObservedObject var taskStore: TaskStore
    @Environment(\.dismiss) private var dismiss
    let task: TaskItem
    
    @State private var taskTitle: String
    @State private var selectedCategory: TaskItem.TaskCategory
    @State private var selectedColor: Color
    @State private var selectedPriority: TaskItem.TaskPriority
    @State private var showingDeleteAlert = false
    
    init(task: TaskItem, taskStore: TaskStore) {
        self.task = task
        self.taskStore = taskStore
        
        _taskTitle = State(initialValue: task.title)
        _selectedCategory = State(initialValue: task.category)
        _selectedColor = State(initialValue: Color(hex: task.colorHex) ?? .blue)
        _selectedPriority = State(initialValue: task.priority)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Enhanced header section
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(selectedColor.opacity(0.1))
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Circle()
                                        .stroke(selectedColor.opacity(0.3), lineWidth: 1)
                                )
                            
                            Image(systemName: "pencil.circle.fill")
                                .font(.system(size: 40, weight: .light))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [selectedColor, selectedColor.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        
                        VStack(spacing: 8) {
                            Text("Edit Task")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text("Update your task details")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Enhanced form sections
                    VStack(spacing: 16) {
                        // Task Details Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "pencil.circle.fill")
                                    .foregroundColor(.infoBlue)
                                    .font(.title3)
                                
                                Text("Task Details")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                            }
                            
                            TextField("e.g., Submit report", text: $taskTitle)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.cardBackground)
                                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                        )
                        
                        // Category Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "calendar.circle.fill")
                                    .foregroundColor(.infoBlue)
                                    .font(.title3)
                                
                                Text("When")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                            }
                            
                            HStack(spacing: 12) {
                                ForEach(TaskItem.TaskCategory.allCases, id: \.self) { category in
                                    CleanDueTimeButton(
                                        dueTime: category,
                                        isSelected: selectedCategory == category,
                                        onTap: {
                                            selectedCategory = category
                                            HapticFeedback.shared.buttonPress()
                                        }
                                    )
                                }
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.cardBackground)
                                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                        )
                        
                        // Priority Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "flag.circle.fill")
                                    .foregroundColor(.infoBlue)
                                    .font(.title3)
                                
                                Text("Priority")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                            }
                            
                            HStack(spacing: 12) {
                                ForEach(TaskItem.TaskPriority.allCases, id: \.self) { priority in
                                    CleanPriorityButton(
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
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.cardBackground)
                                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                        )
                        
                        // Color Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "paintpalette.circle.fill")
                                    .foregroundColor(.infoBlue)
                                    .font(.title3)
                                
                                Text("Color")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                            }
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                                ForEach(Color.modernPalette, id: \.self) { paletteColor in
                                    CleanColorButton(
                                        color: paletteColor,
                                        isSelected: selectedColor == paletteColor,
                                        onTap: { selectedColor = paletteColor }
                                    )
                                }
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.cardBackground)
                                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // Action buttons
                    VStack(spacing: 12) {
                        // Update Button
                        Button(action: {
                            if !taskTitle.isEmpty {
                                Task {
                                    await taskStore.updateTask(
                                        task,
                                        title: taskTitle,
                                        category: selectedCategory,
                                        colorHex: selectedColor.toHex() ?? "#007AFF",
                                        priority: selectedPriority
                                    )
                                }
                                dismiss()
                            }
                        }) {
                            HStack {
                                Image(systemName: "checkmark")
                                Text("Update Task")
                                    .fontWeight(.semibold)
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color.infoBlue,
                                        Color.infoBlue.opacity(0.8)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: Color.infoBlue.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                        .disabled(taskTitle.isEmpty)
                        .opacity(taskTitle.isEmpty ? 0.6 : 1.0)
                        
                        // Delete Button
                        Button(action: {
                            showingDeleteAlert = true
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete Task")
                                    .fontWeight(.semibold)
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color.red,
                                        Color.red.opacity(0.8)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: Color.red.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
            .background(Color.secondaryBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
            }
            .alert("Delete Task", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    Task {
                        await taskStore.deleteTask(task)
                    }
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to delete this task? This action cannot be undone.")
            }
        }
    }
}

// MARK: - Clean Color Button
struct CleanColorButton: View {
    let color: Color
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Circle()
                .fill(color)
                .frame(width: 36, height: 36)
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.primary : Color.clear, lineWidth: 2)
                )
                .overlay(
                    SwiftUI.Group {
                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                    }
                )
                .scaleEffect(isSelected ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Clean Due Time Button
struct CleanDueTimeButton: View {
    let dueTime: TaskItem.TaskCategory
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: dueTimeIcon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected ? .white : Color(hex: dueTimeColor))
                
                Text(dueTime.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        isSelected ?
                        Color(hex: dueTimeColor) :
                        Color(hex: dueTimeColor).opacity(0.1)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        isSelected ? Color(hex: dueTimeColor) : Color.clear,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var dueTimeIcon: String {
        switch dueTime {
        case .today: return "sun.max"
        case .thisWeek: return "calendar.badge.clock"
        case .later: return "clock.arrow.circlepath"
        }
    }
    
    private var dueTimeColor: String {
        switch dueTime {
        case .today: return "#34C759"
        case .thisWeek: return "#FF9500"
        case .later: return "#007AFF"
        }
    }
}

// MARK: - Dragged Task Overlay
struct DraggedTaskOverlay: View {
    let task: TaskItem
    let dragOffset: CGSize
    
    var body: some View {
        HStack(spacing: 16) {
            // Enhanced completion toggle with better visual feedback
            ZStack {
                Circle()
                    .fill(task.isCompleted ? Color.successGreen : Color.clear)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Circle()
                            .stroke(
                                task.isCompleted ? Color.successGreen : Color(hex: task.colorHex).opacity(0.4),
                                lineWidth: 2.5
                            )
                    )
                    .shadow(
                        color: task.isCompleted ? Color.successGreen.opacity(0.3) : Color.clear,
                        radius: 4,
                        x: 0,
                        y: 2
                    )
                
                if task.isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            
            // Enhanced task content with better layout
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    Text(task.title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .strikethrough(task.isCompleted)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    // Enhanced priority badge with better styling
                    Text(task.priority.rawValue)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color(hex: task.priority.color))
                        )
                        .shadow(color: Color(hex: task.priority.color).opacity(0.3), radius: 2, x: 0, y: 1)
                }
                
                HStack {
                    // Enhanced category indicator
                    HStack(spacing: 6) {
                        Image(systemName: categoryIcon)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(hex: categoryColor))
                        
                        Text(task.category.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(hex: categoryColor).opacity(0.1))
                    )
                    
                    Spacer()
                }
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(hex: task.colorHex).opacity(0.3),
                                    Color(hex: task.colorHex).opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(
                    color: Color.black.opacity(0.15),
                    radius: 12,
                    x: 0,
                    y: 6
                )
        )
        .opacity(task.isCompleted ? 0.7 : 1.0)
        .scaleEffect(0.95) // Slightly smaller when dragging
        .rotationEffect(.degrees(1)) // Reduced rotation for visual feedback
        .offset(dragOffset)
        .allowsHitTesting(false) // Don't interfere with other interactions
    }
    
    private var categoryIcon: String {
        switch task.category {
        case .today: return "sun.max"
        case .thisWeek: return "calendar.badge.clock"
        case .later: return "clock.arrow.circlepath"
        }
    }
    
    private var categoryColor: String {
        switch task.category {
        case .today: return "#34C759"
        case .thisWeek: return "#FF9500"
        case .later: return "#007AFF"
        }
    }
}

// MARK: - Clean Priority Button
struct CleanPriorityButton: View {
    let priority: TaskItem.TaskPriority
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: priorityIcon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected ? .white : Color(hex: priority.color))
                
                Text(priority.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        isSelected ?
                        Color(hex: priority.color) :
                        Color(hex: priority.color).opacity(0.1)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        isSelected ? Color(hex: priority.color) : Color.clear,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var priorityIcon: String {
        switch priority {
        case .low:
            return "arrow.down.circle"
        case .medium:
            return "minus.circle"
        case .high:
            return "exclamationmark.triangle"
        }
    }
} 