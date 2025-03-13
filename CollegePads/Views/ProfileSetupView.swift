//
//  ProfileSetupView.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//

import SwiftUI
import FirebaseAuth  // Needed for current user checks

struct ProfileSetupView: View {
    @StateObject private var viewModel = ProfileViewModel()
    
    // Local form fields
    @State private var dormType: String = ""
    @State private var budgetRange: String = ""
    @State private var cleanliness: Int = 3
    @State private var sleepSchedule: String = "Flexible"
    @State private var smoker: Bool = false
    @State private var petFriendly: Bool = false
    
    // Options for the sleep schedule picker
    let sleepScheduleOptions = ["Early Bird", "Night Owl", "Flexible"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Roommate Preferences")) {
                    TextField("Dorm Type (e.g., On-Campus, Off-Campus)", text: $dormType)
                    TextField("Budget Range (e.g., $500 - $1000)", text: $budgetRange)
                    
                    Picker("Cleanliness (1-5)", selection: $cleanliness) {
                        ForEach(1..<6) { number in
                            Text("\(number)").tag(number)
                        }
                    }
                    
                    Picker("Sleep Schedule", selection: $sleepSchedule) {
                        ForEach(sleepScheduleOptions, id: \.self) { option in
                            Text(option)
                        }
                    }
                    
                    Toggle("Smoker", isOn: $smoker)
                    Toggle("Pet Friendly", isOn: $petFriendly)
                }
                
                Section {
                    Button(action: saveProfile) {
                        Text("Save Profile")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationTitle("Profile Setup")
            .onAppear {
                viewModel.loadUserProfile()
            }
            // When userProfile changes, populate local fields
            .onReceive(viewModel.$userProfile) { profile in
                guard let profile = profile else { return }
                dormType = profile.dormType ?? ""
                budgetRange = profile.budgetRange ?? ""
                cleanliness = profile.cleanliness ?? 3
                sleepSchedule = profile.sleepSchedule ?? "Flexible"
                smoker = profile.smoker ?? false
                petFriendly = profile.petFriendly ?? false
            }
            // Show an alert if there's an error
            .alert(item: Binding(
                get: {
                    if let errorMessage = viewModel.errorMessage {
                        return ProfileAlertError(message: errorMessage)
                    }
                    return nil
                },
                set: { _ in viewModel.errorMessage = nil }
            )) { alertError in
                Alert(
                    title: Text("Error"),
                    message: Text(alertError.message),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    /// Saves the updated profile to Firestore.
    private func saveProfile() {
        // If we already have a user profile, update it;
        // otherwise, create a new one.
        if var existingProfile = viewModel.userProfile {
            // Update existing profile fields
            existingProfile.dormType = dormType
            existingProfile.budgetRange = budgetRange
            existingProfile.cleanliness = cleanliness
            existingProfile.sleepSchedule = sleepSchedule
            existingProfile.smoker = smoker
            existingProfile.petFriendly = petFriendly
            
            viewModel.updateUserProfile(updatedProfile: existingProfile) { result in
                switch result {
                case .success:
                    // Successfully saved
                    break
                case .failure(let error):
                    viewModel.errorMessage = error.localizedDescription
                }
            }
        } else {
            // Create a new profile if none exists yet
            let newProfile = UserModel(
                email: Auth.auth().currentUser?.email ?? "",
                isEmailVerified: Auth.auth().currentUser?.isEmailVerified ?? false,
                dormType: dormType,
                budgetRange: budgetRange,
                cleanliness: cleanliness,
                sleepSchedule: sleepSchedule,
                smoker: smoker,
                petFriendly: petFriendly
            )
            
            viewModel.updateUserProfile(updatedProfile: newProfile) { result in
                switch result {
                case .success:
                    // Successfully saved
                    break
                case .failure(let error):
                    viewModel.errorMessage = error.localizedDescription
                }
            }
        }
    }
}

/// A unique alert struct to avoid naming conflicts with `AlertError` in other files.
struct ProfileAlertError: Identifiable {
    let id = UUID()
    let message: String
}
