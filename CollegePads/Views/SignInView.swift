import SwiftUI
import FirebaseAuth

struct SignInView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        ZStack {
            // Global background.
            AppTheme.backgroundGradient.ignoresSafeArea()
            
            // Use a VStack that expands to full height.
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
                
                if let errorMessage = authViewModel.errorMessage {
                    Text(errorMessage)
                        .font(AppTheme.bodyFont)
                        .foregroundColor(AppTheme.nopeColor)
                        .multilineTextAlignment(.center)
                }
                
                Button(action: {
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
                            .background(AppTheme.primaryColor)
                            .cornerRadius(AppTheme.defaultCornerRadius)
                    }
                }
                
                Text("Don't have an account? Sign Up")
                    .font(AppTheme.bodyFont)
                    .foregroundColor(AppTheme.primaryColor)
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
