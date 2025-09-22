import Foundation

struct APIConfig {
    static let baseURL = "https://api.example.com"
    static let requestTimeout: TimeInterval = 30

    struct Endpoints {
        static let habits = "/habits"
        static let goals = "/goals"
        static let friends = "/friends"
    }
} 