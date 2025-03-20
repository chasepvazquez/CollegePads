//
//  SignUpView.swift
//  CollegePads
//
//  Updated for improved input validation and user feedback
//

import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showErrorAnimation = false

    var isFormValid: Bool {
        authViewModel.email.lowercased().contains(".edu") &&
        !authViewModel.email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !authViewModel.password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Create a .edu Account")
                .font(.headline)
            
            TextField("Enter .edu email", text: $authViewModel.email)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
                .accessibilityLabel("Email Field")
            
            SecureField("Enter password", text: $authViewModel.password)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
                .accessibilityLabel("Password Field")
            
            if let errorMessage = authViewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .transition(.opacity)
                    .animation(.easeInOut, value: authViewModel.errorMessage)
            }
            
            Button(action: {
                withAnimation { showErrorAnimation = true }
                authViewModel.signUp()
            }) {
                if authViewModel.isLoading {
                    ProgressView()
                } else {
                    Text("Sign Up")
                        .frame(maxWidth: .infinity)
                }
            }
            .disabled(!isFormValid || authViewModel.isLoading)
            .buttonStyle(PrimaryButtonStyle(backgroundColor: Color.blue))
            .accessibilityLabel("Sign Up Button")
            
            Text("Already have an account? Sign In")
                .foregroundColor(.blue)
                .onTapGesture {
                    authViewModel.errorMessage = nil
                    authViewModel.email = ""
                    authViewModel.password = ""
                    // Navigation handled by AuthenticationView.
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
