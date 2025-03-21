//
//  SignUpView.swift
//  CollegePads
//
//  Updated to use PrimaryButtonStyle and global theme typography.
//
import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        VStack(spacing: 20) {
            Text("Create a .edu Account")
                .font(AppTheme.titleFont)
            
            TextField("Enter .edu email", text: $authViewModel.email)
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
                authViewModel.signUp()
            }) {
                if authViewModel.isLoading {
                    ProgressView()
                } else {
                    Text("Sign Up")
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .accessibilityLabel("Sign Up Button")
            
            Text("Already have an account? Sign In")
                .foregroundColor(AppTheme.accentColor)
                .onTapGesture {
                    authViewModel.errorMessage = nil
                    authViewModel.email = ""
                    authViewModel.password = ""
                    // Navigation handled in AuthenticationView.
                }
        }
        .padding()
        .navigationTitle("Sign Up")
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SignUpView().environmentObject(AuthViewModel())
        }
    }
}
