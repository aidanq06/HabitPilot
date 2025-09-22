import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @StateObject private var authManager = AuthManager.shared
    @State private var isSignUp = false
    @State private var username = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var agreedToPrivacyPolicy = false
    @State private var agreedToTerms = false
    @State private var showingPrivacyPolicy = false
    @State private var showingTermsOfService = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color.primaryBackground,
                        Color.secondaryBackground
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // App Logo/Title
                        VStack(spacing: 16) {
                            Image("AppLogo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white.opacity(0.1))
                                        .frame(width: 100, height: 100)
                                        .shadow(color: Color.infoBlue.opacity(0.2), radius: 8, x: 0, y: 4)
                                )
                            
                            Text("HabitPilot AI")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.primaryText)
                            
                            Text("Build better habits with AI")
                                .font(.subheadline)
                                .foregroundColor(.secondaryText)
                        }
                        .padding(.top, 60)
                        
                        // Login Form
                        VStack(spacing: 20) {
                            // Username Field
                            CustomTextField(
                                text: $username,
                                placeholder: "Username",
                                icon: "person.fill"
                            )
                            
                            // Password Field
                            CustomSecureField(
                                text: $password,
                                placeholder: "Password",
                                showPassword: $showPassword
                            )
                            
                            // Confirm Password Field (for sign up only)
                            if isSignUp {
                                CustomSecureField(
                                    text: $confirmPassword,
                                    placeholder: "Confirm Password",
                                    showPassword: $showConfirmPassword
                                )
                                
                                // Privacy Policy and Terms Agreement (for sign up only)
                                VStack(spacing: 12) {
                                    // Privacy Policy Agreement
                                    HStack(alignment: .top, spacing: 12) {
                                        Button(action: {
                                            agreedToPrivacyPolicy.toggle()
                                        }) {
                                            Image(systemName: agreedToPrivacyPolicy ? "checkmark.square.fill" : "square")
                                                .font(.system(size: 20))
                                                .foregroundColor(agreedToPrivacyPolicy ? .infoBlue : .secondaryText)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            HStack {
                                                Text("I have read and agree to the")
                                                    .font(.caption)
                                                    .foregroundColor(.primaryText)
                                                
                                                Button(action: {
                                                    showingPrivacyPolicy = true
                                                }) {
                                                    Text("Privacy Policy")
                                                        .font(.caption)
                                                        .foregroundColor(.infoBlue)
                                                        .underline()
                                                }
                                            }
                                        }
                                        
                                        Spacer()
                                    }
                                    
                                    // Terms of Service Agreement
                                    HStack(alignment: .top, spacing: 12) {
                                        Button(action: {
                                            agreedToTerms.toggle()
                                        }) {
                                            Image(systemName: agreedToTerms ? "checkmark.square.fill" : "square")
                                                .font(.system(size: 20))
                                                .foregroundColor(agreedToTerms ? .infoBlue : .secondaryText)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            HStack {
                                                Text("I have read and agree to the")
                                                    .font(.caption)
                                                    .foregroundColor(.primaryText)
                                                
                                                Button(action: {
                                                    showingTermsOfService = true
                                                }) {
                                                    Text("Terms of Service")
                                                        .font(.caption)
                                                        .foregroundColor(.infoBlue)
                                                        .underline()
                                                }
                                            }
                                        }
                                        
                                        Spacer()
                                    }
                                }
                                .padding(.horizontal, 4)
                                .padding(.top, 8)
                            }
                            
                            // Error Message
                            if case .error(let message) = authManager.authState {
                                Text(message)
                                    .foregroundColor(.errorRed)
                                    .font(.caption)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                            
                            // Login/Sign Up Button
                            Button(action: {
                                Task {
                                    if isSignUp {
                                        await handleSignUp()
                                    } else {
                                        await handleSignIn()
                                    }
                                }
                            }) {
                                HStack {
                                    if authManager.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: isSignUp ? "person.badge.plus" : "person.fill")
                                    }
                                    
                                    Text(isSignUp ? "Sign Up" : "Sign In")
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(
                                    LinearGradient(
                                        colors: [Color.infoBlue, Color.infoBlue.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(25)
                                .shadow(color: Color.infoBlue.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                            .disabled(authManager.isLoading || !isFormValid)
                            .opacity(isFormValid ? 1.0 : 0.6)
                        }
                        .padding(.horizontal, 32)
                        
                        // Divider
                        HStack {
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(.secondaryText.opacity(0.3))
                            
                            Text("or")
                                .font(.caption)
                                .foregroundColor(.secondaryText)
                                .padding(.horizontal, 16)
                            
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(.secondaryText.opacity(0.3))
                        }
                        .padding(.horizontal, 32)
                        
                        // Sign in with Apple
                        VStack(spacing: 12) {
                            Button(action: {
                                authManager.signInWithApple()
                            }) {
                                HStack {
                                    Image(systemName: "applelogo")
                                        .font(.title3)
                                    Text("Sign in with Apple")
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.black)
                                .cornerRadius(25)
                            }
                            
                            // Apple Sign-In Privacy Notice
                            if !isSignUp {
                                Text("By signing in, you agree to our Privacy Policy and Terms of Service")
                                    .font(.caption2)
                                    .foregroundColor(.secondaryText)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 16)
                            }
                        }
                        .padding(.horizontal, 32)
                        
                        // Toggle between Sign In and Sign Up
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isSignUp.toggle()
                                clearForm()
                            }
                        }) {
                            Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                                .font(.subheadline)
                                .foregroundColor(.infoBlue)
                        }
                        .padding(.top, 16)
                        
                        Spacer()
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingPrivacyPolicy) {
            SimplePrivacyPolicyView()
        }
        .sheet(isPresented: $showingTermsOfService) {
            SimpleTermsOfServiceView()
        }
    }
    
    // MARK: - Helper Methods
    
    private var isFormValid: Bool {
        if isSignUp {
            return !username.isEmpty && 
                   password.count >= 6 && 
                   password == confirmPassword &&
                   agreedToPrivacyPolicy &&
                   agreedToTerms
        } else {
            return !username.isEmpty && !password.isEmpty
        }
    }
    
    private func clearForm() {
        username = ""
        password = ""
        confirmPassword = ""
        showPassword = false
        showConfirmPassword = false
        agreedToPrivacyPolicy = false
        agreedToTerms = false
    }
    
    private func handleSignIn() async {
        await authManager.signIn(username: username, password: password)
    }
    
    private func handleSignUp() async {
        await authManager.signUp(username: username, password: password, agreedToPrivacyPolicy: agreedToPrivacyPolicy, agreedToTerms: agreedToTerms)
    }
}

// MARK: - Custom Text Field
struct CustomTextField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.secondaryText)
                .frame(width: 20)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .autocapitalization(.none)
                .disableAutocorrection(true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.tertiaryBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.secondaryText.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Custom Secure Field
struct CustomSecureField: View {
    @Binding var text: String
    let placeholder: String
    @Binding var showPassword: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock.fill")
                .foregroundColor(.secondaryText)
                .frame(width: 20)
            
            if showPassword {
                TextField(placeholder, text: $text)
                    .textFieldStyle(PlainTextFieldStyle())
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            } else {
                SecureField(placeholder, text: $text)
                    .textFieldStyle(PlainTextFieldStyle())
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            
            Button(action: {
                showPassword.toggle()
            }) {
                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(.secondaryText)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.tertiaryBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.secondaryText.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

#Preview {
    LoginView()
} 