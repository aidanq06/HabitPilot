import Foundation

struct Friend: Codable, Identifiable {
    let id: String
    let userId: String
    let friendId: String
    let friendUsername: String
    let profilePicture: String?
    let status: FriendStatus
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case friendId
        case friendUsername
        case profilePicture
        case status
        case createdAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        friendId = try container.decode(String.self, forKey: .friendId)
        friendUsername = try container.decode(String.self, forKey: .friendUsername)
        profilePicture = try container.decodeIfPresent(String.self, forKey: .profilePicture)
        status = try container.decode(FriendStatus.self, forKey: .status)
        let dateString = try container.decode(String.self, forKey: .createdAt)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let created = formatter.date(from: dateString) else {
            throw DecodingError.dataCorruptedError(forKey: .createdAt, in: container, debugDescription: "Date string does not match format expected by formatter.")
        }
        createdAt = created
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(friendId, forKey: .friendId)
        try container.encode(friendUsername, forKey: .friendUsername)
        try container.encodeIfPresent(profilePicture, forKey: .profilePicture)
        try container.encode(status, forKey: .status)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        try container.encode(formatter.string(from: createdAt), forKey: .createdAt)
    }
    
    init(userId: String, friendId: String, friendUsername: String, profilePicture: String? = nil, status: FriendStatus = .pending) {
        self.id = UUID().uuidString
        self.userId = userId
        self.friendId = friendId
        self.friendUsername = friendUsername
        self.profilePicture = profilePicture
        self.status = status
        self.createdAt = Date()
    }
}

enum FriendStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case accepted = "accepted"
    case declined = "declined"
    case blocked = "blocked"
    
    var displayName: String {
        switch self {
        case .pending:
            return "Pending"
        case .accepted:
            return "Accepted"
        case .declined:
            return "Declined"
        case .blocked:
            return "Blocked"
        }
    }
    
    var color: String {
        switch self {
        case .pending:
            return "orange"
        case .accepted:
            return "green"
        case .declined:
            return "red"
        case .blocked:
            return "gray"
        }
    }
}

struct FriendRequest: Codable, Identifiable {
    let id: String
    let fromUserId: String
    let fromUsername: String
    let toUserId: String
    let toUsername: String
    let message: String?
    let createdAt: Date
    let status: FriendRequestStatus
    
    enum CodingKeys: String, CodingKey {
        case id
        case fromUserId
        case fromUsername
        case toUserId
        case toUsername
        case message
        case createdAt
        case status
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        fromUserId = try container.decode(String.self, forKey: .fromUserId)
        fromUsername = try container.decode(String.self, forKey: .fromUsername)
        toUserId = try container.decode(String.self, forKey: .toUserId)
        toUsername = try container.decode(String.self, forKey: .toUsername)
        message = try? container.decodeIfPresent(String.self, forKey: .message)
        let dateString = try container.decode(String.self, forKey: .createdAt)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let created = formatter.date(from: dateString) else {
            throw DecodingError.dataCorruptedError(forKey: .createdAt, in: container, debugDescription: "Date string does not match format expected by formatter.")
        }
        createdAt = created
        status = try container.decode(FriendRequestStatus.self, forKey: .status)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(fromUserId, forKey: .fromUserId)
        try container.encode(fromUsername, forKey: .fromUsername)
        try container.encode(toUserId, forKey: .toUserId)
        try container.encode(toUsername, forKey: .toUsername)
        try container.encodeIfPresent(message, forKey: .message)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        try container.encode(formatter.string(from: createdAt), forKey: .createdAt)
        try container.encode(status, forKey: .status)
    }
    
    init(fromUserId: String, fromUsername: String, toUserId: String, toUsername: String, message: String? = nil) {
        self.id = UUID().uuidString
        self.fromUserId = fromUserId
        self.fromUsername = fromUsername
        self.toUserId = toUserId
        self.toUsername = toUsername
        self.message = message
        self.createdAt = Date()
        self.status = .pending
    }
}

enum FriendRequestStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case accepted = "accepted"
    case declined = "declined"
    
    var displayName: String {
        switch self {
        case .pending:
            return "Pending"
        case .accepted:
            return "Accepted"
        case .declined:
            return "Declined"
        }
    }
}

struct FriendRequestResponse: Codable {
    let request: FriendRequest
    let message: String
    
    enum CodingKeys: String, CodingKey {
        case request
        case message
    }
}

// Simplified response for accept/decline operations
struct FriendRequestActionResponse: Codable {
    let request: SimpleFriendRequest
    let message: String
    
    struct SimpleFriendRequest: Codable {
        let id: String
        let status: String
    }
}

struct FriendRequestAPIResponse: Codable {
    let success: Bool
    let data: FriendRequestResponse
    
    enum CodingKeys: String, CodingKey {
        case success
        case data
    }
}

struct FriendsResponse: Codable {
    let friends: [Friend]
    let requests: [FriendRequest]
    let outgoingRequests: [FriendRequest]
} 