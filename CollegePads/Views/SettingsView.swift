import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @ObservedObject var profileVM = ProfileViewModel.shared
    @State private var showVerification = false
    @State private var showBlockedUsers = false
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    
    private let appVersion = "1.0.0"  // Update as needed.
    
    var body: some View {
        ZStack {
            // Global background gradient.
            AppTheme.backgroundGradient.ignoresSafeArea()
            
            Form {
                // Account Information Section.
                Section(header: Text("Account")
                            .font(AppTheme.subtitleFont)) {
                    HStack {
                        Text("Email")
                            .font(AppTheme.bodyFont)
                        Spacer()
                        Text(profileVM.userProfile?.email ?? "N/A")
                            .font(AppTheme.bodyFont)
                            .foregroundColor(.gray)
                    }
                    HStack {
                        Text("Verified")
                            .font(AppTheme.bodyFont)
                        Spacer()
                        if let verified = profileVM.userProfile?.isVerified, verified {
                            Text("Yes")
                                .font(AppTheme.bodyFont)
                                .foregroundColor(.green)
                        } else {
                            Text("No")
                                .font(AppTheme.bodyFont)
                                .foregroundColor(.red)
                        }
                    }
                    if profileVM.userProfile?.isVerified != true {
                        Button(action: { showVerification = true }) {
                            Text("Verify Now")
                                .font(AppTheme.bodyFont)
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                // Privacy Section.
                Section(header: Text("Privacy")
                            .font(AppTheme.subtitleFont)) {
                    NavigationLink(destination: BlockedUsersView()) {
                        Text("Manage Blocked Users")
                            .font(AppTheme.bodyFont)
                    }
                }
                
                // Appearance Section.
                Section(header: Text("Appearance")
                            .font(AppTheme.subtitleFont)) {
                    Toggle("Dark Mode", isOn: $isDarkMode)
                        .accessibilityLabel("Dark Mode Toggle")
                }
                
                // About Section.
                Section(header: Text("About")
                            .font(AppTheme.subtitleFont)) {
                    HStack {
                        Text("CollegePads")
                            .font(AppTheme.bodyFont)
                        Spacer()
                        Text("Version \(appVersion)")
                            .font(AppTheme.bodyFont)
                            .foregroundColor(.gray)
                    }
                    NavigationLink(destination: AboutView()) {
                        Text("Learn More")
                            .font(AppTheme.bodyFont)
                    }
                }
                
                // Account Management Section.
                Section(header: Text("Account Management")
                            .font(AppTheme.subtitleFont)) {
                    NavigationLink(destination: DeleteAccountView().environmentObject(authViewModel)) {
                        Text("Delete Account")
                            .font(AppTheme.bodyFont)
                            .foregroundColor(.red)
                    }
                }
                
                // Sign Out Section.
                Section {
                    Button(action: { authViewModel.signOut() }) {
                        Text("Log Out")
                            .font(AppTheme.bodyFont)
                            .foregroundColor(.red)
                    }
                }
            }
            // Hide the Form's default background.
            .scrollContentBackground(.hidden)
            // Apply the global font.
            .font(AppTheme.bodyFont)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Settings")
                        .font(AppTheme.titleFont)
                        .foregroundColor(.primary)
                }
            }
            .sheet(isPresented: $showVerification) {
                VerificationView()
            }
        }
    }
}

struct AboutView: View {
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient.ignoresSafeArea()
            VStack(spacing: 20) {
                Text("CollegePads")
                    .font(AppTheme.titleFont)
                    .bold()
                Text("A production‑ready app to help college students find the perfect roommate and housing. Built with scalability and user experience in mind.")
                    .font(AppTheme.bodyFont)
                    .multilineTextAlignment(.center)
                    .padding()
                Spacer()
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("About")
                        .font(AppTheme.titleFont)
                        .foregroundColor(.primary)
                }
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SettingsView().environmentObject(AuthViewModel())
        }
    }
}
