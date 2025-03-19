//
//  SignUpView.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//

import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
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
            
            SecureField("Enter password", text: $authViewModel.password)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
            
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
            .buttonStyle(PrimaryButtonStyle(backgroundColor: Color.blue))
            
            Text("Already have an account? Sign In")
                .foregroundColor(.blue)
                .onTapGesture {
                    authViewModel.errorMessage = nil
                    authViewModel.email = ""
                    authViewModel.password = ""
                    // Switching is handled in AuthenticationView
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
