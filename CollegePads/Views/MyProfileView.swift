import SwiftUI
import FirebaseAuth

struct MyProfileView: View {
    @StateObject private var viewModel = ProfileViewModel.shared
    
    // For picking a new profile image
    @State private var showingImagePicker = false
    @State private var newProfileImage: UIImage?
    
    // MARK: - Additional Profile Fields (inline editing)
    // Merged from ProfileSetupView logic:
    @State private var selectedGradeLevel: GradeLevel = .freshman
    @State private var major: String = ""
    @State private var collegeName: String = ""
    @State private var budgetRange: String = ""
    @State private var cleanliness: Int = 3
    @State private var sleepSchedule: String = "Flexible"
    @State private var smoker: Bool = false
    @State private var petFriendly: Bool = false
    @State private var interestsText: String = ""
    
    // Enums from ProfileSetupView
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
    @State private var selectedHousingStatus: HousingStatus = .dorm
    @State private var selectedLeaseDuration: LeaseDuration = .notApplicable
    
    let sleepScheduleOptions = ["Early Bird", "Night Owl", "Flexible"]
    
    var body: some View {
        ZStack {
            // Global background gradient.
            AppTheme.backgroundGradient.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    
                    // Profile Completion Meter
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
                    
                    // MARK: Multi-Image Carousel or Fallback Circle
                    if let imageUrls = viewModel.userProfile?.profileImageUrls, !imageUrls.isEmpty {
                        TabView {
                            ForEach(imageUrls.prefix(10), id: \.self) { urlString in
                                if let url = URL(string: urlString) {
                                    CardPreviewImage(url: url)
                                }
                            }
                        }
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                        .frame(height: 340)
                    } else {
                        // Fallback single circle image
                        Button {
                            showingImagePicker = true
                        } label: {
                            if let urlStr = viewModel.userProfile?.profileImageUrl,
                               let url = URL(string: urlStr) {
                                AsyncImage(url: url) { phase in
                                    if let image = phase.image {
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 150, height: 150)
                                            .clipShape(Circle())
                                            .overlay(Circle().stroke(AppTheme.primaryColor, lineWidth: 4))
                                            .shadow(radius: 4)
                                    } else {
                                        Image(systemName: "person.crop.circle")
                                            .resizable()
                                            .frame(width: 150, height: 150)
                                    }
                                }
                            } else {
                                Image(systemName: "person.crop.circle")
                                    .resizable()
                                    .frame(width: 150, height: 150)
                            }
                        }
                    }
                    
                    // Card preview: how others see you
                    ProfileCardPreviewSection()
                    
                    // Inline editing fields from ProfileSetupView
                    InlineEditingSection()
                    
                    // Button to pick a new image
                    Button(action: {
                        showingImagePicker = true
                    }) {
                        Text("Upload Another Image")
                            .font(AppTheme.bodyFont)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(AppTheme.primaryColor)
                            .cornerRadius(AppTheme.defaultCornerRadius)
                    }
                    .padding(.horizontal)
                }
                .padding()
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("My Profile")
                    .font(AppTheme.titleFont)
                    .foregroundColor(.primary)
            }
        }
        // Image picker for new profile images
        .sheet(isPresented: $showingImagePicker, onDismiss: {
            guard let newImg = newProfileImage else { return }
            // Upload the new image and add to profileImageUrls
            viewModel.uploadProfileImage(image: newImg) { result in
                switch result {
                case .success(let downloadURL):
                    // Insert the new URL at the front
                    var updatedProfile = viewModel.userProfile ?? defaultUserProfile()
                    var urls = updatedProfile.profileImageUrls ?? []
                    urls.insert(downloadURL, at: 0)
                    if urls.count > 10 { urls = Array(urls.prefix(10)) }
                    updatedProfile.profileImageUrls = urls
                    // Optionally set profileImageUrl for fallback
                    if updatedProfile.profileImageUrl == nil {
                        updatedProfile.profileImageUrl = downloadURL
                    }
                    // Save changes
                    viewModel.updateUserProfile(updatedProfile: updatedProfile) { res in
                        switch res {
                        case .success:
                            print("Profile images updated successfully.")
                        case .failure(let error):
                            print("Failed to update images: \(error.localizedDescription)")
                        }
                    }
                case .failure(let error):
                    print("Image upload error: \(error.localizedDescription)")
                }
                newProfileImage = nil
            }
        }) {
            ImagePicker(image: $newProfileImage)
        }
        .onAppear {
            viewModel.loadUserProfile()
        }
        .onReceive(viewModel.$userProfile) { profile in
            guard let p = profile else { return }
            // Populate local states
            major = p.major ?? ""
            collegeName = p.collegeName ?? ""
            budgetRange = p.budgetRange ?? ""
            cleanliness = p.cleanliness ?? 3
            sleepSchedule = p.sleepSchedule ?? "Flexible"
            smoker = p.smoker ?? false
            petFriendly = p.petFriendly ?? false
            interestsText = (p.interests ?? []).joined(separator: ", ")
            // Grade level & housing
            selectedGradeLevel = GradeLevel(rawValue: p.gradeLevel ?? "") ?? .freshman
            selectedHousingStatus = HousingStatus(rawValue: p.housingStatus ?? "") ?? .other
            selectedLeaseDuration = LeaseDuration(rawValue: p.leaseDuration ?? "") ?? .notApplicable
        }
    }
    
    /// Displays a single card image in the style of your swipe card
    @ViewBuilder
    private func CardPreviewImage(url: URL) -> some View {
        AsyncImage(url: url) { phase in
            if let image = phase.image {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 300, height: 320)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .shadow(radius: 5)
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 300, height: 320)
                    .foregroundColor(.gray)
            }
        }
    }
    
    /// A preview card section, similar to CandidateProfileView
    @ViewBuilder
    private func ProfileCardPreviewSection() -> some View {
        if let profile = viewModel.userProfile {
            VStack(alignment: .leading, spacing: 8) {
                Text(profile.email)
                    .font(AppTheme.bodyFont)
                if let grade = profile.gradeLevel {
                    Text("Grade: \(grade)")
                        .font(AppTheme.bodyFont)
                }
                if let major = profile.major {
                    Text("Major: \(major)")
                        .font(AppTheme.bodyFont)
                }
                if let college = profile.collegeName {
                    Text("College: \(college)")
                        .font(AppTheme.bodyFont)
                }
                if let budget = profile.budgetRange {
                    Text("Budget: \(budget)")
                        .font(AppTheme.bodyFont)
                }
                if let cleanliness = profile.cleanliness {
                    Text("Cleanliness: \(cleanliness)/5")
                        .font(AppTheme.bodyFont)
                }
                if let schedule = profile.sleepSchedule {
                    Text("Sleep Schedule: \(schedule)")
                        .font(AppTheme.bodyFont)
                }
                if let smoke = profile.smoker {
                    Text("Smoker: \(smoke ? "Yes" : "No")")
                        .font(AppTheme.bodyFont)
                }
                if let pets = profile.petFriendly {
                    Text("Pet Friendly: \(pets ? "Yes" : "No")")
                        .font(AppTheme.bodyFont)
                }
            }
            .padding()
            .background(AppTheme.cardBackground)
            .cornerRadius(15)
            .shadow(radius: 5)
        }
    }
    
    /// Inline editing section from ProfileSetupView
    @ViewBuilder
    private func InlineEditingSection() -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Picker("Grade Level", selection: $selectedGradeLevel) {
                ForEach(GradeLevel.allCases) { level in
                    Text(level.rawValue).tag(level)
                }
            }
            .onChange(of: selectedGradeLevel) { _ in autoSaveProfile() }
            
            TextField("Major (e.g., Computer Science)", text: $major)
                .padding(AppTheme.defaultPadding)
                .background(AppTheme.cardBackground)
                .cornerRadius(AppTheme.defaultCornerRadius)
                .onChange(of: major) { _ in autoSaveProfile() }
            
            TextField("College Name (e.g., Engineering)", text: $collegeName)
                .padding(AppTheme.defaultPadding)
                .background(AppTheme.cardBackground)
                .cornerRadius(AppTheme.defaultCornerRadius)
                .onChange(of: collegeName) { _ in autoSaveProfile() }
            
            Picker("Housing Status", selection: $selectedHousingStatus) {
                ForEach(HousingStatus.allCases) { status in
                    Text(status.rawValue).tag(status)
                }
            }
            .onChange(of: selectedHousingStatus) { _ in autoSaveProfile() }
            
            if selectedHousingStatus == .apartment ||
               selectedHousingStatus == .house ||
               selectedHousingStatus == .subleasing ||
               selectedHousingStatus == .lookingForLease {
                Picker("Lease Duration", selection: $selectedLeaseDuration) {
                    ForEach(LeaseDuration.allCases) { duration in
                        Text(duration.rawValue).tag(duration)
                    }
                }
                .onChange(of: selectedLeaseDuration) { _ in autoSaveProfile() }
            }
            
            TextField("Budget Range (e.g., $500 - $1000)", text: $budgetRange)
                .padding(AppTheme.defaultPadding)
                .background(AppTheme.cardBackground)
                .cornerRadius(AppTheme.defaultCornerRadius)
                .onChange(of: budgetRange) { _ in autoSaveProfile() }
            
            Picker("Cleanliness (1=Very Messy, 5=Very Tidy)", selection: $cleanliness) {
                ForEach(1..<6) { number in
                    Text({
                        switch number {
                        case 1: return "1 - Very Messy"
                        case 2: return "2 - Messy"
                        case 3: return "3 - Average"
                        case 4: return "4 - Tidy"
                        case 5: return "5 - Very Tidy"
                        default: return "\(number)"
                        }
                    }())
                    .tag(number)
                }
            }
            .onChange(of: cleanliness) { _ in
                autoSaveProfile()
            }
            
            Picker("Sleep Schedule", selection: $sleepSchedule) {
                ForEach(sleepScheduleOptions, id: \.self) { option in
                    Text(option)
                }
            }
            .onChange(of: sleepSchedule) { _ in autoSaveProfile() }
            
            Toggle("Smoker", isOn: $smoker)
                .onChange(of: smoker) { _ in autoSaveProfile() }
            
            Toggle("Pet Friendly", isOn: $petFriendly)
                .onChange(of: petFriendly) { _ in autoSaveProfile() }
            
            TextField("Interests (comma-separated)", text: $interestsText)
                .autocapitalization(.none)
                .padding(AppTheme.defaultPadding)
                .background(AppTheme.cardBackground)
                .cornerRadius(AppTheme.defaultCornerRadius)
                .onChange(of: interestsText) { _ in autoSaveProfile() }
        }
        .padding()
        .background(AppTheme.cardBackground.opacity(0.8))
        .cornerRadius(15)
        .shadow(radius: 5)
    }
    
    /// Auto-saves the profile by constructing an updated user object and calling updateUserProfile.
    private func autoSaveProfile() {
        guard var updatedProfile = viewModel.userProfile else {
            print("No user profile loaded yet.")
            return
        }
        
        let interestsArray = interestsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        
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
                print("Profile auto-saved successfully.")
            case .failure(let error):
                print("Error auto-saving profile: \(error.localizedDescription)")
            }
        }
    }
    
    /// Minimal fallback if userProfile doesn't exist
    private func defaultUserProfile() -> UserModel {
        UserModel(email: Auth.auth().currentUser?.email ?? "unknown@unknown.com", isEmailVerified: false)
    }
}
