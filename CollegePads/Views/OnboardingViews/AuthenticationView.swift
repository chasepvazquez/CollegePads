import SwiftUI

struct AuthenticationView: View {
    @State private var showSignIn: Bool = true
    
    var body: some View {
        ZStack {
            // Global background from your theme.
            AppTheme.backgroundGradient.ignoresSafeArea()
            
            NavigationView {
                VStack {
                    Picker("Authentication", selection: $showSignIn) {
                        Text("Sign In").tag(true)
                        Text("Sign Up").tag(false)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                    
                    if showSignIn {
                        SignInView(showSignIn: $showSignIn)
                    } else {
                        SignUpView(showSignIn: $showSignIn)
                    }
                    
                    Spacer()
                }
                // Apply the theme font globally to the content.
                .font(AppTheme.bodyFont)
                .navigationBarHidden(true)
            }
        }
    }
}

struct AuthenticationView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticationView()
    }
}
