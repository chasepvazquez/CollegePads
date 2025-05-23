import SwiftUI
import FirebaseAuth

/// ProfileSetupOnboardingView – displays pages 3–5: Name, Birthday, and Create Profile.
/// This view is presented only after a user is signed in and their profile is incomplete.
struct ProfileSetupOnboardingView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = ProfileViewModel.shared
    
    // Tracks the current page (3 to 5).
    @State private var currentPage: Int = 3
    
    // Profile setup fields.
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var birthDate: Date = Date()
    @State private var selectedGender: Gender = .other
    @State private var showAgeAlert: Bool = false
    
    // MARK: - Gender Enum
    enum Gender: String, CaseIterable, Identifiable {
        case male = "Male"
        case female = "Female"
        case other = "Other"
        var id: String { self.rawValue }
    }

    
    var body: some View {
        Group {
            // 1) Still loading the profile? Show a spinner.
            if viewModel.userProfile == nil {
                ProgressView("Loading…")
                    .onAppear { /* let your snapshotPublisher fill in userProfile */ }
                
                // 2) Profile loaded *and* skip-check passes?  Bail out immediately.
            } else if shouldSkipOnboarding() {
                Color.clear
                    .onAppear {
                        // mark as done so RootView’s .fullScreenCover goes away
                        UserDefaults.standard.set(true, forKey: "onboardingCompleted")
                        presentationMode.wrappedValue.dismiss()
                    }
                
                // 3) Otherwise—render your existing onboarding UI.
            } else {
                ZStack {
                    AppTheme.backgroundGradient.ignoresSafeArea()
                    VStack(spacing: 30) {
                        if currentPage == 3 {
                            OnboardingNameView(
                                firstName: $firstName,
                                lastName: $lastName,
                                onContinue: { withAnimation { currentPage += 1 } },
                                onCancel:  { presentationMode.wrappedValue.dismiss() }
                            )
                        } else if currentPage == 4 {
                            OnboardingBirthdayView(
                                birthDate: $birthDate,
                                onContinue: {
                                    if calculateAge(from: birthDate) < 16 {
                                        showAgeAlert = true
                                    } else {
                                        withAnimation { currentPage += 1 }
                                    }
                                },
                                onCancel:  { withAnimation { currentPage -= 1 } }
                            )
                        } else {
                            OnboardingCreateProfileView(
                                firstName: $firstName,
                                lastName: $lastName,
                                birthDate: $birthDate,
                                selectedGender: $selectedGender,
                                onContinue: {
                                    saveProfileFields()
                                    UserDefaults.standard.set(true, forKey: "onboardingCompleted")
                                    presentationMode.wrappedValue.dismiss()
                                }
                            )
                        }
                        Spacer()
                    }
                    .padding()
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            Text("Profile Setup")
                                .font(AppTheme.titleFont)
                                .foregroundColor(.primary)
                        }
                    }
                }
                .alert("Age Restriction",
                       isPresented: $showAgeAlert,
                       actions: { Button("OK", role: .cancel) { } },
                       message: { Text("You must be at least 16 years old to create an account.") }
                )
            }
        }
    }
        
        // MARK: - Helper Functions
        
        /// Pre-fills fields from the existing profile if available.
        private func prefillFromExistingProfile() {
            guard let profile = viewModel.userProfile else { return }
            firstName = profile.firstName ?? ""
            lastName  = profile.lastName  ?? ""
            if let dob = dateFromString(profile.dateOfBirth ?? "") {
              birthDate = dob
            }
            if let g = Gender(rawValue: profile.gender ?? "") {
              selectedGender = g
            }
          }
        /// Returns true only if firstName, lastName, and dateOfBirth are non‐empty.
        private func shouldSkipOnboarding() -> Bool {
            guard let profile = viewModel.userProfile else { return false }
            let fnOK  = !(profile.firstName?.trimmingCharacters(in: .whitespaces).isEmpty ?? true)
            let lnOK  = !(profile.lastName?.trimmingCharacters(in: .whitespaces).isEmpty ?? true)
            let dobOK = !(profile.dateOfBirth?.trimmingCharacters(in: .whitespaces).isEmpty ?? true)
            return fnOK && lnOK && dobOK
        }
        
        private func dateFromString(_ str: String) -> Date? {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.date(from: str)
        }
        
        private func stringFromDate(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.string(from: date)
        }
        
        private func calculateAge(from birthDate: Date) -> Int {
            let now = Date()
            let calendar = Calendar.current
            let ageComponents = calendar.dateComponents([.year], from: birthDate, to: now)
            return ageComponents.year ?? 0
        }
        
        private func saveProfileFields() {
            if var profile = viewModel.userProfile {
                profile.firstName = firstName
                profile.lastName = lastName
                profile.dateOfBirth = stringFromDate(birthDate)
                profile.gender = selectedGender.rawValue
                viewModel.updateUserProfile(updatedProfile: profile) { result in
                    switch result {
                    case .success:
                        print("Profile updated successfully.")
                    case .failure(let error):
                        print("Error updating profile: \(error.localizedDescription)")
                    }
                }
            } else {
                let newProfile = UserModel(
                    email: Auth.auth().currentUser?.email ?? "unknown@unknown.com",
                    isEmailVerified: false,
                    firstName: firstName,
                    lastName: lastName,
                    dateOfBirth: stringFromDate(birthDate),
                    gender: selectedGender.rawValue
                )
                viewModel.updateUserProfile(updatedProfile: newProfile) { result in
                    switch result {
                    case .success:
                        print("Profile created successfully.")
                    case .failure(let error):
                        print("Error creating profile: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    struct ProfileSetupOnboardingView_Previews: PreviewProvider {
        static var previews: some View {
            ProfileSetupOnboardingView()
        }
    }
    
    /// MARK: - OnboardingNameView
    struct OnboardingNameView: View {
        @Binding var firstName: String
        @Binding var lastName: String
        let onContinue: () -> Void
        let onCancel: () -> Void
        
        var body: some View {
            VStack(spacing: 20) {
                Text("What’s your Name?")
                    .font(AppTheme.titleFont)
                    .padding(.top, 40)
                
                Text("Please enter your name. This is how you'll be greeted in the app.")
                    .font(AppTheme.bodyFont)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                VStack(spacing: 12) {
                    TextField("First Name", text: $firstName)
                        .padding()
                        .background(AppTheme.cardBackground)
                        .cornerRadius(AppTheme.defaultCornerRadius)
                    
                    TextField("Last Name", text: $lastName)
                        .padding()
                        .background(AppTheme.cardBackground)
                        .cornerRadius(AppTheme.defaultCornerRadius)
                }
                .padding(.horizontal)
                
                Button(action: onContinue) {
                    Text("Continue")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding()
            }
        }
    }
    
    /// MARK: - OnboardingBirthdayView
    struct OnboardingBirthdayView: View {
        @Binding var birthDate: Date
        let onContinue: () -> Void
        let onCancel: () -> Void
        
        var body: some View {
            VStack(spacing: 20) {
                HStack {
                    Spacer()
                    Button("Cancel") {
                        onCancel()
                    }
                    .foregroundColor(.red)
                }
                .padding()
                
                Text("Enter your birthday")
                    .font(AppTheme.titleFont)
                    .padding(.top, 40)
                
                DatePicker("", selection: $birthDate, displayedComponents: .date)
                    .datePickerStyle(WheelDatePickerStyle())
                    .labelsHidden()
                    .padding()
                
                Spacer()
                
                Text("By proceeding, you agree to our Terms of Service and Privacy Policy.")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 40)
                
                Button(action: onContinue) {
                    Text("Continue")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding()
            }
        }
    }
    
    /// MARK: - OnboardingCreateProfileView
struct OnboardingCreateProfileView: View {
    @Binding var firstName: String
    @Binding var lastName: String
    @Binding var birthDate: Date
    @Binding var selectedGender: ProfileSetupOnboardingView.Gender
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Create your profile")
                .font(AppTheme.titleFont)
                .padding(.top, 40)
            
            Text("This is your profile. Fill in the details so others can know you better.")
                .font(AppTheme.bodyFont)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                HStack {
                    Text("Name: \(firstName) \(lastName)")
                        .font(AppTheme.bodyFont)
                    Spacer()
                }
                .padding()
                .background(AppTheme.cardBackground)
                .cornerRadius(AppTheme.defaultCornerRadius)
                
                HStack {
                    Text("DOB: \(displayDate(birthDate))")
                        .font(AppTheme.bodyFont)
                    Spacer()
                }
                .padding()
                .background(AppTheme.cardBackground)
                .cornerRadius(AppTheme.defaultCornerRadius)
                
                Picker("I am:", selection: $selectedGender) {
                    ForEach(ProfileSetupOnboardingView.Gender.allCases) { gender in
                        Text(gender.rawValue).tag(gender)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                .background(AppTheme.cardBackground)
                .cornerRadius(AppTheme.defaultCornerRadius)
            }
            .padding(.horizontal)
            
            Spacer()
            
            Button(action: onContinue) {
                Text("Continue")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding()
        }
    }
    
    private func displayDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}
    
