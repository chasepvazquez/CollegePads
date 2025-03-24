import SwiftUI
import FirebaseAuth

struct ProfileSetupView: View {
    @StateObject private var viewModel = ProfileViewModel.shared

    // MARK: - Freeform Fields
    @State private var major: String = ""
    @State private var collegeName: String = ""
    @State private var interestsText: String = ""
    @State private var budgetRange: String = ""
    
    // Other freeform fields
    @State private var cleanliness: Int = 3
    @State private var sleepSchedule: String = "Flexible"
    @State private var smoker: Bool = false
    @State private var petFriendly: Bool = false

    // MARK: - Finite Options (Pickers)
    enum GradeLevel: String, CaseIterable, Identifiable {
        case freshman = "Freshman"
        case sophomore = "Sophomore"
        case junior = "Junior"
        case senior = "Senior"
        case graduate = "Graduate"
        case phd = "PhD"
        case other = "Other"
        var id: String { self.rawValue }
    }
    @State private var selectedGradeLevel: GradeLevel = .freshman
    
    enum HousingStatus: String, CaseIterable, Identifiable {
        case dorm = "Dorm Resident"
        case apartment = "Apartment Resident"
        case house = "House Owner/Renter"
        case subleasing = "Subleasing"
        case lookingForRoommate = "Looking for Roommate"
        case lookingForLease = "Looking for Lease"
        case other = "Other"
        var id: String { self.rawValue }
    }
    @State private var selectedHousingStatus: HousingStatus = .dorm
    
    enum LeaseDuration: String, CaseIterable, Identifiable {
        case current = "Current Lease"
        case shortTerm = "Short Term (<6 months)"
        case mediumTerm = "Medium Term (6-12 months)"
        case longTerm = "Long Term (1 year+)"
        case futureNextYear = "Future: Next Year"
        case futureTwoPlus = "Future: 2+ Years"
        case notApplicable = "Not Applicable"
        var id: String { self.rawValue }
    }
    @State private var selectedLeaseDuration: LeaseDuration = .notApplicable

    // MARK: - Profile Image
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    
    // MARK: - Freeform Options for Sleep Schedule
    let sleepScheduleOptions = ["Early Bird", "Night Owl", "Flexible"]

    var body: some View {
        ZStack {
            // Global background gradient.
            AppTheme.backgroundGradient.ignoresSafeArea()
            
            // Remove the inner NavigationView. The parent (or app coordinator)
            // should provide the navigation container.
            Form {
                // Profile Completion Meter Section
                if let profile = viewModel.userProfile {
                    let completion = ProfileCompletionCalculator.calculateCompletion(for: profile)
                    VStack(alignment: .leading) {
                        Text("Profile Completion: \(Int(completion))%")
                            .font(AppTheme.bodyFont)
                        ProgressView(value: completion, total: 100)
                            .accentColor(AppTheme.primaryColor)
                    }
                    .padding(.vertical, 8)
                }
                
                // Profile Picture Section
                Section(header: Text("Profile Picture")
                            .font(AppTheme.subtitleFont)) {
                    HStack {
                        Spacer()
                        if let image = selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .onTapGesture { showingImagePicker = true }
                        } else if let urlStr = viewModel.userProfile?.profileImageUrl,
                                  let url = URL(string: urlStr) {
                            AsyncImage(url: url) { phase in
                                if let image = phase.image {
                                    image.resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 120, height: 120)
                                        .clipShape(Circle())
                                        .onTapGesture { showingImagePicker = true }
                                } else {
                                    Image(systemName: "person.crop.circle")
                                        .resizable()
                                        .frame(width: 120, height: 120)
                                        .onTapGesture { showingImagePicker = true }
                                }
                            }
                        } else {
                            Image(systemName: "person.crop.circle")
                                .resizable()
                                .frame(width: 120, height: 120)
                                .onTapGesture { showingImagePicker = true }
                        }
                        Spacer()
                    }
                }
                
                // Basic Info Section
                Section(header: Text("Basic Info")
                            .font(AppTheme.subtitleFont)) {
                    Picker("Grade Level", selection: $selectedGradeLevel) {
                        ForEach(GradeLevel.allCases) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                    TextField("Major (e.g., Computer Science)", text: $major)
                        .padding(AppTheme.defaultPadding)
                        .background(AppTheme.cardBackground)
                        .cornerRadius(AppTheme.defaultCornerRadius)
                    TextField("College Name (e.g., Engineering)", text: $collegeName)
                        .padding(AppTheme.defaultPadding)
                        .background(AppTheme.cardBackground)
                        .cornerRadius(AppTheme.defaultCornerRadius)
                    TextField("Email", text: .constant(viewModel.userProfile?.email ?? ""))
                        .disabled(true)
                        .padding(AppTheme.defaultPadding)
                        .background(AppTheme.cardBackground)
                        .cornerRadius(AppTheme.defaultCornerRadius)
                }
                
                // Housing Preferences Section
                Section(header: Text("Housing Preferences")
                            .font(AppTheme.subtitleFont)) {
                    Picker("Housing Status", selection: $selectedHousingStatus) {
                        ForEach(HousingStatus.allCases) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }
                    
                    if selectedHousingStatus == .apartment ||
                       selectedHousingStatus == .house ||
                       selectedHousingStatus == .subleasing ||
                       selectedHousingStatus == .lookingForLease {
                        Picker("Lease Duration", selection: $selectedLeaseDuration) {
                            ForEach(LeaseDuration.allCases) { duration in
                                Text(duration.rawValue).tag(duration)
                            }
                        }
                    }
                    
                    TextField("Budget Range (e.g., $500 - $1000)", text: $budgetRange)
                        .padding(AppTheme.defaultPadding)
                        .background(AppTheme.cardBackground)
                        .cornerRadius(AppTheme.defaultCornerRadius)
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
                
                // Interests Section
                Section(header: Text("Interests")
                            .font(AppTheme.subtitleFont)) {
                    TextField("Enter interests separated by commas", text: $interestsText)
                        .autocapitalization(.none)
                        .padding(AppTheme.defaultPadding)
                        .background(AppTheme.cardBackground)
                        .cornerRadius(AppTheme.defaultCornerRadius)
                }
                
                // Save Button Section
                Section {
                    Button(action: saveProfile) {
                        Text("Save Profile")
                            .font(AppTheme.bodyFont)
                            .foregroundColor(.white)
                            .padding(AppTheme.defaultPadding)
                            .frame(maxWidth: .infinity)
                            .background(AppTheme.primaryColor)
                            .cornerRadius(AppTheme.defaultCornerRadius)
                    }
                }
            }
            // Hide Form's default background and apply global font.
            .scrollContentBackground(.hidden)
            .font(AppTheme.bodyFont)
            .onAppear {
                viewModel.loadUserProfile()
            }
            .onReceive(viewModel.$userProfile) { profile in
                guard let profile = profile else { return }
                selectedGradeLevel = GradeLevel(rawValue: profile.gradeLevel ?? "") ?? .freshman
                major = profile.major ?? ""
                collegeName = profile.collegeName ?? ""
                selectedHousingStatus = HousingStatus(rawValue: profile.housingStatus ?? "") ?? .other
                selectedLeaseDuration = LeaseDuration(rawValue: profile.leaseDuration ?? "") ?? .notApplicable
                budgetRange = profile.budgetRange ?? ""
                cleanliness = profile.cleanliness ?? 3
                sleepSchedule = profile.sleepSchedule ?? "Flexible"
                smoker = profile.smoker ?? false
                petFriendly = profile.petFriendly ?? false
                interestsText = profile.interests?.joined(separator: ", ") ?? ""
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedImage)
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Profile Setup")
                        .font(AppTheme.titleFont)
                        .foregroundColor(.primary)
                }
            }
        }
        // Ensure NavigationView style and clear background if this view is embedded in one.
        .navigationViewStyle(StackNavigationViewStyle())
        .background(Color.clear)
    }
    
    private func saveProfile() {
        let interestsArray = interestsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        
        var updatedProfile = viewModel.userProfile ?? UserModel(email: Auth.auth().currentUser?.email ?? "", isEmailVerified: false)
        updatedProfile.gradeLevel = selectedGradeLevel.rawValue
        updatedProfile.major = major
        updatedProfile.collegeName = collegeName
        updatedProfile.budgetRange = budgetRange
        updatedProfile.cleanliness = cleanliness
        updatedProfile.sleepSchedule = sleepSchedule
        updatedProfile.smoker = smoker
        updatedProfile.petFriendly = petFriendly
        updatedProfile.interests = interestsArray
        updatedProfile.housingStatus = selectedHousingStatus.rawValue
        updatedProfile.leaseDuration = selectedLeaseDuration.rawValue
        
        viewModel.updateUserProfile(updatedProfile: updatedProfile) { result in
            switch result {
            case .success:
                print("Profile successfully updated.")
            case .failure(let error):
                print("Error updating profile: \(error.localizedDescription)")
            }
        }
    }
}

struct ProfileSetupView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileSetupView()
    }
}
