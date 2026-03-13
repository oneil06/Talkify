import Foundation
import AuthenticationServices
import CryptoKit

// MARK: - Auth Service
class AuthService: NSObject, ObservableObject {
    static let shared = AuthService()
    
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: User?
    @Published var isLoading: Bool = false
    @Published var error: String?
    
    private let defaults = UserDefaults.standard
    
    private enum Keys {
        static let userId = "auth_user_id"
        static let userEmail = "auth_user_email"
        static let userName = "auth_user_name"
        static let isAppleSignIn = "auth_is_apple"
        static let isLoggedIn = "auth_is_logged_in"
    }
    
    private override init() {
        super.init()
        checkAuthStatus()
    }
    
    // MARK: - Check Auth Status
    func checkAuthStatus() {
        isAuthenticated = defaults.bool(forKey: Keys.isLoggedIn)
        
        if isAuthenticated {
            let userId = defaults.string(forKey: Keys.userId) ?? ""
            let email = defaults.string(forKey: Keys.userEmail) ?? ""
            let name = defaults.string(forKey: Keys.userName) ?? ""
            let isApple = defaults.bool(forKey: Keys.isAppleSignIn)
            
            currentUser = User(
                id: userId,
                email: email,
                displayName: name.isEmpty ? email.components(separatedBy: "@").first ?? "User" : name,
                isAppleSignIn: isApple,
                subscriptionPlan: .pro, // Default to pro for demo
                createdAt: Date()
            )
        }
    }
    
    // MARK: - Email/Password Sign Up
    func signUp(email: String, password: String, name: String) async throws -> User {
        await MainActor.run { isLoading = true }
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_500_000_000)
        
        // Basic validation
        guard isValidEmail(email) else {
            throw AuthError.invalidEmail
        }
        
        guard password.count >= 6 else {
            throw AuthError.weakPassword
        }
        
        // Create user (in real app, this would call your backend)
        let user = User(
            id: UUID().uuidString,
            email: email,
            displayName: name,
            isAppleSignIn: false,
            subscriptionPlan: .pro,
            createdAt: Date()
        )
        
        // Save to local storage
        saveUser(user)
        
        await MainActor.run {
            currentUser = user
            isAuthenticated = true
            isLoading = false
        }
        
        return user
    }
    
    // MARK: - Email/Password Sign In
    func signIn(email: String, password: String) async throws -> User {
        await MainActor.run { isLoading = true }
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Basic validation
        guard isValidEmail(email) else {
            throw AuthError.invalidEmail
        }
        
        guard !password.isEmpty else {
            throw AuthError.invalidPassword
        }
        
        // Create user (in real app, this would validate with backend)
        let user = User(
            id: UUID().uuidString,
            email: email,
            displayName: email.components(separatedBy: "@").first ?? "User",
            isAppleSignIn: false,
            subscriptionPlan: .pro,
            createdAt: Date()
        )
        
        // Save to local storage
        saveUser(user)
        
        await MainActor.run {
            currentUser = user
            isAuthenticated = true
            isLoading = false
        }
        
        return user
    }
    
    // MARK: - Apple Sign In
    func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) async throws -> User {
        await MainActor.run { isLoading = true }
        
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let email = appleIDCredential.email,
                  let fullName = appleIDCredential.fullName else {
                // Returning user - create based on stored data
                return try await restoreAppleSignIn()
            }
            
            let name = [fullName.givenName, fullName.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
            
            let user = User(
                id: appleIDCredential.user,
                email: email,
                displayName: name.isEmpty ? "Apple User" : name,
                isAppleSignIn: true,
                subscriptionPlan: .pro,
                createdAt: Date()
            )
            
            // Save to local storage
            saveUser(user)
            
            await MainActor.run {
                currentUser = user
                isAuthenticated = true
                isLoading = false
            }
            
            return user
            
        case .failure(let error):
            await MainActor.run { isLoading = false }
            throw AuthError.appleSignInFailed(error.localizedDescription)
        }
    }
    
    // Restore Apple Sign In for returning users
    private func restoreAppleSignIn() async throws -> User {
        guard isAuthenticated else {
            throw AuthError.appleSignInFailed("No stored credentials")
        }
        
        return currentUser!
    }
    
    // MARK: - Sign Out
    func signOut() {
        defaults.removeObject(forKey: Keys.userId)
        defaults.removeObject(forKey: Keys.userEmail)
        defaults.removeObject(forKey: Keys.userName)
        defaults.removeObject(forKey: Keys.isAppleSignIn)
        defaults.set(false, forKey: Keys.isLoggedIn)
        
        currentUser = nil
        isAuthenticated = false
    }
    
    // MARK: - Delete Account
    func deleteAccount() async throws {
        await MainActor.run { isLoading = true }
        
        // Simulate deletion
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // Clear all user data
        signOut()
        
        // Clear stored documents and audio
        StorageService.shared.clearAll()
        
        await MainActor.run { isLoading = false }
    }
    
    // MARK: - Password Reset
    func resetPassword(email: String) async throws {
        guard isValidEmail(email) else {
            throw AuthError.invalidEmail
        }
        
        // Simulate sending reset email
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // In real app, would send reset email via backend
    }
    
    // MARK: - Private Helpers
    private func saveUser(_ user: User) {
        defaults.set(user.id, forKey: Keys.userId)
        defaults.set(user.email, forKey: Keys.userEmail)
        defaults.set(user.displayName, forKey: Keys.userName)
        defaults.set(user.isAppleSignIn, forKey: Keys.isAppleSignIn)
        defaults.set(true, forKey: Keys.isLoggedIn)
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}

// MARK: - Auth Errors
enum AuthError: LocalizedError {
    case invalidEmail
    case invalidPassword
    case weakPassword
    case emailAlreadyInUse
    case userNotFound
    case wrongPassword
    case appleSignInFailed(String)
    case networkError
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Please enter a valid email address"
        case .invalidPassword:
            return "Please enter your password"
        case .weakPassword:
            return "Password must be at least 6 characters"
        case .emailAlreadyInUse:
            return "This email is already registered"
        case .userNotFound:
            return "No account found with this email"
        case .wrongPassword:
            return "Incorrect password"
        case .appleSignInFailed(let message):
            return "Apple Sign In failed: \(message)"
        case .networkError:
            return "Network error. Please try again."
        case .unknown:
            return "An unknown error occurred"
        }
    }
}
