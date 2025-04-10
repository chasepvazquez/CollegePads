import SwiftUI

struct SignInView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    // Local state to track if user tapped "Sign In."
    @State private var hasAttemptedSignIn: Bool = false
    
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
                    hasAttemptedSignIn = true
                    authViewModel.signIn()
                }) {
                    if authViewModel.isLoading {
                        ProgressView()
                    } else {
                        Text("Sign In")
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
                
                Text("Don't have an account? Sign Up")
                    .font(AppTheme.bodyFont)
                    .foregroundColor(AppTheme.primaryColor)
                    .onTapGesture {
                        // Clear errors and fields when switching.
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
                    Text("Sign In")
                        .font(AppTheme.titleFont)
                        .foregroundColor(.primary)
                }
            }
        }
    }
}

struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SignInView().environmentObject(AuthViewModel())
        }
    }
}
