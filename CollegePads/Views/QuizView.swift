//
//  QuizView.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//

import SwiftUI

struct QuizView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var profileVM = ProfileViewModel.shared
    
    // Quiz answers (scale 1-5)
    @State private var socialLevel: Double = 3
    @State private var studyHabits: Double = 3
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("How Social Are You?")) {
                    Text("Rate from 1 (very introverted) to 5 (extremely social)")
                    Slider(value: $socialLevel, in: 1...5, step: 1)
                    Text("Your rating: \(Int(socialLevel))")
                }
                
                Section(header: Text("How Rigorous Are Your Study Habits?")) {
                    Text("Rate from 1 (rarely study) to 5 (studies intensively)")
                    Slider(value: $studyHabits, in: 1...5, step: 1)
                    Text("Your rating: \(Int(studyHabits))")
                }
                
                Button(action: saveQuizResults) {
                    Text("Submit Quiz")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(8)
                }
            }
            .navigationTitle("Roommate Quiz")
            .navigationBarItems(trailing: Button("Close") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func saveQuizResults() {
        // Update current user's profile with the quiz answers.
        if var profile = profileVM.userProfile {
            profile.socialLevel = Int(socialLevel)
            profile.studyHabits = Int(studyHabits)
            profileVM.updateUserProfile(updatedProfile: profile) { result in
                switch result {
                case .success:
                    // Dismiss view after successful update.
                    presentationMode.wrappedValue.dismiss()
                case .failure(let error):
                    print("Error updating quiz results: \(error.localizedDescription)")
                }
            }
        } else {
            // If no profile exists, create one with quiz results (minimal info).
            let newProfile = UserModel(
                email: "", // Should be filled from current auth user
                isEmailVerified: false, // Adjust accordingly
                socialLevel: Int(socialLevel),
                studyHabits: Int(studyHabits)
            )
            profileVM.updateUserProfile(updatedProfile: newProfile) { result in
                switch result {
                case .success:
                    presentationMode.wrappedValue.dismiss()
                case .failure(let error):
                    print("Error creating profile with quiz results: \(error.localizedDescription)")
                }
            }
        }
    }
}

struct QuizView_Previews: PreviewProvider {
    static var previews: some View {
        QuizView()
    }
}
