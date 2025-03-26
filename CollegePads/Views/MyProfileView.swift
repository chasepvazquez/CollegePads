import SwiftUI
import FirebaseAuth

struct MyProfileView: View {
    @StateObject private var viewModel = ProfileViewModel.shared

    // Image picker state
    @State private var showingImagePicker = false
    @State private var newProfileImage: UIImage?
    
    // Existing inline editing state variables
    @State private var selectedGradeLevel: GradeLevel = .freshman
    @State private var major: String = ""
    @State private var collegeName: String = ""
    @State private var budgetRange: String = ""
    @State private var cleanliness: Int = 3
    @State private var sleepSchedule: String = "Flexible"
    @State private var smoker: Bool = false
    @State private var petFriendly: Bool = false
    @State private var interestsText: String = ""
    @State private var selectedHousingStatus: HousingStatus = .dorm
    @State private var selectedLeaseDuration: LeaseDuration = .notApplicable
    
    // NEW FIELDS: Local states to handle firstName, lastName, dateOfBirth, and gender
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var dateOfBirth: String = ""
    @State private var gender: String = "Other" // "Male", "Female", or "Other"
    
    // Sleep schedule options
    let sleepScheduleOptions = ["Early Bird", "Night Owl", "Flexible"]
    
    // MARK: - Enumerations for Inline Editing
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
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    
                    // Header with blurred background using profile image and overlayed email
                    ProfileHeaderView(imageUrl: viewModel.userProfile?.profileImageUrl,
                                      email: viewModel.userProfile?.email ?? "Your Email")
                        .padding(.bottom, 10)
                    
                    // Profile completion meter (card-styled)
                    if let profile = viewModel.userProfile {
                        ProfileCompletionView(completion: ProfileCompletionCalculator.calculateCompletion(for: profile))
                    }
                    
                    // Multi-image carousel (Tinder-like card view) or fallback circular image
                    if let imageUrls = viewModel.userProfile?.profileImageUrls, !imageUrls.isEmpty {
                        ImageCarouselView(imageUrls: imageUrls)
                    } else {
                        ProfileImageFallbackView {
                            showingImagePicker = true
                        }
                    }
                    
                    // Profile card preview displaying key details (including new fields)
                    ProfileCardPreviewSection(profile: viewModel.userProfile)
                    
                    // Inline editing section including new fields and existing ones
                    InlineEditingSection()
                    
                    // Upload new image button (uses your custom PrimaryButtonStyle)
                    Button(action: {
                        showingImagePicker = true
                    }) {
                        Text("Upload Another Image")
                    }
                    .buttonStyle(PrimaryButtonStyle())
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
        // Image picker sheet to handle profile image uploads
        .sheet(isPresented: $showingImagePicker, onDismiss: {
            guard let newImg = newProfileImage else { return }
            viewModel.uploadProfileImage(image: newImg) { result in
                switch result {
                case .success(let downloadURL):
                    var updatedProfile = viewModel.userProfile ?? defaultUserProfile()
                    var urls = updatedProfile.profileImageUrls ?? []
                    urls.insert(downloadURL, at: 0)
                    if urls.count > 10 { urls = Array(urls.prefix(10)) }
                    updatedProfile.profileImageUrls = urls
                    if updatedProfile.profileImageUrl == nil {
                        updatedProfile.profileImageUrl = downloadURL
                    }
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
            // Populate new fields
            firstName = p.firstName ?? ""
            lastName = p.lastName ?? ""
            dateOfBirth = p.dateOfBirth ?? ""
            gender = p.gender ?? "Other"
            
            // Populate existing fields
            major = p.major ?? ""
            collegeName = p.collegeName ?? ""
            budgetRange = p.budgetRange ?? ""
            cleanliness = p.cleanliness ?? 3
            sleepSchedule = p.sleepSchedule ?? "Flexible"
            smoker = p.smoker ?? false
            petFriendly = p.petFriendly ?? false
            interestsText = (p.interests ?? []).joined(separator: ", ")
            selectedGradeLevel = GradeLevel(rawValue: p.gradeLevel ?? "") ?? .freshman
            selectedHousingStatus = HousingStatus(rawValue: p.housingStatus ?? "") ?? .other
            selectedLeaseDuration = LeaseDuration(rawValue: p.leaseDuration ?? "") ?? .notApplicable
        }
    }
    
    // MARK: - Nested Subviews
    
    /// Header view with a blurred background and overlay displaying the profile image and email.
    struct ProfileHeaderView: View {
        let imageUrl: String?
        let email: String
        
        var body: some View {
            ZStack {
                if let urlStr = imageUrl, let url = URL(string: urlStr) {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image.resizable()
                                .scaledToFill()
                                .frame(height: 250)
                                .clipped()
                                .overlay(Color.black.opacity(0.3))
                                .blur(radius: 5)
                        } else {
                            Color.gray
                        }
                    }
                } else {
                    Color.gray
                }
                VStack {
                    Spacer()
                    if let urlStr = imageUrl, let url = URL(string: urlStr) {
                        AsyncImage(url: url) { phase in
                            if let image = phase.image {
                                image.resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(AppTheme.primaryColor, lineWidth: 4))
                                    .shadow(radius: 6)
                            } else {
                                Image(systemName: "person.crop.circle")
                                    .resizable()
                                    .frame(width: 120, height: 120)
                                    .foregroundColor(.white)
                            }
                        }
                    } else {
                        Image(systemName: "person.crop.circle")
                            .resizable()
                            .frame(width: 120, height: 120)
                            .foregroundColor(.white)
                    }
                    Spacer().frame(height: 10)
                    Text(email)
                        .font(AppTheme.titleFont)
                        .foregroundColor(.white)
                        .shadow(radius: 3)
                    Spacer()
                }
                .frame(height: 250)
            }
            .cornerRadius(15)
            .padding(.horizontal)
        }
    }
    
    /// A card-styled view showing the profile completion percentage.
    struct ProfileCompletionView: View {
        let completion: Double
        
        var body: some View {
            VStack(alignment: .leading) {
                Text("Profile Completion: \(Int(completion))%")
                    .font(AppTheme.bodyFont)
                ProgressView(value: completion, total: 100)
                    .accentColor(AppTheme.primaryColor)
                    .scaleEffect(x: 1, y: 2, anchor: .center)
            }
            .padding(.vertical, 8)
            .padding(.horizontal)
            .background(AppTheme.cardBackground)
            .cornerRadius(15)
            .shadow(radius: 5)
        }
    }
    
    /// A carousel view for multiple profile images.
    struct ImageCarouselView: View {
        let imageUrls: [String]
        
        var body: some View {
            TabView {
                ForEach(imageUrls.prefix(10), id: \.self) { urlString in
                    if let url = URL(string: urlString) {
                        AsyncImage(url: url) { phase in
                            if let image = phase.image {
                                image.resizable()
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
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
            .frame(height: 340)
            .padding(.horizontal)
        }
    }
    
    /// Fallback view for when there are no multiple profile images.
    struct ProfileImageFallbackView: View {
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                Image(systemName: "person.crop.circle")
                    .resizable()
                    .frame(width: 150, height: 150)
                    .foregroundColor(.gray)
                    .overlay(Circle().stroke(AppTheme.primaryColor, lineWidth: 4))
            }
        }
    }
    
    /// A preview card showing key profile details, including new fields.
    @ViewBuilder
    func ProfileCardPreviewSection(profile: UserModel?) -> some View {
        if let profile = profile {
            VStack(alignment: .leading, spacing: 8) {
                // NEW FIELDS: Display firstName, lastName, dateOfBirth, and gender
                if let fn = profile.firstName, !fn.isEmpty,
                   let ln = profile.lastName, !ln.isEmpty {
                    Text("\(fn) \(ln)")
                        .font(AppTheme.bodyFont)
                }
                if let dob = profile.dateOfBirth, !dob.isEmpty {
                    Text("DOB: \(dob)")
                        .font(AppTheme.bodyFont)
                }
                if let g = profile.gender, !g.isEmpty {
                    Text("Gender: \(g)")
                        .font(AppTheme.bodyFont)
                }
                
                // Existing details
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
            .padding(.horizontal)
        }
    }
    
    /// Inline editing section that combines new and existing profile fields.
    @ViewBuilder
    func InlineEditingSection() -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Group {
                // NEW FIELDS: Editing for firstName, lastName, dateOfBirth, and gender
                TextField("First Name", text: $firstName)
                    .padding(AppTheme.defaultPadding)
                    .background(AppTheme.cardBackground)
                    .cornerRadius(AppTheme.defaultCornerRadius)
                    .onChange(of: firstName) { _ in autoSaveProfile() }
                
                TextField("Last Name", text: $lastName)
                    .padding(AppTheme.defaultPadding)
                    .background(AppTheme.cardBackground)
                    .cornerRadius(AppTheme.defaultCornerRadius)
                    .onChange(of: lastName) { _ in autoSaveProfile() }
                
                TextField("Date of Birth (YYYY-MM-DD)", text: $dateOfBirth)
                    .padding(AppTheme.defaultPadding)
                    .background(AppTheme.cardBackground)
                    .cornerRadius(AppTheme.defaultCornerRadius)
                    .onChange(of: dateOfBirth) { _ in autoSaveProfile() }
                
                Picker("Gender", selection: $gender) {
                    Text("Male").tag("Male")
                    Text("Female").tag("Female")
                    Text("Other").tag("Other")
                }
                .onChange(of: gender) { _ in autoSaveProfile() }
                .pickerStyle(SegmentedPickerStyle())
                
                // Existing fields below
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
                .onChange(of: cleanliness) { _ in autoSaveProfile() }
                
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
            .transition(.opacity.combined(with: .slide))
            .animation(.easeInOut(duration: 0.3), value: UUID())
        }
        .padding()
        .background(AppTheme.cardBackground.opacity(0.8))
        .cornerRadius(15)
        .shadow(radius: 5)
        .padding(.horizontal)
    }
    
    /// Auto-save function that updates the user profile with both new and existing fields.
    private func autoSaveProfile() {
        guard var updatedProfile = viewModel.userProfile else {
            print("No user profile loaded yet.")
            return
        }
        
        let interestsArray = interestsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        
        // NEW FIELDS update
        updatedProfile.firstName = firstName
        updatedProfile.lastName = lastName
        updatedProfile.dateOfBirth = dateOfBirth
        updatedProfile.gender = gender
        
        // Existing fields update
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
    
    /// Minimal fallback user profile if none exists.
    private func defaultUserProfile() -> UserModel {
        UserModel(email: Auth.auth().currentUser?.email ?? "unknown@unknown.com", isEmailVerified: false)
    }
}
