import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    // Local state for confirm password.
    @State private var confirmPassword: String = ""
    // Local state to track if user tapped "Sign Up."
    @State private var hasAttemptedSignUp: Bool = false
    
    // Computed property for form validity.
    private var isFormValid: Bool {
        return !authViewModel.email.isEmpty &&
               authViewModel.email.lowercased().hasSuffix(".edu") &&
               !authViewModel.password.isEmpty &&
               authViewModel.password == confirmPassword
    }
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient.ignoresSafeArea()
            
            VStack(spacing: 20) {
                Spacer(minLength: 20)
                
                Text("Create a .edu Account")
                    .font(AppTheme.titleFont)
                
                TextField("Enter .edu email", text: $authViewModel.email)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .padding(AppTheme.defaultPadding)
                    .background(AppTheme.cardBackground)
                    .cornerRadius(AppTheme.defaultCornerRadius)
                    .accessibilityLabel("Email Field")
                
                SecureField("Enter password", text: $authViewModel.password)
                    .padding(AppTheme.defaultPadding)
                    .background(AppTheme.cardBackground)
                    .cornerRadius(AppTheme.defaultCornerRadius)
                    .accessibilityLabel("Password Field")
                
                // Confirm Password Field
                SecureField("Confirm password", text: $confirmPassword)
                    .padding(AppTheme.defaultPadding)
                    .background(AppTheme.cardBackground)
                    .cornerRadius(AppTheme.defaultCornerRadius)
                    .accessibilityLabel("Confirm Password Field")
                
                // Error message container (shown only after user attempts sign up).
                Group {
                    if hasAttemptedSignUp,
                       let errorMessage = authViewModel.errorMessage,
                       !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(AppTheme.bodyFont)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    } else {
                        Color.clear.frame(height: 0)
                    }
                }
                
                Button(action: {
                    hasAttemptedSignUp = true
                    // Validate email and password.
                    guard authViewModel.email.lowercased().hasSuffix(".edu") else {
                        authViewModel.errorMessage = "Please use a .edu email address."
                        return
                    }
                    guard authViewModel.password == confirmPassword else {
                        authViewModel.errorMessage = "Passwords do not match."
                        return
                    }
                    authViewModel.signUp()
                }) {
                    if authViewModel.isLoading {
                        ProgressView()
                    } else {
                        Text("Sign Up")
                            .font(AppTheme.bodyFont)
                            .foregroundColor(.white)
                            .padding(AppTheme.defaultPadding)
                            .frame(maxWidth: .infinity)
                            .background(isFormValid ? AppTheme.primaryColor : AppTheme.primaryColor.opacity(0.5))
                            .cornerRadius(AppTheme.defaultCornerRadius)
                    }
                }
                .disabled(!isFormValid)
                .scaleEffect(isFormValid ? 1.0 : 0.95)
                .animation(.easeInOut(duration: 0.2), value: isFormValid)
                .accessibilityLabel("Sign Up Button")
                
                Text("Already have an account? Sign In")
                    .font(AppTheme.bodyFont)
                    .foregroundColor(AppTheme.accentColor)
                    .onTapGesture {
                        // Clear error & fields on switch
                        authViewModel.errorMessage = nil
                        authViewModel.email = ""
                        authViewModel.password = ""
                    }
                
                Spacer(minLength: 20)
            }
            .padding()
            .frame(maxHeight: .infinity)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Sign Up")
                        .font(AppTheme.titleFont)
                        .foregroundColor(.primary)
                }
            }
        }
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SignUpView().environmentObject(AuthViewModel())
        }
    }
}
