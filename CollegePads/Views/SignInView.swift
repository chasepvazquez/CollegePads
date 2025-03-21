//
//  SignInView.swift
//  CollegePads
//
//  Updated to use PrimaryButtonStyle and global theme typography.
//
import SwiftUI

struct SignInView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        VStack(spacing: 20) {
            Text("Sign In")
                .font(AppTheme.titleFont)
            
            TextField("Enter your email", text: $authViewModel.email)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
                .padding()
                .background(AppTheme.cardBackground)
                .cornerRadius(AppTheme.defaultCornerRadius)
                .accessibilityLabel("Email Field")
            
            SecureField("Enter password", text: $authViewModel.password)
                .padding()
                .background(AppTheme.cardBackground)
                .cornerRadius(AppTheme.defaultCornerRadius)
                .accessibilityLabel("Password Field")
            
            if let errorMessage = authViewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {
                authViewModel.signIn()
            }) {
                Text("Sign In")
            }
            .buttonStyle(PrimaryButtonStyle())
            .accessibilityLabel("Sign In Button")
            
            Text("Don't have an account? Sign Up")
                .foregroundColor(AppTheme.accentColor)
                .onTapGesture {
                    authViewModel.errorMessage = nil
                    authViewModel.email = ""
                    authViewModel.password = ""
                    // Navigation handled in AuthenticationView.
                }
        }
        .padding()
        .navigationTitle("Sign In")
    }
}

struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SignInView().environmentObject(AuthViewModel())
        }
    }
}
