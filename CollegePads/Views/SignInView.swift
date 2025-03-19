//
//  SignInView.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//

import SwiftUI

struct SignInView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Sign In")
                .font(.headline)
            
            TextField("Enter your email", text: $authViewModel.email)
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
                authViewModel.signIn()
            }) {
                if authViewModel.isLoading {
                    ProgressView()
                } else {
                    Text("Sign In")
                }
            }
            .buttonStyle(PrimaryButtonStyle(backgroundColor: Color.green))
            
            Text("Don't have an account? Sign Up")
                .foregroundColor(.blue)
                .onTapGesture {
                    authViewModel.errorMessage = nil
                    authViewModel.email = ""
                    authViewModel.password = ""
                    // Switching is handled in AuthenticationView
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
