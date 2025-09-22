import Foundation

struct User: Codable, Identifiable, Equatable {
    let id: String
    let username: String
    let email: String?
    let createdAt: Date
    let lastLoginAt: Date
    let isAppleUser: Bool
    let profilePicture: String?
    let privacyPolicyAcceptedAt: Date?
    let termsOfServiceAcceptedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case email
        case createdAt = "created_at"
        case lastLoginAt = "last_login_at"
        case isAppleUser = "is_apple_user"
        case profilePicture = "profile_picture"
        case privacyPolicyAcceptedAt = "privacy_policy_accepted_at"
        case termsOfServiceAcceptedAt = "terms_of_service_accepted_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        username = try container.decode(String.self, forKey: .username)
        email = try? container.decodeIfPresent(String.self, forKey: .email)
        profilePicture = try? container.decodeIfPresent(String.self, forKey: .profilePicture)
        
        // Handle isAppleUser as Int or Bool
        if let boolValue = try? container.decode(Bool.self, forKey: .isAppleUser) {
            isAppleUser = boolValue
        } else if let intValue = try? container.decode(Int.self, forKey: .isAppleUser) {
            isAppleUser = intValue != 0
        } else {
            isAppleUser = false
        }
        
        // Handle ISO8601 date strings
        let dateString = try container.decode(String.self, forKey: .createdAt)
        let lastLoginString = try container.decode(String.self, forKey: .lastLoginAt)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let created = formatter.date(from: dateString),
              let lastLogin = formatter.date(from: lastLoginString) else {
            throw DecodingError.dataCorruptedError(forKey: .createdAt, in: container, debugDescription: "Date string does not match format expected by formatter.")
        }
        createdAt = created
        lastLoginAt = lastLogin
        
        // Handle privacy consent dates (optional)
        if let privacyDateString = try? container.decodeIfPresent(String.self, forKey: .privacyPolicyAcceptedAt),
           let privacyDate = formatter.date(from: privacyDateString) {
            privacyPolicyAcceptedAt = privacyDate
        } else {
            privacyPolicyAcceptedAt = nil
        }
        
        if let termsDateString = try? container.decodeIfPresent(String.self, forKey: .termsOfServiceAcceptedAt),
           let termsDate = formatter.date(from: termsDateString) {
            termsOfServiceAcceptedAt = termsDate
        } else {
            termsOfServiceAcceptedAt = nil
        }
    }

    init(id: String, username: String, email: String?, createdAt: Date, lastLoginAt: Date, isAppleUser: Bool, profilePicture: String? = nil, privacyPolicyAcceptedAt: Date? = nil, termsOfServiceAcceptedAt: Date? = nil) {
        self.id = id
        self.username = username
        self.email = email
        self.createdAt = createdAt
        self.lastLoginAt = lastLoginAt
        self.isAppleUser = isAppleUser
        self.profilePicture = profilePicture
        self.privacyPolicyAcceptedAt = privacyPolicyAcceptedAt
        self.termsOfServiceAcceptedAt = termsOfServiceAcceptedAt
    }
    
    mutating func updateLastLogin() {
        // Note: This would need to be handled differently in a real implementation
        // since structs are value types. For now, we'll create a new instance.
    }
    
    var hasAcceptedCurrentTerms: Bool {
        // Consider terms accepted if both privacy policy and terms of service have been accepted
        // In a real implementation, you might want to check against specific version dates
        return privacyPolicyAcceptedAt != nil && termsOfServiceAcceptedAt != nil
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(username, forKey: .username)
        try container.encodeIfPresent(email, forKey: .email)
        try container.encodeIfPresent(profilePicture, forKey: .profilePicture)
        try container.encode(isAppleUser, forKey: .isAppleUser)
        
        // Encode dates as ISO8601 strings
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        try container.encode(formatter.string(from: createdAt), forKey: .createdAt)
        try container.encode(formatter.string(from: lastLoginAt), forKey: .lastLoginAt)
        
        // Encode privacy consent dates if present
        if let privacyDate = privacyPolicyAcceptedAt {
            try container.encode(formatter.string(from: privacyDate), forKey: .privacyPolicyAcceptedAt)
        }
        if let termsDate = termsOfServiceAcceptedAt {
            try container.encode(formatter.string(from: termsDate), forKey: .termsOfServiceAcceptedAt)
        }
    }
}

// MARK: - User Authentication State
enum AuthState: Equatable {
    case notAuthenticated
    case authenticating
    case authenticated(User)
    case error(String)
    
    static func == (lhs: AuthState, rhs: AuthState) -> Bool {
        switch (lhs, rhs) {
        case (.notAuthenticated, .notAuthenticated),
             (.authenticating, .authenticating):
            return true
        case let (.authenticated(lhsUser), .authenticated(rhsUser)):
            return lhsUser.id == rhsUser.id
        case let (.error(lhsError), .error(rhsError)):
            return lhsError == rhsError
        default:
            return false
        }
    }
}

// MARK: - User Statistics
struct UserStatistics: Codable {
    let userId: String
    let currentStreak: Int
    let activeChallengesCount: Int
    let lastActivityDate: Date?
    
    enum CodingKeys: String, CodingKey {
        case userId
        case currentStreak
        case activeChallengesCount
        case lastActivityDate
    }
    
    init(userId: String, currentStreak: Int, activeChallengesCount: Int, lastActivityDate: Date?) {
        self.userId = userId
        self.currentStreak = currentStreak
        self.activeChallengesCount = activeChallengesCount
        self.lastActivityDate = lastActivityDate
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        userId = try container.decode(String.self, forKey: .userId)
        currentStreak = try container.decode(Int.self, forKey: .currentStreak)
        activeChallengesCount = try container.decode(Int.self, forKey: .activeChallengesCount)
        
        // Handle date decoding
        if let dateString = try? container.decode(String.self, forKey: .lastActivityDate) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            lastActivityDate = formatter.date(from: dateString)
        } else {
            lastActivityDate = nil
        }
    }
    
    var lastActivityDescription: String {
        guard let lastActivity = lastActivityDate else {
            return "No recent activity"
        }
        
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day], from: lastActivity, to: now)
        
        if let days = components.day, days > 0 {
            return days == 1 ? "Last active 1 day ago" : "Last active \(days) days ago"
        } else if let hours = components.hour, hours > 0 {
            return hours == 1 ? "Last active 1 hour ago" : "Last active \(hours) hours ago"
        } else if let minutes = components.minute, minutes > 0 {
            return minutes == 1 ? "Last active 1 minute ago" : "Last active \(minutes) minutes ago"
        } else {
            return "Active now"
        }
    }
} 