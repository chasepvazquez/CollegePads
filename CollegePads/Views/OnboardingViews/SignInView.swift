import SwiftUI

struct SignInView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Binding var showSignIn: Bool
    @State private var hasAttemptedSignIn: Bool = false
    @State private var showResetAlert: Bool = false
    
    // Computed property for form validity.
    private var isFormValid: Bool {
        return !authViewModel.email.isEmpty && !authViewModel.password.isEmpty
    }
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient.ignoresSafeArea()
            
            VStack(spacing: 20) {
                Spacer(minLength: 20)
                
                Text("Sign In")
                    .font(AppTheme.titleFont)
                
                TextField("Enter your email", text: $authViewModel.email)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .padding(AppTheme.defaultPadding)
                    .background(AppTheme.cardBackground)
                    .cornerRadius(AppTheme.defaultCornerRadius)
                
                SecureField("Enter password", text: $authViewModel.password)
                    .padding(AppTheme.defaultPadding)
                    .background(AppTheme.cardBackground)
                    .cornerRadius(AppTheme.defaultCornerRadius)
                
                // Error message container – uses red text as in SignUpView.
                Group {
                    if hasAttemptedSignIn,
                       let msg = authViewModel.errorMessage {
                        Text(msg)
                            .foregroundColor(.red)
                            .font(AppTheme.bodyFont)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    Button {
                        hasAttemptedSignIn = true
                        authViewModel.signIn()
                    } label: {
                        if authViewModel.isLoading {
                            ProgressView()
                        } else {
                            Text("Sign In")
                                .foregroundColor(.white)
                                .padding(AppTheme.defaultPadding)
                                .frame(maxWidth: .infinity)
                                .background(isFormValid ? AppTheme.primaryColor : AppTheme.primaryColor.opacity(0.5))
                                .cornerRadius(AppTheme.defaultCornerRadius)
                        }
                    }
                    .disabled(!isFormValid)
                    .scaleEffect(isFormValid ? 1 : 0.95)
                    .animation(.easeInOut, value: isFormValid)
                    // — Password Reset Link —
                    Button("Forgot password?") {
                        // clear previous messages
                        authViewModel.errorMessage = nil
                        authViewModel.passwordResetMessage = nil
                        authViewModel.sendPasswordReset()
                        showResetAlert = true
                    }
                    .font(AppTheme.bodyFont)
                    .foregroundColor(.accentColor)
                    
                    Button("Don't have an account? Sign Up") {
                        // clear state and toggle
                        authViewModel.errorMessage = nil
                        authViewModel.password = ""
                        showSignIn = false
                    }
                    .font(AppTheme.bodyFont)
                    .foregroundColor(AppTheme.primaryColor)
                    
                    Spacer(minLength: 20)
                }
                .padding()
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("Sign In")
                            .font(AppTheme.titleFont)
                            .foregroundColor(.primary)
                    }
                }
            }
            .alert("Password Reset",
                   isPresented: $showResetAlert,
                   actions: { Button("OK", role: .cancel) {} },
                   message: {
                Text(authViewModel.passwordResetMessage ?? "Check your email inbox.")
            })
        }
    }
    
    struct SignInView_Previews: PreviewProvider {
        static var previews: some View {
            NavigationView {
                SignInView(showSignIn: .constant(true))
                    .environmentObject(AuthViewModel())
            }
        }
    }
}
