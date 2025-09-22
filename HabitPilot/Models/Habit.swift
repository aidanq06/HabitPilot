import Foundation

// Weekday enum for flexible scheduling
enum Weekday: Int, CaseIterable, Codable, Equatable {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday
    
    var shortName: String {
        switch self {
        case .sunday: return "Sun"
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        }
    }
    
    static func today() -> Weekday {
        let weekday = Calendar.current.component(.weekday, from: Date())
        return Weekday(rawValue: weekday) ?? .monday
    }
}

// Frequency enum for flexible scheduling
enum HabitFrequency: String, CaseIterable, Codable {
    case daily = "Daily"
    case everyOtherDay = "Every Other Day"
    case threeTimesWeek = "3x per Week"
    case twiceWeek = "2x per Week"
    case onceWeek = "Once per Week"
    case custom = "Custom"
    
    var displayName: String {
        return self.rawValue
    }
    
    var description: String {
        switch self {
        case .daily:
            return "Every day"
        case .everyOtherDay:
            return "Every other day"
        case .threeTimesWeek:
            return "3 times per week"
        case .twiceWeek:
            return "2 times per week"
        case .onceWeek:
            return "Once per week"
        case .custom:
            return "Custom schedule"
        }
    }
    
    var icon: String {
        switch self {
        case .daily:
            return "calendar"
        case .everyOtherDay:
            return "calendar.badge.clock"
        case .threeTimesWeek:
            return "calendar.badge.plus"
        case .twiceWeek:
            return "calendar.badge.exclamationmark"
        case .onceWeek:
            return "calendar.badge.minus"
        case .custom:
            return "calendar.badge.gearshape"
        }
    }
}

// Add HabitType enum
enum HabitType: String, CaseIterable, Codable {
    case simple = "Simple"
    case incremental = "Incremental"
    
    var displayName: String {
        return self.rawValue
    }
    
    var typeDescription: String {
        switch self {
        case .simple:
            return "Complete once per day"
        case .incremental:
            return "Complete multiple times per day"
        }
    }
    
    var typeIcon: String {
        switch self {
        case .simple:
            return "checkmark.circle.fill"
        case .incremental:
            return "plus.circle.fill"
        }
    }
}

struct Habit: Identifiable, Codable {
    let id: UUID
    var name: String
    var description: String
    var notificationTime: Date?
    var isEnabled: Bool
    var streak: Int
    var lastCompletedDate: Date?
    var createdAt: Date
    var colorHex: String
    var scheduledDays: [Weekday] // Days of week this habit is active
    var reminderMessage: String // Custom reminder message
    var frequency: HabitFrequency // New: frequency of the habit
    var customFrequency: Int? // New: custom frequency (e.g., every X days)
    var multipleReminders: [Date] // New: multiple reminder times (premium feature)
    var type: HabitType // New: simple or incremental
    // Incremental habit support
    var dailyTarget: Int // How many times per day to complete (default 1)
    var todayProgress: Int // How many times completed today (reset daily)
    // Track if habit was completed today but then undone
    var wasCompletedToday: Bool // New: track if completed today but undone

    enum CodingKeys: String, CodingKey {
        case id, name, description, notificationTime, isEnabled, streak, lastCompletedDate, createdAt, colorHex, scheduledDays, reminderMessage, frequency, customFrequency, multipleReminders, type, dailyTarget, todayProgress, wasCompletedToday
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        notificationTime = try container.decodeIfPresent(Date.self, forKey: .notificationTime)
        isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
        streak = try container.decode(Int.self, forKey: .streak)
        lastCompletedDate = try container.decodeIfPresent(Date.self, forKey: .lastCompletedDate)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        colorHex = try container.decode(String.self, forKey: .colorHex)
        scheduledDays = try container.decodeIfPresent([Weekday].self, forKey: .scheduledDays) ?? Weekday.allCases
        reminderMessage = try container.decodeIfPresent(String.self, forKey: .reminderMessage) ?? "Time for your habit!"
        frequency = try container.decodeIfPresent(HabitFrequency.self, forKey: .frequency) ?? .daily
        customFrequency = try container.decodeIfPresent(Int.self, forKey: .customFrequency)
        multipleReminders = try container.decodeIfPresent([Date].self, forKey: .multipleReminders) ?? []
        type = try container.decodeIfPresent(HabitType.self, forKey: .type) ?? .simple
        dailyTarget = try container.decodeIfPresent(Int.self, forKey: .dailyTarget) ?? 1
        todayProgress = try container.decodeIfPresent(Int.self, forKey: .todayProgress) ?? 0
        wasCompletedToday = try container.decodeIfPresent(Bool.self, forKey: .wasCompletedToday) ?? false
    }

    init(name: String, description: String, notificationTime: Date, isEnabled: Bool = true, colorHex: String = "#007AFF", scheduledDays: [Weekday] = Weekday.allCases, reminderMessage: String = "Time for your habit!", frequency: HabitFrequency = .daily, customFrequency: Int? = nil, multipleReminders: [Date] = [], type: HabitType = .simple, dailyTarget: Int = 1, todayProgress: Int = 0) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.notificationTime = notificationTime
        self.isEnabled = isEnabled
        self.streak = 0
        self.lastCompletedDate = nil
        self.createdAt = Date()
        self.colorHex = colorHex
        self.scheduledDays = scheduledDays
        self.reminderMessage = reminderMessage
        self.frequency = frequency
        self.customFrequency = customFrequency
        self.multipleReminders = multipleReminders.isEmpty ? [notificationTime] : multipleReminders
        self.type = type
        self.dailyTarget = dailyTarget
        self.todayProgress = todayProgress
        self.wasCompletedToday = false
    }
    
    // For decoding with id
    init(id: UUID, name: String, description: String, notificationTime: Date, isEnabled: Bool, streak: Int, lastCompletedDate: Date?, createdAt: Date, colorHex: String, scheduledDays: [Weekday] = Weekday.allCases, reminderMessage: String = "Time for your habit!", frequency: HabitFrequency = .daily, customFrequency: Int? = nil, multipleReminders: [Date] = [], type: HabitType = .simple, dailyTarget: Int = 1, todayProgress: Int = 0) {
        self.id = id
        self.name = name
        self.description = description
        self.notificationTime = notificationTime
        self.isEnabled = isEnabled
        self.streak = streak
        self.lastCompletedDate = lastCompletedDate
        self.createdAt = createdAt
        self.colorHex = colorHex
        self.scheduledDays = scheduledDays
        self.reminderMessage = reminderMessage
        self.frequency = frequency
        self.customFrequency = customFrequency
        self.multipleReminders = multipleReminders.isEmpty ? [notificationTime] : multipleReminders
        self.type = type
        self.dailyTarget = dailyTarget
        self.todayProgress = todayProgress
        self.wasCompletedToday = false
    }
    
    mutating func markCompleted() {
        let today = Calendar.current.startOfDay(for: Date())
        let oldStreak = streak
        
        // Check if this is a re-completion of today (after an undo)
        if wasCompletedToday && lastCompletedDate == nil {
            // Re-completing after undo - restore the streak to what it was before undo
            streak = max(1, oldStreak + 1)
            print("📝 Re-completing after undo: \(oldStreak) -> \(streak)")
            lastCompletedDate = Date()
            wasCompletedToday = true
            return
        }
        
        if let lastCompleted = lastCompletedDate {
            let lastCompletedDay = Calendar.current.startOfDay(for: lastCompleted)
            
            if Calendar.current.isDate(today, inSameDayAs: lastCompletedDay) {
                // Already completed today - don't increment streak again
                print("📝 Already completed today, not incrementing streak")
                return
            }
            
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
            if Calendar.current.isDate(lastCompletedDay, inSameDayAs: yesterday) {
                // Consecutive day
                streak += 1
                print("📝 Consecutive day completion: \(oldStreak) -> \(streak)")
            } else {
                // Check if this completion follows the frequency pattern
                if isCompletionValid() {
                    streak += 1
                    print("📝 Frequency-valid completion: \(oldStreak) -> \(streak)")
                } else {
                    // Break in streak due to frequency
                    streak = 1
                    print("📝 Break in streak, resetting to 1")
                }
            }
        } else {
            // First completion
            streak = 1
            print("📝 First completion, setting streak to 1")
        }
        
        lastCompletedDate = Date()
        wasCompletedToday = true
    }
    
    // Call this to increment progress for today
    mutating func incrementProgress() {
        print("📈 Incrementing progress: Current progress \(todayProgress)/\(dailyTarget), completed today: \(isCompletedToday())")
        
        if type == .incremental {
            // Only reset if we haven't made any progress today
            if todayProgress == 0 {
                resetProgressIfNeeded()
            }
            
            if todayProgress < dailyTarget {
                todayProgress += 1
                print("📈 Progress incremented to \(todayProgress)/\(dailyTarget)")
                
                if todayProgress == dailyTarget {
                    // Only mark completed if not already completed today
                    if !isCompletedToday() {
                        print("📈 Target reached, marking completed")
                        markCompleted()
                    } else {
                        print("📈 Target reached but already completed today, skipping markCompleted")
                    }
                }
            } else {
                print("📈 Already at target, not incrementing")
            }
        } else {
            // For simple habits, only mark completed if not already completed today
            if !isCompletedToday() {
                print("📈 Simple habit, marking completed")
                markCompleted()
            } else {
                print("📈 Simple habit already completed today, skipping markCompleted")
            }
        }
    }

    // Returns true if today's target is reached
    func isCompletedToday() -> Bool {
        if type == .incremental {
            return todayProgress >= dailyTarget
        } else {
            guard let lastCompleted = lastCompletedDate else { return false }
            return Calendar.current.isDateInToday(lastCompleted)
        }
    }
    
    // Computed properties for better performance
    var progressFraction: Double {
        if type == .incremental {
            guard dailyTarget > 0 else { return 0 }
            return Double(todayProgress) / Double(dailyTarget)
        } else {
            return isCompletedToday() ? 1.0 : 0.0
        }
    }
    
    var isAtTarget: Bool {
        if type == .incremental {
            return todayProgress >= dailyTarget
        } else {
            return isCompletedToday()
        }
    }
    
    var canIncrement: Bool {
        type == .incremental && todayProgress < dailyTarget
    }

    // Resets todayProgress if the day has changed
    mutating func resetProgressIfNeeded() {
        let calendar = Calendar.current
        
        // Reset wasCompletedToday flag if we're on a new day
        if let lastCompleted = lastCompletedDate {
            let isLastCompletedToday = calendar.isDateInToday(lastCompleted)
            if !isLastCompletedToday {
                wasCompletedToday = false
            }
        } else {
            // If no lastCompletedDate, reset wasCompletedToday flag
            wasCompletedToday = false
        }
        
        // For incremental habits, only reset if we're on a new day
        if type == .incremental {
            // Only reset if we have a lastCompletedDate and it's from a different day
            if let lastCompleted = lastCompletedDate {
                let isLastCompletedToday = calendar.isDateInToday(lastCompleted)
                
                if !isLastCompletedToday {
                    todayProgress = 0
                }
            }
        }
    }
    
    // Check if this habit is scheduled for today
    func isScheduledForToday() -> Bool {
        scheduledDays.contains(Weekday.today())
    }
    
    // Check if completion is valid based on frequency
    func isCompletionValid() -> Bool {
        guard let lastCompleted = lastCompletedDate else { return true }
        
        let calendar = Calendar.current
        let today = Date()
        let daysSinceLastCompletion = calendar.dateComponents([.day], from: lastCompleted, to: today).day ?? 0
        
        switch frequency {
        case .daily:
            return daysSinceLastCompletion <= 1
        case .everyOtherDay:
            return daysSinceLastCompletion <= 2
        case .threeTimesWeek:
            return daysSinceLastCompletion <= 3
        case .twiceWeek:
            return daysSinceLastCompletion <= 4
        case .onceWeek:
            return daysSinceLastCompletion <= 7
        case .custom:
            guard let customFreq = customFrequency else { return true }
            return daysSinceLastCompletion <= customFreq
        }
    }
    
    // Get next scheduled date based on frequency
    func getNextScheduledDate() -> Date? {
        guard let lastCompleted = lastCompletedDate else { return Date() }
        
        let calendar = Calendar.current
        var nextDate = lastCompleted
        
        switch frequency {
        case .daily:
            nextDate = calendar.date(byAdding: .day, value: 1, to: lastCompleted) ?? lastCompleted
        case .everyOtherDay:
            nextDate = calendar.date(byAdding: .day, value: 2, to: lastCompleted) ?? lastCompleted
        case .threeTimesWeek:
            nextDate = calendar.date(byAdding: .day, value: 2, to: lastCompleted) ?? lastCompleted
        case .twiceWeek:
            nextDate = calendar.date(byAdding: .day, value: 3, to: lastCompleted) ?? lastCompleted
        case .onceWeek:
            nextDate = calendar.date(byAdding: .day, value: 7, to: lastCompleted) ?? lastCompleted
        case .custom:
            guard let customFreq = customFrequency else { return Date() }
            nextDate = calendar.date(byAdding: .day, value: customFreq, to: lastCompleted) ?? lastCompleted
        }
        
        return nextDate
    }
    
    // Get frequency description for display
    func getFrequencyDescription() -> String {
        switch frequency {
        case .daily:
            return "Every day"
        case .everyOtherDay:
            return "Every other day"
        case .threeTimesWeek:
            return "3 times per week"
        case .twiceWeek:
            return "2 times per week"
        case .onceWeek:
            return "Once per week"
        case .custom:
            if let customFreq = customFrequency {
                return "Every \(customFreq) days"
            }
            return "Custom schedule"
        }
    }
    
    // Check if habit should be active today based on frequency
    func shouldBeActiveToday() -> Bool {
        guard isScheduledForToday() else { return false }
        
        if let lastCompleted = lastCompletedDate {
            let calendar = Calendar.current
            let today = Date()
            let daysSinceLastCompletion = calendar.dateComponents([.day], from: lastCompleted, to: today).day ?? 0
            
            switch frequency {
            case .daily:
                return true
            case .everyOtherDay:
                return daysSinceLastCompletion >= 2
            case .threeTimesWeek:
                return daysSinceLastCompletion >= 2
            case .twiceWeek:
                return daysSinceLastCompletion >= 3
            case .onceWeek:
                return daysSinceLastCompletion >= 7
            case .custom:
                guard let customFreq = customFrequency else { return true }
                return daysSinceLastCompletion >= customFreq
            }
        }
        
        return true
    }
    
    mutating func undoCompletedToday() {
        guard let lastCompleted = lastCompletedDate, Calendar.current.isDateInToday(lastCompleted) else { 
            print("📝 Cannot undo: No completion today or not completed today")
            return 
        }
        
        let oldStreak = streak
        
        // Remove today's completion but mark that it was completed today
        lastCompletedDate = nil
        wasCompletedToday = true // Keep this true to track that it was completed today
        
        // For incremental habits, also reset today's progress
        if type == .incremental {
            todayProgress = 0
        }
        
        // Decrement streak, but not below 0
        // This ensures we don't go negative and properly handle undo
        if streak > 0 {
            streak = max(0, streak - 1)
            print("📝 Undoing completion: \(oldStreak) -> \(streak)")
        } else {
            print("📝 Undoing completion: Streak already at 0, not decrementing")
        }
    }
}

// MARK: - AI Suggested Habit Model
struct SuggestedHabit: Identifiable, Codable {
    let id: UUID
    var name: String
    var description: String
    var reasoning: String // Why this habit is suggested
    var category: String // e.g., "Health", "Productivity", "Mindfulness"
    var difficulty: Difficulty // Easy, Medium, Hard
    var frequency: HabitFrequency
    var type: HabitType
    var dailyTarget: Int
    var colorHex: String
    var estimatedTimeMinutes: Int
    var benefits: [String] // Array of expected benefits
    var isDismissed: Bool // Track if user has dismissed this suggestion
    var createdAt: Date
    
    enum Difficulty: String, CaseIterable, Codable {
        case easy = "Easy"
        case medium = "Medium" 
        case hard = "Hard"
        
        var color: String {
            switch self {
            case .easy: return "#4CAF50"    // Green
            case .medium: return "#FF9800"  // Orange
            case .hard: return "#F44336"    // Red
            }
        }
        
        var icon: String {
            switch self {
            case .easy: return "leaf.fill"
            case .medium: return "flame.fill"
            case .hard: return "bolt.fill"
            }
        }
    }
    
    init(name: String, description: String, reasoning: String, category: String, difficulty: Difficulty = .medium, frequency: HabitFrequency = .daily, type: HabitType = .simple, dailyTarget: Int = 1, colorHex: String = "#007AFF", estimatedTimeMinutes: Int = 15, benefits: [String] = []) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.reasoning = reasoning
        self.category = category
        self.difficulty = difficulty
        self.frequency = frequency
        self.type = type
        self.dailyTarget = dailyTarget
        self.colorHex = colorHex
        self.estimatedTimeMinutes = estimatedTimeMinutes
        self.benefits = benefits
        self.isDismissed = false
        self.createdAt = Date()
    }
    
    // Convert to actual Habit
    func toHabit() -> Habit {
        return Habit(
            name: name,
            description: description,
            notificationTime: Date(),
            isEnabled: true,
            colorHex: colorHex,
            scheduledDays: Weekday.allCases,
            reminderMessage: "Time for your \(name.lowercased())!",
            frequency: frequency,
            type: type,
            dailyTarget: dailyTarget
        )
    }
}

// MARK: - Contextual Suggestion System Models

enum SuggestionPriority: String, CaseIterable, Codable {
    case low = "low"
    case medium = "medium" 
    case high = "high"
}

enum SuggestionTimingType: String, CaseIterable, Codable {
    case now = "now"
    case laterToday = "later_today"
    case tomorrow = "tomorrow"
    case nextWeek = "next_week"
}

enum EngagementLevel: String, CaseIterable, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case veryHigh = "very_high"
}

struct SuggestionContext: Codable {
    let contentType: ContentType
    let existingCount: Int
    let recentCompletions: Int // Percentage
    let daysSinceLastSuggestion: Int
    let engagementLevel: EngagementLevel
    let timeOfDay: String
    let dayOfWeek: String
    
    enum ContentType: String, CaseIterable, Codable {
        case habit = "Habit"
        case task = "Task"
        case goal = "Goal"
    }
    
    init(contentType: ContentType, existingCount: Int, recentCompletions: Int, daysSinceLastSuggestion: Int, engagementLevel: EngagementLevel) {
        self.contentType = contentType
        self.existingCount = existingCount
        self.recentCompletions = recentCompletions
        self.daysSinceLastSuggestion = daysSinceLastSuggestion
        self.engagementLevel = engagementLevel
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        self.timeOfDay = formatter.string(from: Date())
        
        formatter.dateFormat = "EEEE"
        self.dayOfWeek = formatter.string(from: Date())
    }
}

struct SuggestionTiming: Codable {
    let shouldShow: Bool
    let reason: String
    let priority: SuggestionPriority
    let timing: SuggestionTimingType
    let context: SuggestionContext
    let timestamp: Date
    
    init(shouldShow: Bool, reason: String, priority: SuggestionPriority, timing: SuggestionTimingType, context: SuggestionContext) {
        self.shouldShow = shouldShow
        self.reason = reason
        self.priority = priority
        self.timing = timing
        self.context = context
        self.timestamp = Date()
    }
}

// Unified suggestion item that can represent habits, tasks, or goals
enum SuggestedItem: Codable {
    case habit(SuggestedHabit)
    case task(SuggestedTask)
    case goal(SuggestedGoal)
    
    var id: UUID {
        switch self {
        case .habit(let habit): return habit.id
        case .task(let task): return task.id
        case .goal(let goal): return goal.id
        }
    }
    
    var name: String {
        switch self {
        case .habit(let habit): return habit.name
        case .task(let task): return task.title
        case .goal(let goal): return goal.title
        }
    }
    
    var reasoning: String {
        switch self {
        case .habit(let habit): return habit.reasoning
        case .task(let task): return task.reasoning
        case .goal(let goal): return goal.reasoning
        }
    }
    
    var colorHex: String {
        switch self {
        case .habit(let habit): return habit.colorHex
        case .task(let task): return task.colorHex
        case .goal(let goal): return goal.colorHex
        }
    }
}

// MARK: - Suggested Task Model
struct SuggestedTask: Identifiable, Codable {
    let id: UUID
    var title: String
    var description: String
    var reasoning: String
    var category: String
    var priority: TaskPriority
    var estimatedTimeMinutes: Int
    var benefits: [String]
    var colorHex: String
    var isDismissed: Bool
    var createdAt: Date
    
    enum TaskPriority: String, CaseIterable, Codable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        
        var color: String {
            switch self {
            case .low: return "#4CAF50"
            case .medium: return "#FF9800"
            case .high: return "#F44336"
            }
        }
    }
    
    init(title: String, description: String, reasoning: String, category: String, priority: TaskPriority = .medium, estimatedTimeMinutes: Int = 30, benefits: [String] = [], colorHex: String = "#2196F3") {
        self.id = UUID()
        self.title = title
        self.description = description
        self.reasoning = reasoning
        self.category = category
        self.priority = priority
        self.estimatedTimeMinutes = estimatedTimeMinutes
        self.benefits = benefits
        self.colorHex = colorHex
        self.isDismissed = false
        self.createdAt = Date()
    }
}

// MARK: - Suggested Goal Model
struct SuggestedGoal: Identifiable, Codable {
    let id: UUID
    var title: String
    var description: String
    var reasoning: String
    var category: String
    var timeframe: String
    var difficulty: GoalDifficulty
    var benefits: [String]
    var colorHex: String
    var isDismissed: Bool
    var createdAt: Date
    
    enum GoalDifficulty: String, CaseIterable, Codable {
        case easy = "Easy"
        case medium = "Medium"
        case hard = "Hard"
        
        var color: String {
            switch self {
            case .easy: return "#4CAF50"
            case .medium: return "#FF9800"
            case .hard: return "#F44336"
            }
        }
    }
    
    init(title: String, description: String, reasoning: String, category: String, timeframe: String = "1 month", difficulty: GoalDifficulty = .medium, benefits: [String] = [], colorHex: String = "#9C27B0") {
        self.id = UUID()
        self.title = title
        self.description = description
        self.reasoning = reasoning
        self.category = category
        self.timeframe = timeframe
        self.difficulty = difficulty
        self.benefits = benefits
        self.colorHex = colorHex
        self.isDismissed = false
        self.createdAt = Date()
    }
} 