import SwiftUI
import PhotosUI
import FirebaseAuth

struct MyProfileView: View {
    @StateObject private var viewModel = ProfileViewModel.shared

    // MARK: - Photo Picker State
    @State private var showingPhotoPicker = false
    @State private var newProfileImage: UIImage? = nil
    @State private var tappedImageIndex: Int? = nil
    @State private var isPickerActive = false  // Tracks if picker is currently active

    // MARK: - Inline Editing State Variables
    @State private var selectedGradeLevel: GradeLevel = .freshman
    @State private var major = ""
    @State private var collegeName = ""
    @State private var budgetRange = ""
    @State private var cleanliness = 3
    @State private var sleepSchedule = "Flexible"
    @State private var smoker = false
    @State private var petFriendly = false
    @State private var interestsText = ""
    @State private var selectedHousingStatus: HousingStatus = .dorm
    @State private var selectedLeaseDuration: LeaseDuration = .notApplicable

    // MARK: - New Profile Fields
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var dateOfBirth = ""
    @State private var gender = "Other" // "Male", "Female", or "Other"

    // Sleep schedule options
    let sleepScheduleOptions = ["Early Bird", "Night Owl", "Flexible"]

    // Debouncer for autosave
    @State private var autoSaveWorkItem: DispatchWorkItem?

    // MARK: - Enumerations
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

    // MARK: - Body
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    if let profile = viewModel.userProfile {
                        ProfileCompletionView(
                            completion: ProfileCompletionCalculator.calculateCompletion(for: profile)
                        )
                    }
                    
                    MediaGridView(
                        imageUrls: viewModel.userProfile?.profileImageUrls ?? [],
                        onTapAddOrEdit: { index in
                            tappedImageIndex = index
                            newProfileImage = nil  // Clear any stale image
                            isPickerActive = true
                            viewModel.suspendUpdates = true  // Suspend external updates
                            showingPhotoPicker = true
                            print("MyProfileView: Tapped grid index \(index); presenting picker.")
                        },
                        onRemoveImage: { index in
                            removeImage(at: index)
                        }
                    )
                    
                    ProfileCardPreviewSection(profile: viewModel.userProfile)
                    InlineEditingSection()
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
        .onAppear {
            print("MyProfileView: onAppear called.")
            viewModel.loadUserProfile()
        }
        // Debounce external profile updates to prevent rapid state changes
        .onReceive(viewModel.$userProfile.debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)) { profile in
            if !isPickerActive, let p = profile {
                print("MyProfileView (debounced): userProfile updated (picker not active).")
                populateLocalFields(from: p)
            } else {
                print("MyProfileView (debounced): userProfile updated but picker is active.")
            }
        }
        .sheet(isPresented: $showingPhotoPicker, onDismiss: {
            isPickerActive = false
            viewModel.suspendUpdates = false  // Re-enable external updates
            print("MyProfileView: Photo picker dismissed.")
        }) {
            CustomImagePicker(image: $newProfileImage)
        }
        .onChange(of: newProfileImage) { image in
            print("MyProfileView: newProfileImage changed: \(String(describing: image)).")
            if image != nil {
                handlePhotoSelected()
            }
        }
    }

    // MARK: - Handle Photo Selection
    private func handlePhotoSelected() {
        guard let newImg = newProfileImage, let index = tappedImageIndex else {
            print("MyProfileView: No image or index selected.")
            return
        }
        print("MyProfileView: Uploading new image for grid index \(index)...")
        viewModel.uploadProfileImage(image: newImg) { result in
            switch result {
            case .success(let downloadURL):
                print("MyProfileView: Image uploaded: \(downloadURL)")
                var updatedProfile = viewModel.userProfile ?? defaultUserProfile()
                var urls = updatedProfile.profileImageUrls ?? []
                if index < urls.count {
                    urls[index] = downloadURL
                } else {
                    urls.append(downloadURL)
                }
                updatedProfile.profileImageUrls = Array(urls.prefix(9))
                updatedProfile.profileImageUrl = updatedProfile.profileImageUrls?.first
                viewModel.updateUserProfile(updatedProfile: updatedProfile) { res in
                    switch res {
                    case .success:
                        print("MyProfileView: Profile updated successfully at index \(index).")
                        viewModel.loadUserProfile()  // Refresh UI
                    case .failure(let error):
                        print("MyProfileView: Failed to update profile images: \(error.localizedDescription)")
                    }
                }
            case .failure(let error):
                print("MyProfileView: Image upload error: \(error.localizedDescription)")
            }
            newProfileImage = nil
        }
    }

    // MARK: - Remove Image
    private func removeImage(at index: Int) {
        guard var profile = viewModel.userProfile,
              var urls = profile.profileImageUrls, index < urls.count else { return }
        urls.remove(at: index)
        profile.profileImageUrls = urls
        profile.profileImageUrl = urls.first
        viewModel.updateUserProfile(updatedProfile: profile) { result in
            switch result {
            case .success:
                print("MyProfileView: Removed image at index \(index).")
            case .failure(let error):
                print("MyProfileView: Error removing image: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Populate Local Fields
    private func populateLocalFields(from profile: UserModel) {
        firstName = profile.firstName ?? ""
        lastName = profile.lastName ?? ""
        dateOfBirth = profile.dateOfBirth ?? ""
        gender = profile.gender ?? "Other"
        major = profile.major ?? ""
        collegeName = profile.collegeName ?? ""
        budgetRange = profile.budgetRange ?? ""
        cleanliness = profile.cleanliness ?? 3
        sleepSchedule = profile.sleepSchedule ?? "Flexible"
        smoker = profile.smoker ?? false
        petFriendly = profile.petFriendly ?? false
        interestsText = (profile.interests ?? []).joined(separator: ", ")
        selectedGradeLevel = GradeLevel(rawValue: profile.gradeLevel ?? "") ?? .freshman
        selectedHousingStatus = HousingStatus(rawValue: profile.housingStatus ?? "") ?? .other
        selectedLeaseDuration = LeaseDuration(rawValue: profile.leaseDuration ?? "") ?? .notApplicable
    }

    // MARK: - Provide a Fallback Profile
    private func defaultUserProfile() -> UserModel {
        UserModel(
            email: Auth.auth().currentUser?.email ?? "unknown@unknown.com",
            isEmailVerified: false
        )
    }

    // MARK: - Debounced Auto-Save
    private func scheduleAutoSave() {
        autoSaveWorkItem?.cancel()
        let workItem = DispatchWorkItem { autoSaveProfile() }
        autoSaveWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: workItem)
    }

    private func autoSaveProfile() {
        guard !isPickerActive else {
            print("MyProfileView: Auto-save skipped because picker is active.")
            return
        }
        guard var updatedProfile = viewModel.userProfile else {
            print("MyProfileView: No user profile loaded yet.")
            return
        }
        let interestsArray = interestsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        updatedProfile.firstName = firstName
        updatedProfile.lastName = lastName
        updatedProfile.dateOfBirth = dateOfBirth
        updatedProfile.gender = gender
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
        let originalCreatedAt = updatedProfile.createdAt
        viewModel.updateUserProfile(updatedProfile: updatedProfile) { result in
            switch result {
            case .success:
                updatedProfile.createdAt = originalCreatedAt
                print("MyProfileView: Profile auto-saved successfully.")
            case .failure(let error):
                print("MyProfileView: Error auto-saving profile: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Nested Subviews

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

    struct MediaGridView: View {
        let imageUrls: [String]
        let onTapAddOrEdit: (Int) -> Void
        let onRemoveImage: (Int) -> Void

        private let columns = [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ]

        var body: some View {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(0..<9) { index in
                    ZStack(alignment: .topTrailing) {
                        if index < imageUrls.count, let url = URL(string: imageUrls[index]) {
                            AsyncImage(url: url) { phase in
                                if let image = phase.image {
                                    image.resizable()
                                        .scaledToFill()
                                        .frame(height: 100)
                                        .clipped()
                                        .cornerRadius(8)
                                } else {
                                    Image(systemName: "photo").resizable()
                                }
                            }
                            .frame(height: 100)
                            .clipped()
                            .cornerRadius(8)
                            .onTapGesture { onTapAddOrEdit(index) }
                            Button(action: { onRemoveImage(index) }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white)
                                    .padding(6)
                            }
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                            .offset(x: -4, y: 4)
                        } else {
                            ZStack {
                                Rectangle()
                                    .fill(AppTheme.cardBackground)
                                    .cornerRadius(8)
                                    .frame(height: 100)
                                Image(systemName: "plus")
                                    .font(.system(size: 24))
                                    .foregroundColor(.gray)
                            }
                            .onTapGesture { onTapAddOrEdit(index) }
                        }
                    }
                }
            }
            .padding(.horizontal, 8)
        }
    }

    @ViewBuilder
    func ProfileCardPreviewSection(profile: UserModel?) -> some View {
        if let profile = profile {
            VStack(alignment: .leading, spacing: 8) {
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

    @ViewBuilder
    func InlineEditingSection() -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Group {
                TextField("First Name", text: $firstName)
                    .padding(AppTheme.defaultPadding)
                    .background(AppTheme.cardBackground)
                    .cornerRadius(AppTheme.defaultCornerRadius)
                    .onChange(of: firstName) { _ in scheduleAutoSave() }
                TextField("Last Name", text: $lastName)
                    .padding(AppTheme.defaultPadding)
                    .background(AppTheme.cardBackground)
                    .cornerRadius(AppTheme.defaultCornerRadius)
                    .onChange(of: lastName) { _ in scheduleAutoSave() }
                TextField("Date of Birth (YYYY-MM-DD)", text: $dateOfBirth)
                    .padding(AppTheme.defaultPadding)
                    .background(AppTheme.cardBackground)
                    .cornerRadius(AppTheme.defaultCornerRadius)
                    .onChange(of: dateOfBirth) { _ in scheduleAutoSave() }
                Picker("Gender", selection: $gender) {
                    Text("Male").tag("Male")
                    Text("Female").tag("Female")
                    Text("Other").tag("Other")
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: gender) { _ in scheduleAutoSave() }
                Picker("Grade Level", selection: $selectedGradeLevel) {
                    ForEach(GradeLevel.allCases) { level in
                        Text(level.rawValue).tag(level)
                    }
                }
                .onChange(of: selectedGradeLevel) { _ in scheduleAutoSave() }
                TextField("Major (e.g., Computer Science)", text: $major)
                    .padding(AppTheme.defaultPadding)
                    .background(AppTheme.cardBackground)
                    .cornerRadius(AppTheme.defaultCornerRadius)
                    .onChange(of: major) { _ in scheduleAutoSave() }
                TextField("College Name (e.g., Engineering)", text: $collegeName)
                    .padding(AppTheme.defaultPadding)
                    .background(AppTheme.cardBackground)
                    .cornerRadius(AppTheme.defaultCornerRadius)
                    .onChange(of: collegeName) { _ in scheduleAutoSave() }
                Picker("Housing Status", selection: $selectedHousingStatus) {
                    ForEach(HousingStatus.allCases) { status in
                        Text(status.rawValue).tag(status)
                    }
                }
                .onChange(of: selectedHousingStatus) { _ in scheduleAutoSave() }
                if selectedHousingStatus == .apartment ||
                   selectedHousingStatus == .house ||
                   selectedHousingStatus == .subleasing ||
                   selectedHousingStatus == .lookingForLease {
                    Picker("Lease Duration", selection: $selectedLeaseDuration) {
                        ForEach(LeaseDuration.allCases) { duration in
                            Text(duration.rawValue).tag(duration)
                        }
                    }
                    .onChange(of: selectedLeaseDuration) { _ in scheduleAutoSave() }
                }
                TextField("Budget Range (e.g., $500 - $1000)", text: $budgetRange)
                    .padding(AppTheme.defaultPadding)
                    .background(AppTheme.cardBackground)
                    .cornerRadius(AppTheme.defaultCornerRadius)
                    .onChange(of: budgetRange) { _ in scheduleAutoSave() }
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
                .onChange(of: cleanliness) { _ in scheduleAutoSave() }
                Picker("Sleep Schedule", selection: $sleepSchedule) {
                    ForEach(sleepScheduleOptions, id: \.self) { option in
                        Text(option)
                    }
                }
                .onChange(of: sleepSchedule) { _ in scheduleAutoSave() }
                Toggle("Smoker", isOn: $smoker)
                    .onChange(of: smoker) { _ in scheduleAutoSave() }
                Toggle("Pet Friendly", isOn: $petFriendly)
                    .onChange(of: petFriendly) { _ in scheduleAutoSave() }
                TextField("Interests (comma-separated)", text: $interestsText)
                    .autocapitalization(.none)
                    .padding(AppTheme.defaultPadding)
                    .background(AppTheme.cardBackground)
                    .cornerRadius(AppTheme.defaultCornerRadius)
                    .onChange(of: interestsText) { _ in scheduleAutoSave() }
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
}

struct MyProfileView_Previews: PreviewProvider {
    static var previews: some View {
        MyProfileView()
    }
}
