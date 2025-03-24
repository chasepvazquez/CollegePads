import SwiftUI

struct QuizView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var profileVM = ProfileViewModel.shared
    
    // Quiz answers (scale 1-5)
    @State private var socialLevel: Double = 3
    @State private var studyHabits: Double = 3
    @State private var isSubmitting: Bool = false
    @State private var showSuccessAlert: Bool = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("How Social Are You?")
                            .font(AppTheme.subtitleFont)) {
                    Text("Rate from 1 (very introverted) to 5 (extremely social)")
                        .font(AppTheme.bodyFont)
                    Slider(value: $socialLevel, in: 1...5, step: 1)
                    Text("Your rating: \(Int(socialLevel))")
                        .font(AppTheme.bodyFont)
                }
                
                Section(header: Text("How Rigorous Are Your Study Habits?")
                            .font(AppTheme.subtitleFont)) {
                    Text("Rate from 1 (rarely study) to 5 (studies intensively)")
                        .font(AppTheme.bodyFont)
                    Slider(value: $studyHabits, in: 1...5, step: 1)
                    Text("Your rating: \(Int(studyHabits))")
                        .font(AppTheme.bodyFont)
                }
                
                Button(action: saveQuizResults) {
                    if isSubmitting {
                        ProgressView()
                    } else {
                        Text("Submit Quiz")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .buttonStyle(PrimaryButtonStyle(backgroundColor: AppTheme.primaryColor))
                .disabled(isSubmitting)
            }
            .scrollContentBackground(.hidden)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Roommate Quiz")
                        .font(AppTheme.titleFont)
                        .foregroundColor(.primary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .font(AppTheme.bodyFont)
                }
            }
            .alert(isPresented: $showSuccessAlert) {
                Alert(title: Text("Success"),
                      message: Text("Your quiz results have been saved."),
                      dismissButton: .default(Text("OK"), action: {
                          presentationMode.wrappedValue.dismiss()
                      }))
            }
        }
    }
    
    private func saveQuizResults() {
        isSubmitting = true
        if var profile = profileVM.userProfile {
            profile.socialLevel = Int(socialLevel)
            profile.studyHabits = Int(studyHabits)
            profileVM.updateUserProfile(updatedProfile: profile) { result in
                DispatchQueue.main.async {
                    isSubmitting = false
                    switch result {
                    case .success:
                        showSuccessAlert = true
                    case .failure(let error):
                        print("Error updating quiz results: \(error.localizedDescription)")
                    }
                }
            }
        } else {
            let newProfile = UserModel(
                email: "", // Should be updated from current auth user
                isEmailVerified: false,
                socialLevel: Int(socialLevel),
                studyHabits: Int(studyHabits)
            )
            profileVM.updateUserProfile(updatedProfile: newProfile) { result in
                DispatchQueue.main.async {
                    isSubmitting = false
                    switch result {
                    case .success:
                        showSuccessAlert = true
                    case .failure(let error):
                        print("Error creating profile with quiz results: \(error.localizedDescription)")
                    }
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
