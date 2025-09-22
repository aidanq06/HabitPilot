import Foundation
import AuthenticationServices
import CryptoKit
import SwiftUI

// MARK: - Notification Names
extension Notification.Name {
    static let userDidLogin = Notification.Name("userDidLogin")
    static let userDidLogout = Notification.Name("userDidLogout")
    static let shouldRefreshHabits = Notification.Name("shouldRefreshHabits")
}

@MainActor
class AuthManager: NSObject, ObservableObject {
    @Published var authState: AuthState = .notAuthenticated
    @Published var isLoading = false
    
    private let userDefaults = UserDefaults.standard
    private let userKey = "currentUser"
    private var currentNonce: String?
    
    static let shared = AuthManager()
    
    private override init() {
        super.init()
        // Check if user is already logged in
        loadSavedUser()
        
        // Clean up orphaned auth tokens
        if case .notAuthenticated = authState {
            userDefaults.removeObject(forKey: "authToken")
        }
    }
    
    // MARK: - Username/Password Authentication
    
    func signUp(username: String, password: String, agreedToPrivacyPolicy: Bool = true, agreedToTerms: Bool = true) async -> Bool {
        isLoading = true
        authState = .authenticating
        
        // Validate input
        guard !username.isEmpty, password.count >= 6 else {
            authState = .error("Username cannot be empty and password must be at least 6 characters")
            isLoading = false
            return false
        }
        
        // Validate privacy consent
        guard agreedToPrivacyPolicy && agreedToTerms else {
            authState = .error("You must agree to the Privacy Policy and Terms of Service to create an account")
            isLoading = false
            return false
        }
        
        do {
            // Use API to register user
            let user = try await APIClient.shared.register(username: username, password: password, agreedToPrivacyPolicy: agreedToPrivacyPolicy, agreedToTerms: agreedToTerms)
            await saveUser(user)
            authState = .authenticated(user)
            
            // Notify HabitStore that user has logged in
            await notifyUserLogin()
            
            isLoading = false
            return true
        } catch {
            // Handle signup error
            _ = error
            
            // If API fails, create local user account as fallback
            if let apiError = error as? APIError {
                switch apiError {
                case .networkError, .serverError:
                    // API unavailable, creating local account
                    let localUser = User(
                        id: UUID().uuidString,
                        username: username,
                        email: nil,
                        createdAt: Date(),
                        lastLoginAt: Date(),
                        isAppleUser: false,
                        profilePicture: nil,
                        privacyPolicyAcceptedAt: Date(),
                        termsOfServiceAcceptedAt: Date()
                    )
                    await saveUser(localUser)
                    authState = .authenticated(localUser)
                    await notifyUserLogin()
                    isLoading = false
                    return true
                default:
                    break
                }
            }
            
            // Provide more user-friendly error messages
            let userFriendlyError: String
            if let apiError = error as? APIError {
                switch apiError {
                case .networkError(let message):
                    userFriendlyError = "Connection failed: \(message). Please check your internet connection and try again."
                case .serverError(let message):
                    userFriendlyError = "Server error: \(message). The server may be temporarily unavailable."
                case .unauthorized:
                    userFriendlyError = "Authentication failed. Please try again."
                case .invalidResponse:
                    userFriendlyError = "Server returned an invalid response. Please try again later."
                case .decodingError:
                    userFriendlyError = "Failed to process server response. Please try again."
                }
            } else {
                userFriendlyError = error.localizedDescription
            }
            
            authState = .error(userFriendlyError)
            isLoading = false
            return false
        }
    }
    
    func signIn(username: String, password: String) async -> Bool {
        isLoading = true
        authState = .authenticating
        
        // Validate input
        guard !username.isEmpty, !password.isEmpty else {
            authState = .error("Username and password cannot be empty")
            isLoading = false
            return false
        }
        
        do {
            // Use API to login user
            let user = try await APIClient.shared.login(username: username, password: password)
            await saveUser(user)
            authState = .authenticated(user)
            
            // Notify HabitStore that user has logged in
            await notifyUserLogin()
            
            isLoading = false
            return true
        } catch {
            // Handle signin error
            _ = error
            
            // Provide user-friendly error messages
            let userFriendlyError: String
            if let apiError = error as? APIError {
                switch apiError {
                case .networkError(let message):
                    userFriendlyError = "Connection failed: \(message)"
                case .serverError(let message):
                    userFriendlyError = "Server error: \(message)"
                case .unauthorized:
                    userFriendlyError = "Invalid credentials"
                case .invalidResponse:
                    userFriendlyError = "Invalid server response"
                case .decodingError:
                    userFriendlyError = "Failed to process response"
                }
            } else {
                userFriendlyError = error.localizedDescription
            }
            
            authState = .error(userFriendlyError)
            isLoading = false
            return false
        }
    }
    
    // MARK: - Sign in with Apple
    
    func signInWithApple() {
        let nonce = randomNonceString()
        currentNonce = nonce
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    

    // MARK: - Sign Out
    
    func signOut() {
        // Clear all user-related data
        clearAllUserData()
        
        userDefaults.removeObject(forKey: userKey)
        userDefaults.removeObject(forKey: "authToken")
        authState = .notAuthenticated
        
        // Notify HabitStore that user has logged out
        Task {
            await notifyUserLogout()
        }
    }
    
    private func clearAllUserData() {
        // Clear friend-related data
        userDefaults.removeObject(forKey: "userFriends")
        userDefaults.removeObject(forKey: "friendRequests")
        userDefaults.removeObject(forKey: "outgoingFriendRequests")
        userDefaults.removeObject(forKey: "userActivities")
        userDefaults.removeObject(forKey: "userAnalytics")
        
        // Clear habit-related data
        userDefaults.removeObject(forKey: "SavedHabits")
        userDefaults.removeObject(forKey: "SavedTasks")
        userDefaults.removeObject(forKey: "SavedGoals")
        
        // Synchronize to ensure all data is cleared
        userDefaults.synchronize()
    }
    
    // MARK: - Private Methods
    
    private func loadSavedUser() {
        // Check if we have both user data AND a valid auth token
        if let userData = userDefaults.data(forKey: userKey),
           let _ = userDefaults.string(forKey: "authToken") {
            do {
                let user = try JSONDecoder().decode(User.self, from: userData)
                authState = .authenticated(user)
            } catch {
                authState = .notAuthenticated
            }
        } else {
            // If either user data or auth token is missing, user is not authenticated
            authState = .notAuthenticated
        }
    }
    
    func saveUser(_ user: User) async {
        do {
            let userData = try JSONEncoder().encode(user)
            userDefaults.set(userData, forKey: userKey)
        } catch {
            // ... existing code ...
        }
    }
    
    func updateCurrentUser(_ user: User) {
        authState = .authenticated(user)
        Task {
            await saveUser(user)
        }
    }
    
    private func isUsernameTaken(_ username: String) async -> Bool {
        // In a real app, this would check against a database
        // For now, we'll simulate that "admin" is taken
        return username.lowercased() == "admin"
    }
    
    private func validateCredentials(username: String, password: String) async -> Bool {
        // In a real app, this would validate against a backend
        // For demo purposes, accept any non-empty credentials
        return !username.isEmpty && !password.isEmpty
    }
    
    var currentUser: User? {
        // Get the current user from auth state
        if case .authenticated(let user) = authState {
            return user
        }
        return nil
    }
    
    private func getCurrentUser() -> User? {
        // Get the current user from auth state
        if case .authenticated(let user) = authState {
            return user
        }
        return nil
    }
    
    // MARK: - User Session Notifications
    
    private func notifyUserLogin() async {
        // Post notification for HabitStore to handle
        await MainActor.run {
            NotificationCenter.default.post(name: .userDidLogin, object: nil)
        }
    }
    
    private func notifyUserLogout() async {
        // Post notification for HabitStore to handle
        await MainActor.run {
            NotificationCenter.default.post(name: .userDidLogout, object: nil)
        }
    }
    
    // MARK: - Apple Sign In Helpers
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
}

// MARK: - ASAuthorizationControllerDelegate
extension AuthManager: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            authState = .error("Failed to get Apple ID credential")
            return
        }
        
        guard let nonce = currentNonce else {
            authState = .error("Invalid state: A login callback was received, but no login request was sent.")
            return
        }
        
        guard let appleIDToken = appleIDCredential.identityToken else {
            authState = .error("Unable to fetch identity token")
            return
        }
        
        guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            authState = .error("Unable to serialize token string from data")
            return
        }
        
        let userId = appleIDCredential.user
        
        Task {
            do {
                let (user, isNewUser) = try await APIClient.shared.signInWithApple(
                    identityToken: idTokenString,
                    user: userId,
                    email: appleIDCredential.email,
                    fullName: appleIDCredential.fullName
                )
                
                await saveUser(user)
                authState = .authenticated(user)
                
                // Notify about successful login
                await notifyUserLogin()
                
            } catch {
                authState = .error("Apple Sign In failed: \(error.localizedDescription)")
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        authState = .error("Sign in with Apple failed: \(error.localizedDescription)")
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding
extension AuthManager: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            fatalError("No window found")
        }
        return window
    }
} 