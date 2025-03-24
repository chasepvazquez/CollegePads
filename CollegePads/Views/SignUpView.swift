import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        ZStack {
            // Global background.
            AppTheme.backgroundGradient.ignoresSafeArea()
            
            // Use a VStack that expands to full height.
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
                
                if let errorMessage = authViewModel.errorMessage {
                    Text(errorMessage)
                        .font(AppTheme.bodyFont)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }
                
                Button(action: {
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
                            .background(AppTheme.primaryColor)
                            .cornerRadius(AppTheme.defaultCornerRadius)
                    }
                }
                // Remove redundant buttonStyle since explicit styling is applied.
                .accessibilityLabel("Sign Up Button")
                
                Text("Already have an account? Sign In")
                    .font(AppTheme.bodyFont)
                    .foregroundColor(AppTheme.accentColor)
                    .onTapGesture {
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
