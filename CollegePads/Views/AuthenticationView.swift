//
//  AuthenticationView.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//

import SwiftUI

struct AuthenticationView: View {
    @State private var showSignIn: Bool = true
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("Authentication", selection: $showSignIn) {
                    Text("Sign In").tag(true)
                    Text("Sign Up").tag(false)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                if showSignIn {
                    SignInView()
                } else {
                    SignUpView()
                }
                
                Spacer()
            }
            .navigationBarHidden(true)
        }
    }
}

struct AuthenticationView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticationView()
    }
}
