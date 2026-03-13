import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showSignUp: Bool = false
    @State private var showForgotPassword: Bool = false
    @State private var errorMessage: String?
    @State private var showError: Bool = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Logo/Brand
                    VStack(spacing: 16) {
                        Image(systemName: "waveform.circle.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.brandPrimary, Color.brandSecondary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("Talkify")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.textPrimary)
                        
                        Text("Transform any content into audio")
                            .font(.bodyMedium)
                            .foregroundColor(.textSecondary)
                    }
                    .padding(.top, 60)
                    .padding(.bottom, 20)
                    
                    // Email Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.appSubheadline)
                            .foregroundColor(.textSecondary)
                        
                        TextField("Enter your email", text: $email)
                            .textFieldStyle(CustomTextFieldStyle())
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    
                    // Password Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.appSubheadline)
                            .foregroundColor(.textSecondary)
                        
                        SecureField("Enter your password", text: $password)
                            .textFieldStyle(CustomTextFieldStyle())
                            .textContentType(.password)
                    }
                    
                    // Forgot Password
                    HStack {
                        Spacer()
                        Button(action: { showForgotPassword = true }) {
                            Text("Forgot Password?")
                                .font(.appSubheadline)
                                .foregroundColor(.brandPrimary)
                        }
                    }
                    
                    // Sign In Button
                    PrimaryButton(
                        "Sign In",
                        icon: "arrow.right",
                        isLoading: AuthService.shared.isLoading
                    ) {
                        signIn()
                    }
                    
                    // Divider
                    HStack {
                        Rectangle()
                            .fill(Color.textSecondary.opacity(0.3))
                            .frame(height: 1)
                        
                        Text("or")
                            .font(.appSubheadline)
                            .foregroundColor(.textSecondary)
                        
                        Rectangle()
                            .fill(Color.textSecondary.opacity(0.3))
                            .frame(height: 1)
                    }
                    
                    // Apple Sign In
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        handleAppleSignIn(result)
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .cornerRadius(12)
                    
                    // Sign Up Link
                    HStack {
                        Text("Don't have an account?")
                            .font(.appSubheadline)
                            .foregroundColor(.textSecondary)
                        
                        Button(action: { showSignUp = true }) {
                            Text("Sign Up")
                                .font(.appSubheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.brandPrimary)
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
            .background(Color.appBackgroundPrimary.ignoresSafeArea())
            .navigationDestination(isPresented: $showSignUp) {
                SignUpView()
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "An error occurred")
            }
            .sheet(isPresented: $showForgotPassword) {
                ForgotPasswordView()
            }
        }
    }
    
    private func signIn() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter email and password"
            showError = true
            return
        }
        
        Task {
            do {
                _ = try await AuthService.shared.signIn(email: email, password: password)
                await MainActor.run {
                    appState.currentUser = AuthService.shared.currentUser
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        Task {
            do {
                _ = try await AuthService.shared.handleAppleSignIn(result)
                await MainActor.run {
                    appState.currentUser = AuthService.shared.currentUser
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

// MARK: - Sign Up View
struct SignUpView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var errorMessage: String?
    @State private var showError: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Create Account")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)
                    
                    Text("Start your audio journey today")
                        .font(.bodyMedium)
                        .foregroundColor(.textSecondary)
                }
                .padding(.top, 40)
                
                // Name Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Full Name")
                        .font(.appSubheadline)
                        .foregroundColor(.textSecondary)
                    
                    TextField("Enter your name", text: $name)
                        .textFieldStyle(CustomTextFieldStyle())
                        .textContentType(.name)
                        .autocapitalization(.words)
                }
                
                // Email Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email")
                        .font(.appSubheadline)
                        .foregroundColor(.textSecondary)
                    
                    TextField("Enter your email", text: $email)
                        .textFieldStyle(CustomTextFieldStyle())
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                
                // Password Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Password")
                        .font(.appSubheadline)
                        .foregroundColor(.textSecondary)
                    
                    SecureField("Create a password", text: $password)
                        .textFieldStyle(CustomTextFieldStyle())
                        .textContentType(.newPassword)
                }
                
                // Confirm Password
                VStack(alignment: .leading, spacing: 8) {
                    Text("Confirm Password")
                        .font(.appSubheadline)
                        .foregroundColor(.textSecondary)
                    
                    SecureField("Confirm your password", text: $confirmPassword)
                        .textFieldStyle(CustomTextFieldStyle())
                        .textContentType(.newPassword)
                }
                
                // Sign Up Button
                PrimaryButton(
                    "Create Account",
                    icon: "checkmark.circle",
                    isLoading: AuthService.shared.isLoading
                ) {
                    signUp()
                }
                
                // Terms
                Text("By signing up, you agree to our Terms of Service and Privacy Policy")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                
                // Apple Sign In Option
                HStack {
                    Rectangle()
                        .fill(Color.textSecondary.opacity(0.3))
                        .frame(height: 1)
                    
                    Text("or")
                        .font(.appSubheadline)
                        .foregroundColor(.textSecondary)
                    
                    Rectangle()
                        .fill(Color.textSecondary.opacity(0.3))
                        .frame(height: 1)
                }
                
                SignInWithAppleButton(.signUp) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    handleAppleSignIn(result)
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 50)
                .cornerRadius(12)
                
                // Sign In Link
                HStack {
                    Text("Already have an account?")
                        .font(.appSubheadline)
                        .foregroundColor(.textSecondary)
                    
                    Button(action: { dismiss() }) {
                        Text("Sign In")
                            .font(.appSubheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.brandPrimary)
                    }
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 24)
        }
        .background(Color.appBackgroundPrimary.ignoresSafeArea())
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "An error occurred")
        }
    }
    
    private func signUp() {
        guard !name.isEmpty, !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields"
            showError = true
            return
        }
        
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match"
            showError = true
            return
        }
        
        Task {
            do {
                _ = try await AuthService.shared.signUp(email: email, password: password, name: name)
                await MainActor.run {
                    appState.currentUser = AuthService.shared.currentUser
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        Task {
            do {
                _ = try await AuthService.shared.handleAppleSignIn(result)
                await MainActor.run {
                    appState.currentUser = AuthService.shared.currentUser
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

// MARK: - Forgot Password View
struct ForgotPasswordView: View {
    @Environment(\.dismiss) var dismiss
    @State private var email: String = ""
    @State private var showSuccess: Bool = false
    @State private var errorMessage: String?
    @State private var showError: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Image(systemName: "lock.circle")
                        .font(.system(size: 60))
                        .foregroundColor(.brandPrimary)
                    
                    Text("Reset Password")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Enter your email and we'll send you a link to reset your password")
                        .font(.bodyMedium)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email")
                        .font(.appSubheadline)
                        .foregroundColor(.textSecondary)
                    
                    TextField("Enter your email", text: $email)
                        .textFieldStyle(CustomTextFieldStyle())
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
                
                PrimaryButton("Send Reset Link", icon: "envelope", isLoading: AuthService.shared.isLoading) {
                    resetPassword()
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .background(Color.appBackgroundPrimary.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Success", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Password reset link sent to your email")
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "An error occurred")
            }
        }
    }
    
    private func resetPassword() {
        Task {
            do {
                try await AuthService.shared.resetPassword(email: email)
                await MainActor.run {
                    showSuccess = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}


