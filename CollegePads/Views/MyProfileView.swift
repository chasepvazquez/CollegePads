import SwiftUI
import PhotosUI
import FirebaseAuth

struct MyProfileView: View {
    @StateObject private var viewModel = ProfileViewModel.shared

    // MARK: - Mode Selection (Edit / Preview)
    @State private var isPreviewMode = false

    // MARK: - Photo Picker State
    @State private var showingPhotoPicker = false
    @State private var newProfileImage: UIImage? = nil
    @State private var tappedImageIndex: Int? = nil
    @State private var isPickerActive = false

    // MARK: - State Variables (Fields)
    @State private var aboutMe = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var dateOfBirth = ""
    @State private var gender = "Other"
    @State private var selectedGradeLevel: GradeLevel = .freshman
    @State private var major = ""
    @State private var collegeName = ""  // Now set via a Picker.
    @State private var budgetRange = ""
    @State private var cleanliness = 3
    @State private var sleepSchedule = "Flexible"
    @State private var smoker = false
    @State private var petFriendly = false
    @State private var interestsText = ""
    @State private var selectedHousingStatus: HousingStatus = .dorm
    @State private var selectedLeaseDuration: LeaseDuration = .notApplicable

    // New state: List of valid colleges loaded from CSV.
    @State private var validColleges: [String] = []

    let sleepScheduleOptions = ["Early Bird", "Night Owl", "Flexible"]

    // MARK: - A simple dictionary to map cleanliness levels to descriptions.
    private let cleanlinessDescriptions: [Int: String] = [
        1: "Very Messy",
        2: "Messy",
        3: "Average",
        4: "Tidy",
        5: "Very Tidy"
    ]
    
    // Debouncer for Auto-Save
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
        case mediumTerm = "6-12 months"
        case longTerm = "1 year+"
        case futureNextYear = "Future: Next Year"
        case futureTwoPlus = "Future: 2+ Years"
        case notApplicable = "Not Applicable"
        var id: String { self.rawValue }
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Title
                HStack {
                    Text("My Profile")
                        .font(AppTheme.titleFont)
                        .foregroundColor(.primary)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 8)

                // Segmented Control
                Picker("", selection: $isPreviewMode) {
                    Text("Edit").tag(false)
                    Text("Preview").tag(true)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .padding(.bottom, 8)

                // Main Content
                if isPreviewMode {
                    if let profile = viewModel.userProfile {
                        ProfilePreviewView(user: profile)
                            .transition(.opacity)
                    } else {
                        Text("Loading preview...")
                            .font(AppTheme.bodyFont)
                            .foregroundColor(.primary)
                    }
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            // Profile Completion Bar
                            if let profile = viewModel.userProfile {
                                ProfileCompletionView(
                                    completion: ProfileCompletionCalculator.calculateCompletion(for: profile)
                                )
                            }

                            // 3x3 Image Grid
                            MediaGridView(
                                imageUrls: viewModel.userProfile?.profileImageUrls ?? [],
                                onTapAddOrEdit: { index in
                                    tappedImageIndex = index
                                    newProfileImage = nil
                                    isPickerActive = true
                                    showingPhotoPicker = true
                                },
                                onRemoveImage: { index in
                                    removeImage(at: index)
                                }
                            )

                            // ABOUT ME
                            VStack(alignment: .leading, spacing: 6) {
                                Text("ABOUT ME")
                                    .font(.headline)
                                TextEditor(text: $aboutMe)
                                    .scrollContentBackground(.hidden)
                                    .background(AppTheme.cardBackground)
                                    .cornerRadius(AppTheme.defaultCornerRadius)
                                    .frame(minHeight: 100)
                                    .padding(6)
                                    .onChange(of: aboutMe) { _ in scheduleAutoSave() }
                            }
                            .padding()
                            .background(AppTheme.cardBackground.opacity(0.8))
                            .cornerRadius(15)
                            .shadow(radius: 5)

                            // BASICS
                            VStack(alignment: .leading, spacing: 10) {
                                Text("BASICS")
                                    .font(.headline)
                                Group {
                                    LabeledField(label: "First Name", text: $firstName)
                                    LabeledField(label: "Last Name", text: $lastName)
                                    LabeledField(label: "Date of Birth (YYYY-MM-DD)", text: $dateOfBirth)
                                    Picker("Gender", selection: $gender) {
                                        Text("Male").tag("Male")
                                        Text("Female").tag("Female")
                                        Text("Other").tag("Other")
                                    }
                                    .pickerStyle(SegmentedPickerStyle())
                                    .onChange(of: gender) { _ in scheduleAutoSave() }
                                }
                            }
                            .padding()
                            .background(AppTheme.cardBackground.opacity(0.8))
                            .cornerRadius(15)
                            .shadow(radius: 5)

                            // ACADEMICS
                            VStack(alignment: .leading, spacing: 10) {
                                Text("ACADEMICS")
                                    .font(.headline)
                                Group {
                                    Picker("Grade Level", selection: $selectedGradeLevel) {
                                        ForEach(GradeLevel.allCases) { level in
                                            Text(level.rawValue).tag(level)
                                        }
                                    }
                                    .onChange(of: selectedGradeLevel) { _ in scheduleAutoSave() }

                                    LabeledField(label: "Major", text: $major)
                                    // Replace text field with a Picker for College selection.
                                    Picker("College", selection: $collegeName) {
                                        Text("Select a College").tag("")
                                        ForEach(validColleges, id: \.self) { college in
                                            Text(college).tag(college)
                                        }
                                    }
                                    .onChange(of: collegeName) { _ in scheduleAutoSave() }
                                }
                            }
                            .padding()
                            .background(AppTheme.cardBackground.opacity(0.8))
                            .cornerRadius(15)
                            .shadow(radius: 5)

                            // HOUSING
                            VStack(alignment: .leading, spacing: 10) {
                                Text("HOUSING")
                                    .font(.headline)
                                Group {
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

                                    LabeledField(label: "Budget Range", text: $budgetRange)

                                    Picker("Cleanliness", selection: $cleanliness) {
                                        ForEach(1..<6) { number in
                                            let desc = cleanlinessDescriptions[number] ?? ""
                                            Text("\(number) - \(desc)").tag(number)
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
                                }
                            }
                            .padding()
                            .background(AppTheme.cardBackground.opacity(0.8))
                            .cornerRadius(15)
                            .shadow(radius: 5)

                            // INTERESTS
                            VStack(alignment: .leading, spacing: 10) {
                                Text("INTERESTS")
                                    .font(.headline)
                                TextField("Interests (comma-separated)", text: $interestsText)
                                    .autocapitalization(.none)
                                    .padding(AppTheme.defaultPadding)
                                    .background(AppTheme.cardBackground)
                                    .cornerRadius(AppTheme.defaultCornerRadius)
                                    .onChange(of: interestsText) { _ in scheduleAutoSave() }
                            }
                            .padding()
                            .background(AppTheme.cardBackground.opacity(0.8))
                            .cornerRadius(15)
                            .shadow(radius: 5)
                        }
                        .padding()
                    }
                }
            }
        }
        .onAppear {
            if viewModel.userProfile == nil {
                viewModel.loadUserProfile()
            } else {
                populateLocalFields(from: viewModel.userProfile!)
            }
            // Asynchronously load and cache valid college names.
            UniversityDataProvider.shared.loadUniversities { colleges in
                self.validColleges = colleges
            }
        }
        .sheet(isPresented: $showingPhotoPicker) {
            CustomImagePicker(image: $newProfileImage)
        }
        .onChange(of: newProfileImage) { image in
            if image != nil {
                handlePhotoSelected()
            }
        }
    }

    // MARK: - Custom Labeled TextField
    @ViewBuilder
    func LabeledField(label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            TextField(label, text: text)
                .padding(AppTheme.defaultPadding)
                .background(AppTheme.cardBackground)
                .cornerRadius(AppTheme.defaultCornerRadius)
                .onChange(of: text.wrappedValue) { _ in scheduleAutoSave() }
        }
    }

    // MARK: - Profile Completion
    struct ProfileCompletionView: View {
        let completion: Double
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text("Profile Completion: \(Int(completion))%")
                    .font(AppTheme.bodyFont)
                ProgressView(value: completion, total: 100)
                    .accentColor(AppTheme.primaryColor)
                    .scaleEffect(x: 1, y: 2, anchor: .center)
            }
            .padding()
            .background(AppTheme.cardBackground)
            .cornerRadius(15)
            .shadow(radius: 5)
        }
    }

    // MARK: - Media Grid
    struct MediaGridView: View {
        let imageUrls: [String]
        let onTapAddOrEdit: (Int) -> Void
        let onRemoveImage: (Int) -> Void

        private let columns = Array(repeating: GridItem(.flexible()), count: 3)

        var body: some View {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(0..<9, id: \.self) { index in
                    ZStack(alignment: .topTrailing) {
                        if index < imageUrls.count, let url = URL(string: imageUrls[index]) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .frame(width: 100, height: 100)
                                case .success(let image):
                                    image.resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipped()
                                        .cornerRadius(8)
                                case .failure:
                                    Image(systemName: "photo")
                                        .resizable()
                                        .frame(width: 100, height: 100)
                                @unknown default:
                                    Image(systemName: "photo")
                                        .resizable()
                                        .frame(width: 100, height: 100)
                                }
                            }
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
                                    .frame(width: 100, height: 100)
                                    .cornerRadius(8)
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

    // MARK: - Photo Selection
    private func handlePhotoSelected() {
        guard let newImg = newProfileImage, let index = tappedImageIndex else { return }
        viewModel.uploadProfileImage(image: newImg) { result in
            switch result {
            case .success(let downloadURL):
                var updatedProfile = viewModel.userProfile ?? defaultUserProfile()
                var urls = updatedProfile.profileImageUrls ?? []
                if index < urls.count {
                    urls[index] = downloadURL
                } else {
                    urls.append(downloadURL)
                }
                updatedProfile.profileImageUrls = Array(urls.prefix(9))
                updatedProfile.profileImageUrl = updatedProfile.profileImageUrls?.first
                viewModel.updateUserProfile(updatedProfile: updatedProfile) { _ in }
            case .failure:
                break
            }
            DispatchQueue.main.async {
                showingPhotoPicker = false
                isPickerActive = false
                newProfileImage = nil
            }
        }
    }

    // MARK: - Remove Image
    private func removeImage(at index: Int) {
        guard var profile = viewModel.userProfile,
              var urls = profile.profileImageUrls, index < urls.count else { return }
        urls.remove(at: index)
        profile.profileImageUrls = urls
        profile.profileImageUrl = urls.first
        viewModel.updateUserProfile(updatedProfile: profile) { _ in }
    }

    // MARK: - Populate Fields
    private func populateLocalFields(from profile: UserModel) {
        aboutMe = profile.aboutMe ?? ""
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
        selectedHousingStatus = HousingStatus(rawValue: profile.housingStatus ?? "") ?? .dorm
        selectedLeaseDuration = LeaseDuration(rawValue: profile.leaseDuration ?? "") ?? .notApplicable
    }

    // MARK: - Debounced Auto-Save
    private func scheduleAutoSave() {
        autoSaveWorkItem?.cancel()
        autoSaveWorkItem = DispatchWorkItem { autoSaveProfile() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: autoSaveWorkItem!)
    }

    private func autoSaveProfile() {
        guard !isPickerActive, var updatedProfile = viewModel.userProfile else { return }
        let interestsArray = interestsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        updatedProfile.aboutMe = aboutMe
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
            case .failure:
                break
            }
        }
    }

    // MARK: - Fallback
    private func defaultUserProfile() -> UserModel {
        UserModel(
            email: Auth.auth().currentUser?.email ?? "unknown@unknown.com",
            isEmailVerified: false
        )
    }
}

struct MyProfileView_Previews: PreviewProvider {
    static var previews: some View {
        MyProfileView()
    }
}
