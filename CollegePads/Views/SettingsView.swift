//
//  SettingsView.swift
//  CollegePads
//
//  Updated to include a new "Account Management" section with a Delete Account option.
//  Also includes existing dark mode, About, and Privacy sections.
//

import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @ObservedObject var profileVM = ProfileViewModel.shared
    @State private var showVerification = false
    @State private var showBlockedUsers = false
    // Persist dark mode preference.
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    
    private let appVersion = "1.0.0"  // Update this as needed.
    
    var body: some View {
        NavigationView {
            Form {
                // Account Information Section.
                Section(header: Text("Account")) {
                    HStack {
                        Text("Email")
                        Spacer()
                        Text(profileVM.userProfile?.email ?? "N/A")
                            .foregroundColor(.gray)
                    }
                    HStack {
                        Text("Verified")
                        Spacer()
                        if let verified = profileVM.userProfile?.isVerified, verified {
                            Text("Yes")
                                .foregroundColor(.green)
                        } else {
                            Text("No")
                                .foregroundColor(.red)
                        }
                    }
                    if profileVM.userProfile?.isVerified != true {
                        Button(action: { showVerification = true }) {
                            Text("Verify Now")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                // Privacy Section.
                Section(header: Text("Privacy")) {
                    NavigationLink(destination: BlockedUsersView()) {
                        Text("Manage Blocked Users")
                    }
                }
                
                // Appearance Section.
                Section(header: Text("Appearance")) {
                    Toggle("Dark Mode", isOn: $isDarkMode)
                        .accessibilityLabel("Dark Mode Toggle")
                }
                
                // About Section.
                Section(header: Text("About")) {
                    HStack {
                        Text("CollegePads")
                        Spacer()
                        Text("Version \(appVersion)")
                            .foregroundColor(.gray)
                    }
                    NavigationLink(destination: AboutView()) {
                        Text("Learn More")
                    }
                }
                
                // Account Management Section (New).
                Section(header: Text("Account Management")) {
                    NavigationLink(destination: DeleteAccountView().environmentObject(authViewModel)) {
                        Text("Delete Account")
                            .foregroundColor(.red)
                    }
                }
                
                // Sign Out Section.
                Section {
                    Button(action: { authViewModel.signOut() }) {
                        Text("Log Out")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showVerification) {
                VerificationView()
            }
        }
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("CollegePads")
                .font(.largeTitle)
                .bold()
            Text("A production‑ready app to help college students find the perfect roommate and housing. Built with scalability and user experience in mind.")
                .multilineTextAlignment(.center)
                .padding()
            Spacer()
        }
        .padding()
        .navigationTitle("About")
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SettingsView().environmentObject(AuthViewModel())
        }
    }
}
