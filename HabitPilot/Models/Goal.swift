import Foundation

struct Goal: Identifiable, Codable {
    let id: UUID
    var title: String
    var description: String
    var isCompleted: Bool
    var createdAt: Date
    var completedDate: Date?
    var category: GoalCategory
    var priority: GoalPriority
    var goalType: GoalType
    var targetValue: Int
    var currentProgress: Int
    var deadline: Date?
    var linkedHabitID: UUID?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case isCompleted = "is_completed"
        case createdAt = "created_at"
        case completedDate = "completed_date"
        case category
        case priority
        case goalType = "goal_type"
        case targetValue = "target_value"
        case currentProgress = "current_progress"
        case deadline
        case linkedHabitID = "linked_habit_id"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Decode UUID from string
        let idString = try container.decode(String.self, forKey: .id)
        guard let uuid = UUID(uuidString: idString) else {
            throw DecodingError.dataCorruptedError(forKey: .id, in: container, debugDescription: "Invalid UUID string for id")
        }
        id = uuid
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        completedDate = try? container.decodeIfPresent(Date.self, forKey: .completedDate)
        category = try container.decode(GoalCategory.self, forKey: .category)
        priority = try container.decode(GoalPriority.self, forKey: .priority)
        goalType = try container.decode(GoalType.self, forKey: .goalType)
        targetValue = try container.decode(Int.self, forKey: .targetValue)
        currentProgress = try container.decode(Int.self, forKey: .currentProgress)
        deadline = try? container.decodeIfPresent(Date.self, forKey: .deadline)
        // linkedHabitID is optional and may be null or a string
        if let idString = try? container.decodeIfPresent(String.self, forKey: .linkedHabitID),
           let linkedUUID = UUID(uuidString: idString) {
            linkedHabitID = linkedUUID
        } else {
            linkedHabitID = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id.uuidString, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(isCompleted, forKey: .isCompleted)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(completedDate, forKey: .completedDate)
        try container.encode(category, forKey: .category)
        try container.encode(priority, forKey: .priority)
        try container.encode(goalType, forKey: .goalType)
        try container.encode(targetValue, forKey: .targetValue)
        try container.encode(currentProgress, forKey: .currentProgress)
        try container.encodeIfPresent(deadline, forKey: .deadline)
        try container.encodeIfPresent(linkedHabitID?.uuidString, forKey: .linkedHabitID)
    }
    
    enum GoalCategory: String, CaseIterable, Codable {
        case personal = "Personal"
        case health = "Health"
        case career = "Career"
        case learning = "Learning"
        case financial = "Financial"
        case other = "Other"
        
        var icon: String {
            switch self {
            case .personal: return "person.fill"
            case .health: return "heart.fill"
            case .career: return "briefcase.fill"
            case .learning: return "book.fill"
            case .financial: return "dollarsign.circle.fill"
            case .other: return "star.fill"
            }
        }
        
        var color: String {
            switch self {
            case .personal: return "#007AFF"
            case .health: return "#34C759"
            case .career: return "#FF9500"
            case .learning: return "#AF52DE"
            case .financial: return "#FFD60A"
            case .other: return "#FF3B30"
            }
        }
    }
    
    enum GoalPriority: String, CaseIterable, Codable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        
        var color: String {
            switch self {
            case .low: return "#34C759"
            case .medium: return "#FF9500"
            case .high: return "#FF3B30"
            }
        }
        
        var sortOrder: Int {
            switch self {
            case .high: return 0
            case .medium: return 1
            case .low: return 2
            }
        }
    }
    
    enum GoalType: String, CaseIterable, Codable {
        case simple = "Simple"
        case measurable = "Measurable"
        case habit = "Habit"
        
        var displayName: String {
            switch self {
            case .simple: return "Simple Goal"
            case .measurable: return "Measurable Goal"
            case .habit: return "Habit Goal"
            }
        }
        
        var description: String {
            switch self {
            case .simple: return "Just complete it"
            case .measurable: return "Track progress to a target"
            case .habit: return "Repeat an action X times"
            }
        }
    }
    
    init(title: String, description: String, category: GoalCategory = .other, priority: GoalPriority = .medium, goalType: GoalType = .simple, targetValue: Int = 1, deadline: Date? = nil, linkedHabitID: UUID? = nil) {
        self.id = UUID()
        self.title = title
        self.description = description
        self.isCompleted = false
        self.createdAt = Date()
        self.completedDate = nil
        self.category = category
        self.priority = priority
        self.goalType = goalType
        self.targetValue = targetValue
        self.currentProgress = 0
        self.deadline = deadline
        self.linkedHabitID = linkedHabitID
    }
    
    var progressPercentage: Double {
        guard targetValue > 0 else { return 0 }
        return min(Double(currentProgress) / Double(targetValue), 1.0)
    }
    
    var progressText: String {
        switch goalType {
        case .simple:
            return isCompleted ? "Completed" : "In Progress"
        case .measurable:
            return "\(currentProgress)/\(targetValue)"
        case .habit:
            return "\(currentProgress)/\(targetValue) times"
        }
    }
    
    var deadlineISO8601: String? {
        deadline?.iso8601String()
    }
    var completedDateISO8601: String? {
        completedDate?.iso8601String()
    }
    
    mutating func toggleCompletion() {
        isCompleted.toggle()
        completedDate = isCompleted ? Date() : nil
        if isCompleted && goalType == .simple {
            currentProgress = 1
        } else if !isCompleted {
            // Reset progress when marking as incomplete
            currentProgress = 0
        }
    }
    
    mutating func updateProgress(_ newProgress: Int) {
        currentProgress = max(0, min(newProgress, targetValue))
        if currentProgress >= targetValue {
            isCompleted = true
            completedDate = Date()
        } else {
            // Mark as incomplete if progress is less than target
            isCompleted = false
            completedDate = nil
        }
    }
    
    mutating func incrementProgress() {
        updateProgress(currentProgress + 1)
    }
}

extension Date {
    func iso8601String() -> String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: self)
    }
} 