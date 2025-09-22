import Foundation

struct TaskItem: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var description: String
    var category: TaskCategory
    var topicCategory: TaskTopicCategory
    var isCompleted: Bool
    let createdAt: Date
    var colorHex: String
    var priority: TaskPriority
    var estimatedDuration: TimeInterval // in minutes
    var deadline: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case category
        case topicCategory = "topic_category"
        case isCompleted = "is_completed"
        case createdAt = "created_at"
        case colorHex = "color_hex"
        case priority
        case estimatedDuration = "estimated_duration"
        case deadline
    }
    
    enum TaskCategory: String, CaseIterable, Codable {
        case today = "Today"
        case thisWeek = "This week"
        case later = "Later"
        
        var icon: String {
            switch self {
            case .today: return "clock.fill"
            case .thisWeek: return "calendar"
            case .later: return "calendar.badge.plus"
            }
        }
        
        var color: String {
            switch self {
            case .today: return "#FF3B30"
            case .thisWeek: return "#FF9500"
            case .later: return "#34C759"
            }
        }
        
        var displayName: String {
            return self.rawValue
        }
    }
    
    enum TaskTopicCategory: String, CaseIterable, Codable {
        case work = "Work"
        case personal = "Personal"
        case health = "Health"
        case learning = "Learning"
        case financial = "Financial"
        case other = "Other"
        
        var icon: String {
            switch self {
            case .work: return "briefcase.fill"
            case .personal: return "person.fill"
            case .health: return "heart.fill"
            case .learning: return "book.fill"
            case .financial: return "dollarsign.circle.fill"
            case .other: return "star.fill"
            }
        }
        
        var color: String {
            switch self {
            case .work: return "#FF9500"
            case .personal: return "#007AFF"
            case .health: return "#34C759"
            case .learning: return "#AF52DE"
            case .financial: return "#FFD60A"
            case .other: return "#FF3B30"
            }
        }
    }
    
    enum TaskPriority: String, CaseIterable, Codable {
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
        
        var icon: String {
            switch self {
            case .low: return "arrow.down.circle.fill"
            case .medium: return "minus.circle.fill"
            case .high: return "exclamationmark.triangle.fill"
            }
        }
        
        var displayName: String {
            return self.rawValue
        }
        
        var description: String {
            switch self {
            case .low: return "Not urgent, can be done later"
            case .medium: return "Important but not critical"
            case .high: return "Urgent, needs immediate attention"
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
    
    init(title: String, description: String = "", category: TaskCategory = .today, topicCategory: TaskTopicCategory = .other, isCompleted: Bool = false, colorHex: String = "#007AFF", priority: TaskPriority = .medium, estimatedDuration: TimeInterval = 30, deadline: Date? = nil) {
        self.id = UUID()
        self.title = title
        self.description = description
        self.category = category
        self.topicCategory = topicCategory
        self.isCompleted = isCompleted
        self.createdAt = Date()
        self.colorHex = colorHex
        self.priority = priority
        self.estimatedDuration = estimatedDuration
        self.deadline = deadline
    }
} 