import SwiftUI
import FirebaseAuth

/// Data model for tutorial pages.
struct OnboardingPage {
    let title: String
    let description: String
    let imageName: String
}

/// Main Onboarding View: displays 6 pages in order.
/// Pages 0–2: Tutorial (swipeable).
/// Pages 3–5: Profile setup.
/// When onboarding is complete, the view is dismissed so that RootView shows the sign‑in/signup view.
struct OnboardingView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = ProfileViewModel.shared
    
    // Tracks which page (0 to 5) is active.
    @State private var currentPage: Int = 0
    
    // Tutorial pages (pages 0-2)
    private let tutorialPages: [OnboardingPage] = [
        OnboardingPage(title: "Welcome to CollegePads",
                       description: "Find your perfect roommate easily!",
                       imageName: "person.3.fill"),
        OnboardingPage(title: "Swipe to Match",
                       description: "Swipe right to like, left to pass, just like Tinder!",
                       imageName: "hand.point.right.fill"),
        OnboardingPage(title: "Chat & Connect",
                       description: "Start chatting once you match with someone!",
                       imageName: "message.fill")
    ]
    
    // Profile setup fields (pages 3-5)
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var birthDate: Date = Date()
    @State private var selectedGender: Gender = .other
    
    // MARK: - Gender Enum
    enum Gender: String, CaseIterable, Identifiable {
        case male = "Male"
        case female = "Female"
        case other = "Other"
        var id: String { self.rawValue }
    }
    
    // Alert for age check
    @State private var showAgeAlert: Bool = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundGradient.ignoresSafeArea()
                VStack(spacing: 30) {
                    if currentPage < 3 {
                        tutorialFlow
                    } else {
                        profileSetupFlow
                    }
                    Spacer()
                }
                .padding()
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("Onboarding")
                            .font(AppTheme.titleFont)
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .onAppear {
            prefillFromExistingProfile()
        }
        .alert(isPresented: $showAgeAlert) {
            Alert(title: Text("Age Restriction"),
                  message: Text("You must be at least 16 years old to create an account."),
                  dismissButton: .default(Text("OK")))
        }
    }
    
    // MARK: - Tutorial Flow (Pages 0–2)
    private var tutorialFlow: some View {
        VStack {
            TabView(selection: $currentPage) {
                ForEach(0..<tutorialPages.count, id: \.self) { index in
                    VStack(spacing: 20) {
                        Image(systemName: tutorialPages[index].imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 150, height: 150)
                            .foregroundColor(AppTheme.primaryColor)
                            .accessibilityHidden(true)
                        
                        Text(tutorialPages[index].title)
                            .font(AppTheme.titleFont)
                            .bold()
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Text(tutorialPages[index].description)
                            .font(AppTheme.bodyFont)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
            .frame(maxHeight: 400)
            
            // "Get Started" button on last tutorial page
            if currentPage == tutorialPages.count - 1 {
                Button(action: {
                    // Proceed to profile setup.
                    currentPage += 1 // now currentPage is 3
                }) {
                    Text("Get Started")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding()
            }
        }
    }
    
    // MARK: - Profile Setup Flow (Pages 3–5)
    private var profileSetupFlow: some View {
        VStack {
            if currentPage == 3 {
                // Onboarding Name View with hyperlink restored below Continue button.
                OnboardingNameView(
                    firstName: $firstName,
                    lastName: $lastName,
                    onContinue: { withAnimation { currentPage += 1 } },
                    onCancel: {
                        // Sign in action – dismiss onboarding to show authentication.
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            } else if currentPage == 4 {
                // Onboarding Birthday View with age check.
                OnboardingBirthdayView(
                    birthDate: $birthDate,
                    onContinue: {
                        if calculateAge(from: birthDate) < 16 {
                            showAgeAlert = true
                        } else {
                            withAnimation { currentPage += 1 }
                        }
                    },
                    onCancel: { withAnimation { currentPage -= 1 } }
                )
            } else {
                // Onboarding Create Profile View
                OnboardingCreateProfileView(
                    firstName: $firstName,
                    lastName: $lastName,
                    birthDate: $birthDate,
                    selectedGender: $selectedGender,
                    onContinue: {
                        saveProfileFields()
                        // Mark onboarding complete and dismiss to show sign in.
                        UserDefaults.standard.set(true, forKey: "onboardingCompleted")
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            }
        }
    }
    
    // MARK: - Helper Functions
    private func prefillFromExistingProfile() {
        if let profile = viewModel.userProfile {
            firstName = profile.firstName ?? ""
            lastName = profile.lastName ?? ""
            if let dobString = profile.dateOfBirth, !dobString.isEmpty,
               let dob = dateFromString(dobString) {
                birthDate = dob
            }
            if let gender = profile.gender, let g = Gender(rawValue: gender) {
                selectedGender = g
            }
        }
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

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
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
            // Removed hyperlink from top.
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
            
            // Hyperlink placed beneath the Continue button.
            Button(action: {
                onCancel()
            }) {
                Text("Already have an account? Sign in")
                    .font(AppTheme.bodyFont)
                    .underline()
                    .foregroundColor(AppTheme.primaryColor)
            }
            .padding(.bottom, 20)
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
    @Binding var selectedGender: OnboardingView.Gender
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
                    ForEach(OnboardingView.Gender.allCases) { gender in
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
