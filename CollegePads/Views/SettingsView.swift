//
//  SettingsView.swift
//  CollegePads
//
//  Updated to use global theme for typography, colors, and button styles.
//

import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @ObservedObject var profileVM = ProfileViewModel.shared
    @State private var showVerification = false
    @State private var showBlockedUsers = false
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    
    private let appVersion = "1.0.0"
    
    var body: some View {
        NavigationView {
            Form {
                // Account Information Section.
                Section(header: Text("Account").font(AppTheme.subtitleFont)) {
                    HStack {
                        Text("Email").font(AppTheme.bodyFont)
                        Spacer()
                        Text(profileVM.userProfile?.email ?? "N/A")
                            .foregroundColor(.gray)
                    }
                    HStack {
                        Text("Verified").font(AppTheme.bodyFont)
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
                        }
                        .buttonStyle(PrimaryButtonStyle(backgroundColor: AppTheme.accentColor))
                    }
                }
                
                // Privacy Section.
                Section(header: Text("Privacy").font(AppTheme.subtitleFont)) {
                    NavigationLink(destination: BlockedUsersView()) {
                        Text("Manage Blocked Users")
                    }
                }
                
                // Appearance Section.
                Section(header: Text("Appearance").font(AppTheme.subtitleFont)) {
                    Toggle("Dark Mode", isOn: $isDarkMode)
                        .accessibilityLabel("Dark Mode Toggle")
                }
                
                // About Section.
                Section(header: Text("About").font(AppTheme.subtitleFont)) {
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
                
                // Account Management Section.
                Section(header: Text("Account Management").font(AppTheme.subtitleFont)) {
                    NavigationLink(destination: DeleteAccountView().environmentObject(authViewModel)) {
                        Text("Delete Account")
                            .foregroundColor(.red)
                    }
                }
                
                // Sign Out Section.
                Section {
                    Button(action: { authViewModel.signOut() }) {
                        Text("Log Out")
                    }
                    .buttonStyle(PrimaryButtonStyle(backgroundColor: .red))
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
                .font(AppTheme.titleFont)
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
