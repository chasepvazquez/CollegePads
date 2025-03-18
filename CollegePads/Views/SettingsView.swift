//
//  SettingsView.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//

import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @ObservedObject var profileVM = ProfileViewModel.shared
    @State private var showVerification = false
    @State private var showBlockedUsers = false

    var body: some View {
        NavigationView {
            Form {
                // Account Information Section
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
                
                // Blocked Users Section
                Section(header: Text("Privacy")) {
                    NavigationLink(destination: BlockedUsersView()) {
                        Text("Manage Blocked Users")
                    }
                }
                
                // Sign Out Section
                Section {
                    Button(action: {
                        authViewModel.signOut()
                    }) {
                        Text("Log Out")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showVerification) {
                // Present your VerificationView for account verification.
                VerificationView()
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SettingsView()
                .environmentObject(AuthViewModel())
        }
    }
}
