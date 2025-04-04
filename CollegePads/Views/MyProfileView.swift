import SwiftUI
import PhotosUI
import FirebaseAuth

// MARK: - Missing Enum Definitions
enum PrimaryHousingPreference: String, CaseIterable, Identifiable {
    case lookingForLease = "Looking for Lease"
    case lookingForRoommate = "Looking for Roommate"
    var id: String { self.rawValue }
}

enum PropertyMediaType: String, CaseIterable, Identifiable {
    case propertyImage = "Property Image"
    case floorplan = "Floorplan"
    case document = "Document"
    var id: String { self.rawValue }
}

// MARK: - Quiz Data Structures & Other Quiz-Related Code
struct QuizQuestion: Identifiable {
    let id = UUID()
    let question: String
    let options: [String]
}

let goingOutQuizQuestions: [QuizQuestion] = [
    QuizQuestion(question: "You can find me...", options: ["Dancing 💃", "Socializing 🗣️"]),
    QuizQuestion(question: "I like to...", options: ["Dress Up 👗", "Dress Down 👕"]),
    QuizQuestion(question: "I tend to arrive...", options: ["Early ⏰", "Fashionably Late 🕒"]),
    QuizQuestion(question: "My exit strategy looks like...", options: ["Say Bye First 👋", "Disappear 🕶️"])
]

let weekendsQuizQuestions: [QuizQuestion] = [
    QuizQuestion(question: "Weekends are for...", options: ["Recharging 😴", "Socializing 🥳"]),
    QuizQuestion(question: "Saturday night looks like...", options: ["Cozy nights in 🏡", "Fun nights out 🎊"]),
    QuizQuestion(question: "A typical Sunday looks like...", options: ["Self care 💆", "Sunday fun day 🎈"])
]

let myPhoneQuizQuestions: [QuizQuestion] = [
    QuizQuestion(question: "I'm the kind of person who...", options: ["Replies quickly ⚡", "Forgets to reply 💤"]),
    QuizQuestion(question: "I prefer receiving...", options: ["Text messages 📱", "Phone calls 📞"]),
    QuizQuestion(question: "My phone is always...", options: ["Fully charged 🔋", "Low on battery 🪫"])
]

// MARK: - MyProfileView
struct MyProfileView: View {
    @StateObject private var viewModel = ProfileViewModel.shared

    // MARK: - Mode Selection
    @State private var isPreviewMode = false

    // MARK: - Photo Picker State (for profile images)
    @State private var showingPhotoPicker = false
    @State private var newProfileImage: UIImage? = nil
    @State private var tappedImageIndex: Int? = nil
    @State private var isPickerActive = false

    // MARK: - Property Media Picker State (for property media uploads)
    @State private var showingPropertyMediaPicker = false
    @State private var newPropertyMediaImage: UIImage? = nil
    @State private var tappedPropertyMediaIndex: Int? = nil
    @State private var currentPropertyMediaType: PropertyMediaType = .propertyImage

    // MARK: - Housing Tiered State
    @State private var primaryHousingPreference: PrimaryHousingPreference? = nil
    @State private var secondaryHousingType: String = ""

    // MARK: - Profile Fields
    @State private var aboutMe = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var dateOfBirth = ""
    @State private var gender = "Other"
    @State private var selectedHeight = ""
    
    @State private var selectedGradeLevel: GradeLevel = .freshman
    @State private var major = ""
    @State private var collegeName = ""
    @State private var collegeSearchQuery: String = ""
    @State private var filteredColleges: [String] = []
    @State private var budgetRange = ""
    @State private var cleanliness = 3
    @State private var sleepSchedule = "Flexible"
    @State private var smoker = false
    @State private var petFriendly = false
    @State private var interestsText = ""
    // (Old housing multi-select removed)

    // New state variables for roommate count inputs
    @State private var roommateCountNeeded: Int = 0
    @State private var roommateCountExisting: Int = 0

    // MARK: - Property Details & Media State
    @State private var propertyDetails: String = ""
    @State private var propertyImageUrls: [String] = []
    @State private var floorplanUrls: [String] = []
    @State private var documentUrls: [String] = []
    
    // MARK: - Amenities State (New Multi-Select)
    @State private var selectedAmenities: [String] = []
    private let propertyAmenitiesOptions = [
        "In-Unit Laundry",
        "On-Site Laundry",
        "Air Conditioning",
        "Heating",
        "Furnished",
        "Unfurnished",
        "High-Speed Internet",
        "Utilities Included",
        "Pet Friendly",
        "Parking Available",
        "Garage Parking",
        "Balcony / Patio",
        "Private Bathroom",
        "Shared Bathroom",
        "Gym / Fitness Center",
        "Common Area / Lounge",
        "Pool Access",
        "Rooftop Access",
        "Bike Storage",
        "Dishwasher",
        "Microwave",
        "Elevator Access",
        "Wheelchair Accessible",
        "24/7 Security",
        "Gated Community",
        "Study Rooms",
        "Game Room",
        "Smoke-Free",
        "Quiet Hours Enforced"
    ]
    
    // MARK: - Lease & Pricing Details State (for Lease/Sublease users)
    @State private var leaseStartDate: Date = Date()
    @State private var leaseDurationText: String = ""
    @State private var monthlyRentText: String = ""
    @State private var selectedSpecialLeaseConditions: [String] = []
    private let specialLeaseConditionsOptions: [String] = [
        "Start date negotiable",
        "Early move-in available",
        "Late move-out allowed",
        "Rent negotiable",
        "First month free",
        "Utilities included",
        "Partial months prorated",
        "Furnished room",
        "Unfurnished but furniture available for purchase",
        "Room includes mattress/desk/chair",
        "Must be approved by landlord",
        "Temporary sublease only",
        "Must sign roommate agreement",
        "Deposit required",
        "No deposit required",
        "Split rent with roommate",
        "Venmo/Zelle accepted",
        "Pet allowed (with conditions)",
        "No smoking",
        "Must be okay with overnight guests",
        "Cleanliness expectations",
        "Quiet hours after 10 PM",
        "No parties",
        "Gated entry",
        "Keycard access only",
        "Limited guest parking"
    ]
    
    // MARK: - Room Type State
    @State private var roomType: String = ""
    
    // MARK: - Lifestyle State (Added Cleanliness header here)
    @State private var selectedPets: [String] = []
    @State private var selectedDrinking: String = ""
    @State private var selectedSmoking: String = ""
    @State private var selectedCannabis: String = ""
    @State private var selectedWorkout: String = ""
    @State private var selectedDietaryPreferences: [String] = []
    @State private var selectedSocialMedia: String = ""
    @State private var selectedSleepingHabits: String = ""
    
    // MARK: - Quiz State (matching UserModel exactly)
    @State private var goingOutQuizAnswers: [String] = []
    @State private var weekendQuizAnswers: [String] = []
    @State private var phoneQuizAnswers: [String] = []

    // MARK: - Options
    private let petOptions = [
        "Dog", "Cat", "Reptile", "Amphibian", "Bird", "Fish",
        "Don't have but love others", "Turtle", "Hamster", "Rabbit",
        "Pet-free", "Want a pet", "Allergic to pets"
    ]
    private let drinkingOptions = [
        "Not for me", "Sober", "Sober curious",
        "On special occasions", "Socially on weekends", "Most nights"
    ]
    private let smokingOptions = [
        "Non-smoker", "Smoker", "Smoker when drinking", "Trying to quit"
    ]
    private let cannabisOptions = [
        "Yes", "Occasionally", "Socially", "Never"
    ]
    private let workoutOptions = [
        "Everyday", "Often", "Sometimes", "Never"
    ]
    private let dietaryOptions = [
        "Vegan", "Vegetarian", "Pescatarian", "Kosher", "Halal",
        "Carnivore", "Omnivore", "Other"
    ]
    private let socialMediaOptions = [
        "Influencer status", "Socially active", "Off the grid", "Passive scroller"
    ]
    private let sleepingHabitsOptions = [
        "Early bird", "Night owl", "In a spectrum"
    ]
    
    // New desired lease housing type options
    private let leaseTypeForLease = ["Dorm", "Apartment", "House"]
    private let leaseTypeForRoommate = ["Dorm", "Apartment", "House", "Subleasing"]
    
    // New property media type options (for segmented control)
    private let propertyMediaTypeOptions = PropertyMediaType.allCases.map { $0.rawValue }
    
    // MARK: - Height Options
    private let heightOptions: [String] = {
        var result: [String] = []
        for ft in 3...8 {
            for inch in 0...11 {
                if ft == 8 && inch > 0 { break }
                result.append("\(ft)'\(inch)\"")
            }
        }
        return result
    }()
    
    // MARK: - College Search
    @State private var validColleges: [String] = []
    let sleepScheduleOptions = ["Early Bird", "Night Owl", "Flexible"]
    
    // MARK: - Cleanliness Descriptions
    private let cleanlinessDescriptions: [Int: String] = [
        1: "Very Messy",
        2: "Messy",
        3: "Average",
        4: "Tidy",
        5: "Very Tidy"
    ]
    
    // MARK: - Auto-Save Debouncer
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
    
    // Updated: Lease & Pricing Details are now displayed only for the “Looking for Roommate” view.
    private var isLeaseOrSublease: Bool {
        return primaryHousingPreference == .lookingForRoommate
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient.ignoresSafeArea()
            VStack(spacing: 0) {
                headerSection
                if isPreviewMode {
                    if let profile = viewModel.userProfile {
                        ProfilePreviewView(user: profile)
                            .transition(.opacity)
                    } else {
                        Text("Loading preview...")
                            .font(AppTheme.bodyFont)
                            .foregroundColor(.primary)
                            .padding()
                    }
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                            if let profile = viewModel.userProfile {
                                ProfileCompletionView(
                                    completion: ProfileCompletionCalculator.calculateCompletion(for: profile)
                                )
                            }
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
                            aboutMeSection
                            basicsSection
                            academicsSection
                            housingSection
                            // Property Details now appear only for Looking for Roommate
                            if primaryHousingPreference == .lookingForRoommate {
                                propertyDetailsSection
                            }
                            roomTypeSection
                            // Lease & Pricing Details are displayed only for Looking for Roommate view
                            if primaryHousingPreference == .lookingForRoommate {
                                leasePricingSection
                            }
                            amenitiesSection
                            lifestyleSection
                            CombinedQuizzesSection(
                                goingOutQuizAnswers: $goingOutQuizAnswers,
                                weekendQuizAnswers: $weekendQuizAnswers,
                                phoneQuizAnswers: $phoneQuizAnswers,
                                onQuizComplete: { scheduleAutoSave() }
                            )
                            interestsSection
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 30)
                    }
                }
            }
        }
        .onAppear {
            if viewModel.userProfile == nil {
                viewModel.loadUserProfile()
            } else if let existingProfile = viewModel.userProfile {
                populateLocalFields(from: existingProfile)
            }
            UniversityDataProvider.shared.loadUniversities { colleges in
                self.validColleges = colleges
            }
        }
        .sheet(isPresented: $showingPhotoPicker) {
            CustomImagePicker(image: $newProfileImage)
        }
        .sheet(isPresented: $showingPropertyMediaPicker) {
            CustomImagePicker(image: $newPropertyMediaImage)
        }
        .onChange(of: newProfileImage) { image in
            if image != nil {
                handlePhotoSelected()
            }
        }
        .onChange(of: newPropertyMediaImage) { image in
            if image != nil {
                handlePropertyMediaSelected()
            }
        }
    }
    
    // MARK: - Subviews
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("My Profile")
                    .font(AppTheme.titleFont)
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 8)
            Picker("", selection: $isPreviewMode) {
                Text("Edit").tag(false)
                Text("Preview").tag(true)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }
    
    private var aboutMeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
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
    }
    
    private var basicsSection: some View {
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
                Picker("Height", selection: $selectedHeight) {
                    Text("Select Height").tag("")
                    ForEach(heightOptions, id: \.self) { h in
                        Text(h).tag(h)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: selectedHeight) { _ in scheduleAutoSave() }
            }
        }
        .padding()
        .background(AppTheme.cardBackground.opacity(0.8))
        .cornerRadius(15)
        .shadow(radius: 5)
    }
    
    private var academicsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ACADEMICS")
                .font(.headline)
            Picker("Grade Level", selection: $selectedGradeLevel) {
                ForEach(GradeLevel.allCases) { level in
                    Text(level.rawValue).tag(level)
                }
            }
            .onChange(of: selectedGradeLevel) { _ in scheduleAutoSave() }
            LabeledField(label: "Major", text: $major)
            VStack(alignment: .leading, spacing: 4) {
                Text("College")
                    .foregroundColor(.secondary)
                TextField("Search College", text: $collegeSearchQuery)
                    .padding(8)
                    .background(AppTheme.cardBackground)
                    .cornerRadius(8)
                    .onChange(of: collegeSearchQuery) { newValue in
                        filteredColleges = UniversityDataProvider.shared.searchUniversities(query: newValue)
                    }
                if !filteredColleges.isEmpty {
                    ScrollView(.vertical) {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(filteredColleges, id: \.self) { college in
                                Text(college)
                                    .padding(8)
                                    .onTapGesture {
                                        collegeName = college
                                        collegeSearchQuery = college
                                        filteredColleges = []
                                        scheduleAutoSave()
                                    }
                            }
                        }
                    }
                    .frame(maxHeight: 150)
                    .background(AppTheme.cardBackground.opacity(0.8))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(AppTheme.cardBackground.opacity(0.8))
        .cornerRadius(15)
        .shadow(radius: 5)
    }
    
    // Updated Housing Section:
    private var housingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("HOUSING")
                .font(.headline)
            
            Picker("Primary Preference", selection: $primaryHousingPreference) {
                ForEach(PrimaryHousingPreference.allCases) { pref in
                    Text(pref.rawValue).tag(Optional(pref))
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .onChange(of: primaryHousingPreference) { _ in
                scheduleAutoSave()
                secondaryHousingType = ""
            }
            
            if let primary = primaryHousingPreference {
                Picker("Housing Type", selection: $secondaryHousingType) {
                    Text("Select Type").tag("")
                    if primary == .lookingForLease {
                        ForEach(leaseTypeForLease, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    } else {
                        ForEach(leaseTypeForRoommate, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .onChange(of: secondaryHousingType) { _ in scheduleAutoSave() }
            }
            
            // Show budget range only for Looking for Lease
            if primaryHousingPreference == .lookingForLease {
                LabeledField(label: "Budget Range", text: $budgetRange)
            }
            // Add roommate count info for Looking for Roommate
            else if primaryHousingPreference == .lookingForRoommate {
                HStack {
                    Text("Roommates Needed: \(roommateCountNeeded)")
                    Stepper("", value: $roommateCountNeeded, in: 0...10)
                        .onChange(of: roommateCountNeeded) { _ in scheduleAutoSave() }
                }
                HStack {
                    Text("Roommates Already: \(roommateCountExisting)")
                    Stepper("", value: $roommateCountExisting, in: 0...10)
                        .onChange(of: roommateCountExisting) { _ in scheduleAutoSave() }
                }
            }
        }
        .padding()
        .background(AppTheme.cardBackground.opacity(0.8))
        .cornerRadius(15)
        .shadow(radius: 5)
    }

    
    // Property Details Section remains unchanged
    private var propertyDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PROPERTY DETAILS")
                .font(.headline)
            TextEditor(text: $propertyDetails)
                .frame(minHeight: 100)
                .padding(6)
                .background(AppTheme.cardBackground)
                .cornerRadius(AppTheme.defaultCornerRadius)
                .onChange(of: propertyDetails) { _ in scheduleAutoSave() }
            Picker("Media Type", selection: $currentPropertyMediaType) {
                ForEach(PropertyMediaType.allCases) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.vertical, 4)
            VStack(alignment: .leading) {
                Text(currentPropertyMediaType.rawValue)
                    .font(.subheadline)
                PropertyMediaGridView(
                    mediaType: currentPropertyMediaType,
                    propertyImageUrls: $propertyImageUrls,
                    floorplanUrls: $floorplanUrls,
                    documentUrls: $documentUrls,
                    onAddMedia: {
                        tappedPropertyMediaIndex = nil
                        newPropertyMediaImage = nil
                        showingPropertyMediaPicker = true
                    },
                    onRemoveMedia: { index in
                        removePropertyMedia(at: index, for: currentPropertyMediaType)
                    }
                )
            }
        }
        .padding()
        .background(AppTheme.cardBackground.opacity(0.8))
        .cornerRadius(15)
        .shadow(radius: 5)
    }
    
    // Room Type Section remains for both views.
    private var roomTypeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ROOM TYPE")
                .font(.headline)
            Picker("Room Type", selection: $roomType) {
                Text("Private Room").tag("Private Room")
                Text("Shared Room").tag("Shared Room")
                Text("Studio").tag("Studio")
            }
            .pickerStyle(SegmentedPickerStyle())
            .onChange(of: roomType) { _ in scheduleAutoSave() }
        }
        .padding()
        .background(AppTheme.cardBackground.opacity(0.8))
        .cornerRadius(15)
        .shadow(radius: 5)
    }
    
    // Lease & Pricing Details are only shown for Looking for Roommate view.
    private var leasePricingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("LEASE & PRICING DETAILS")
                .font(.headline)
            DatePicker("Lease Start Date", selection: $leaseStartDate, displayedComponents: .date)
                .datePickerStyle(CompactDatePickerStyle())
            LabeledField(label: "Lease Duration", text: $leaseDurationText)
            LabeledField(label: "Monthly Rent (USD)", text: $monthlyRentText)
                .keyboardType(.decimalPad)
            Text("Special Lease Conditions")
                .font(.subheadline)
            MultiSelectChipView(
                options: specialLeaseConditionsOptions,
                selectedItems: $selectedSpecialLeaseConditions,
                onSelectionChanged: { scheduleAutoSave() }
            )
        }
        .padding()
        .background(AppTheme.cardBackground.opacity(0.8))
        .cornerRadius(15)
        .shadow(radius: 5)
    }
    
    private var amenitiesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("AMENITIES")
                .font(.headline)
            MultiSelectChipView(
                options: propertyAmenitiesOptions,
                selectedItems: $selectedAmenities,
                onSelectionChanged: { scheduleAutoSave() }
            )
        }
        .padding()
        .background(AppTheme.cardBackground.opacity(0.8))
        .cornerRadius(15)
        .shadow(radius: 5)
    }
    
    // Lifestyle Section updated: now includes a "Cleanliness" header above the cleanliness picker.
    private var lifestyleSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("LIFESTYLE")
                .font(.headline)
                .padding(.bottom, 4)
            // Cleanliness now appears first and uses bodyFont
            VStack(alignment: .leading, spacing: 4) {
                Text("Cleanliness")
                    .font(AppTheme.bodyFont)
                Picker("Cleanliness", selection: $cleanliness) {
                    ForEach(1..<6) { number in
                        let desc = cleanlinessDescriptions[number] ?? ""
                        Text("\(number) - \(desc)").tag(number)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: cleanliness) { _ in scheduleAutoSave() }
            }
            Text("Do you have any pets?")
                .font(AppTheme.bodyFont)
            MultiSelectChipView(
                options: petOptions,
                selectedItems: $selectedPets,
                onSelectionChanged: { scheduleAutoSave() }
            )
            .padding(.bottom, 8)
            Text("How often do you drink?")
                .font(AppTheme.bodyFont)
            Picker("Drinking", selection: $selectedDrinking) {
                ForEach(drinkingOptions, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            .pickerStyle(.menu)
            .onChange(of: selectedDrinking) { _ in scheduleAutoSave() }
            .padding(.bottom, 8)
            Text("How often do you smoke?")
                .font(AppTheme.bodyFont)
            Picker("Smoking", selection: $selectedSmoking) {
                ForEach(smokingOptions, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            .pickerStyle(.menu)
            .onChange(of: selectedSmoking) { _ in scheduleAutoSave() }
            .padding(.bottom, 8)
            Text("Are you 420 friendly?")
                .font(AppTheme.bodyFont)
            Picker("Cannabis", selection: $selectedCannabis) {
                ForEach(cannabisOptions, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            .pickerStyle(.menu)
            .onChange(of: selectedCannabis) { _ in scheduleAutoSave() }
            .padding(.bottom, 8)
            Text("Do you workout?")
                .font(AppTheme.bodyFont)
            Picker("Workout", selection: $selectedWorkout) {
                ForEach(workoutOptions, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            .pickerStyle(.menu)
            .onChange(of: selectedWorkout) { _ in scheduleAutoSave() }
            .padding(.bottom, 8)
            Text("What are your dietary preferences?")
                .font(AppTheme.bodyFont)
            MultiSelectChipView(
                options: dietaryOptions,
                selectedItems: $selectedDietaryPreferences,
                onSelectionChanged: { scheduleAutoSave() }
            )
            .padding(.bottom, 8)
            Text("How active are you on social media?")
                .font(AppTheme.bodyFont)
            Picker("Social Media", selection: $selectedSocialMedia) {
                ForEach(socialMediaOptions, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            .pickerStyle(.menu)
            .onChange(of: selectedSocialMedia) { _ in scheduleAutoSave() }
            .padding(.bottom, 8)
            Text("What are your sleeping habits?")
                .font(AppTheme.bodyFont)
            Picker("Sleeping Habits", selection: $selectedSleepingHabits) {
                ForEach(sleepingHabitsOptions, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            .pickerStyle(.menu)
            .onChange(of: selectedSleepingHabits) { _ in scheduleAutoSave() }
            .padding(.bottom, 8)
        }
        .padding()
        .background(AppTheme.cardBackground.opacity(0.8))
        .cornerRadius(15)
        .shadow(radius: 5)
    }
    
    private var interestsSection: some View {
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
    
    struct PropertyMediaGridView: View {
        let mediaType: PropertyMediaType
        @Binding var propertyImageUrls: [String]
        @Binding var floorplanUrls: [String]
        @Binding var documentUrls: [String]
        let onAddMedia: () -> Void
        let onRemoveMedia: (Int) -> Void

        private var currentMediaUrls: [String] {
            switch mediaType {
            case .propertyImage: return propertyImageUrls
            case .floorplan: return floorplanUrls
            case .document: return documentUrls
            }
        }

        var body: some View {
            VStack {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                    ForEach(0..<max(9, currentMediaUrls.count + 1), id: \.self) { index in
                        ZStack(alignment: .topTrailing) {
                            if index < currentMediaUrls.count, let url = URL(string: currentMediaUrls[index]) {
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
                                        Image(systemName: "doc")
                                            .resizable()
                                            .frame(width: 100, height: 100)
                                    @unknown default:
                                        Image(systemName: "doc")
                                            .resizable()
                                            .frame(width: 100, height: 100)
                                    }
                                }
                                .onTapGesture { onAddMedia() }
                                
                                Button(action: { onRemoveMedia(index) }) {
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
                                .onTapGesture { onAddMedia() }
                            }
                        }
                    }
                }
                .padding(.horizontal, 8)
            }
        }
    }
    
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
    
    private func handlePropertyMediaSelected() {
        guard let newImg = newPropertyMediaImage else { return }
        let folder: String
        switch currentPropertyMediaType {
        case .propertyImage:
            folder = "propertyImages"
        case .floorplan:
            folder = "floorplans"
        case .document:
            folder = "documents"
        }
        viewModel.uploadPropertyMedia(image: newImg, folder: folder) { result in
            switch result {
            case .success(let downloadURL):
                var updatedProfile = viewModel.userProfile ?? defaultUserProfile()
                switch currentPropertyMediaType {
                case .propertyImage:
                    var arr = updatedProfile.propertyImageUrls ?? []
                    arr.append(downloadURL)
                    updatedProfile.propertyImageUrls = arr
                    propertyImageUrls = arr
                case .floorplan:
                    var arr = updatedProfile.floorplanUrls ?? []
                    arr.append(downloadURL)
                    updatedProfile.floorplanUrls = arr
                    floorplanUrls = arr
                case .document:
                    var arr = updatedProfile.documentUrls ?? []
                    arr.append(downloadURL)
                    updatedProfile.documentUrls = arr
                    documentUrls = arr
                }
                viewModel.updateUserProfile(updatedProfile: updatedProfile) { _ in }
            case .failure:
                break
            }
            DispatchQueue.main.async {
                showingPropertyMediaPicker = false
                newPropertyMediaImage = nil
            }
        }
    }
    
    private func removeImage(at index: Int) {
        guard var profile = viewModel.userProfile,
              var urls = profile.profileImageUrls, index < urls.count else { return }
        urls.remove(at: index)
        profile.profileImageUrls = urls
        profile.profileImageUrl = urls.first
        viewModel.updateUserProfile(updatedProfile: profile) { _ in }
    }
    
    private func removePropertyMedia(at index: Int, for mediaType: PropertyMediaType) {
        guard var profile = viewModel.userProfile else { return }
        switch mediaType {
        case .propertyImage:
            if var arr = profile.propertyImageUrls, index < arr.count {
                arr.remove(at: index)
                profile.propertyImageUrls = arr
                propertyImageUrls = arr
            }
        case .floorplan:
            if var arr = profile.floorplanUrls, index < arr.count {
                arr.remove(at: index)
                profile.floorplanUrls = arr
                floorplanUrls = arr
            }
        case .document:
            if var arr = profile.documentUrls, index < arr.count {
                arr.remove(at: index)
                profile.documentUrls = arr
                documentUrls = arr
            }
        }
        viewModel.updateUserProfile(updatedProfile: profile) { _ in }
    }
    
    private func populateLocalFields(from profile: UserModel) {
        aboutMe = profile.aboutMe ?? ""
        firstName = profile.firstName ?? ""
        lastName = profile.lastName ?? ""
        dateOfBirth = profile.dateOfBirth ?? ""
        gender = profile.gender ?? "Other"
        selectedHeight = profile.height ?? ""
        major = profile.major ?? ""
        collegeName = profile.collegeName ?? ""
        budgetRange = profile.budgetRange ?? ""
        cleanliness = profile.cleanliness ?? 3
        sleepSchedule = profile.sleepSchedule ?? "Flexible"
        smoker = profile.smoker ?? false
        petFriendly = profile.petFriendly ?? false
        interestsText = (profile.interests ?? []).joined(separator: ", ")
        selectedGradeLevel = GradeLevel(rawValue: profile.gradeLevel ?? "") ?? .freshman
        
        if let primary = profile.housingStatus, let pref = PrimaryHousingPreference(rawValue: primary) {
            primaryHousingPreference = pref
        } else {
            primaryHousingPreference = nil
        }
        secondaryHousingType = profile.desiredLeaseHousingType ?? ""
        
        propertyDetails = profile.propertyDetails ?? ""
        propertyImageUrls = profile.propertyImageUrls ?? []
        floorplanUrls = profile.floorplanUrls ?? []
        documentUrls = profile.documentUrls ?? []
        
        selectedAmenities = profile.amenities ?? []
        
        if let startDate = profile.leaseStartDate {
            leaseStartDate = startDate
        } else {
            leaseStartDate = Date()
        }
        leaseDurationText = profile.leaseDuration ?? ""
        if let rent = profile.monthlyRent {
            monthlyRentText = String(rent)
        } else {
            monthlyRentText = ""
        }
        selectedSpecialLeaseConditions = profile.specialLeaseConditions ?? []
        roomType = profile.roomType ?? ""
        
        selectedPets = profile.pets ?? []
        selectedDrinking = profile.drinking ?? ""
        selectedSmoking = profile.smoking ?? ""
        selectedCannabis = profile.cannabis ?? ""
        selectedWorkout = profile.workout ?? ""
        selectedDietaryPreferences = profile.dietaryPreferences ?? []
        selectedSocialMedia = profile.socialMedia ?? ""
        selectedSleepingHabits = profile.sleepingHabits ?? ""
        
        goingOutQuizAnswers = profile.goingOutQuizAnswers ?? []
        weekendQuizAnswers = profile.weekendQuizAnswers ?? []
        phoneQuizAnswers = profile.phoneQuizAnswers ?? []
    }
    
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
        updatedProfile.height = selectedHeight
        updatedProfile.gradeLevel = selectedGradeLevel.rawValue
        updatedProfile.major = major
        updatedProfile.collegeName = collegeName
        updatedProfile.budgetRange = budgetRange
        updatedProfile.cleanliness = cleanliness
        updatedProfile.sleepSchedule = sleepSchedule
        updatedProfile.smoker = smoker
        updatedProfile.petFriendly = petFriendly
        updatedProfile.interests = interestsArray
        
        updatedProfile.housingStatus = primaryHousingPreference?.rawValue
        updatedProfile.desiredLeaseHousingType = secondaryHousingType.isEmpty ? nil : secondaryHousingType
        
        updatedProfile.roommateCountNeeded = roommateCountNeeded
        updatedProfile.roommateCountExisting = roommateCountExisting
        
        updatedProfile.propertyDetails = propertyDetails
        updatedProfile.propertyImageUrls = propertyImageUrls
        updatedProfile.floorplanUrls = floorplanUrls
        updatedProfile.documentUrls = documentUrls
        
        updatedProfile.amenities = selectedAmenities
        
        if isLeaseOrSublease {
            updatedProfile.leaseStartDate = leaseStartDate
            updatedProfile.leaseDuration = leaseDurationText
            if let rent = Double(monthlyRentText) {
                updatedProfile.monthlyRent = rent
            } else {
                updatedProfile.monthlyRent = nil
            }
            updatedProfile.specialLeaseConditions = selectedSpecialLeaseConditions
            updatedProfile.roomType = roomType
        } else {
            updatedProfile.leaseStartDate = nil
            updatedProfile.leaseDuration = nil
            updatedProfile.monthlyRent = nil
            updatedProfile.specialLeaseConditions = nil
            updatedProfile.roomType = roomType
        }
        
        updatedProfile.pets = selectedPets
        updatedProfile.drinking = selectedDrinking
        updatedProfile.smoking = selectedSmoking
        updatedProfile.cannabis = selectedCannabis
        updatedProfile.workout = selectedWorkout
        updatedProfile.dietaryPreferences = selectedDietaryPreferences
        updatedProfile.socialMedia = selectedSocialMedia
        updatedProfile.sleepingHabits = selectedSleepingHabits
        
        updatedProfile.goingOutQuizAnswers = goingOutQuizAnswers
        updatedProfile.weekendQuizAnswers = weekendQuizAnswers
        updatedProfile.phoneQuizAnswers = phoneQuizAnswers
        
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
    
    private func defaultUserProfile() -> UserModel {
        // Updated order: housingStatus, desiredLeaseHousingType, roommate counts, property details, room type, then lease/pricing details, then amenities, then budgetRange & cleanliness.
        UserModel(
            email: Auth.auth().currentUser?.email ?? "unknown@unknown.com",
            isEmailVerified: false,
            createdAt: nil,
            aboutMe: nil,
            firstName: nil,
            lastName: nil,
            dateOfBirth: nil,
            gender: nil,
            height: nil,
            gradeLevel: nil,
            major: nil,
            collegeName: nil,
            housingStatus: nil,
            dormType: nil,
            preferredDorm: nil,
            desiredLeaseHousingType: nil,
            roommateCountNeeded: 0,
            roommateCountExisting: 0,
            propertyDetails: nil,
            propertyImageUrls: nil,
            floorplanUrls: nil,
            documentUrls: nil,
            roomType: nil,
            leaseStartDate: nil,
            leaseDuration: nil,
            monthlyRent: nil,
            specialLeaseConditions: nil,
            amenities: nil,
            budgetRange: nil,
            cleanliness: nil,
            sleepSchedule: nil,
            smoker: nil,
            petFriendly: nil,
            livingStyle: nil,
            socialLevel: nil,
            studyHabits: nil,
            interests: nil,
            profileImageUrl: nil,
            location: nil,
            isVerified: false,
            blockedUserIDs: nil,
            filterSettings: nil,
            pets: nil,
            drinking: nil,
            smoking: nil,
            cannabis: nil,
            workout: nil,
            dietaryPreferences: nil,
            socialMedia: nil,
            sleepingHabits: nil,
            goingOutQuizAnswers: nil,
            weekendQuizAnswers: nil,
            phoneQuizAnswers: nil
        )
    }
}

// MARK: - MultiSelectChipView (For Pets, Dietary Preferences, and Amenities)
struct MultiSelectChipView: View {
    let options: [String]
    @Binding var selectedItems: [String]
    var onSelectionChanged: () -> Void = {}
    var maxSelection: Int? = nil

    var body: some View {
        FlowLayout(options, selectedItems: $selectedItems, onSelectionChanged: onSelectionChanged, maxSelection: maxSelection)
            .padding(6)
            .background(Color.clear)
    }
}

// MARK: - FlowLayout for Multi-Select Chips
struct FlowLayout: View {
    let data: [String]
    @Binding var selectedItems: [String]
    var onSelectionChanged: () -> Void
    var maxSelection: Int? = nil

    @State private var totalHeight: CGFloat = .zero

    init(_ data: [String],
         selectedItems: Binding<[String]>,
         onSelectionChanged: @escaping () -> Void,
         maxSelection: Int? = nil) {
        self.data = data
        self._selectedItems = selectedItems
        self.onSelectionChanged = onSelectionChanged
        self.maxSelection = maxSelection
    }

    var body: some View {
        GeometryReader { geo in
            self.content(in: geo)
        }
        .frame(minHeight: totalHeight)
    }

    private func content(in g: GeometryProxy) -> some View {
        var widthAccumulator: CGFloat = 0
        var rows: [RowItem] = []
        var currentRow = RowItem()

        for text in data {
            let chipSize = chipSize(for: text)
            if widthAccumulator + chipSize.width > g.size.width {
                rows.append(currentRow)
                currentRow = RowItem()
                widthAccumulator = 0
            }
            currentRow.items.append(text)
            widthAccumulator += chipSize.width
        }
        if !currentRow.items.isEmpty {
            rows.append(currentRow)
        }
        DispatchQueue.main.async {
            self.totalHeight = CGFloat(rows.count) * 40
        }
        return VStack(alignment: .leading, spacing: 8) {
            ForEach(rows.indices, id: \.self) { rowIndex in
                HStack(spacing: 8) {
                    ForEach(rows[rowIndex].items, id: \.self) { item in
                        chipView(item)
                    }
                }
            }
        }
    }

    private func chipSize(for text: String) -> CGSize {
        let padding: CGFloat = 44
        let font = UIFont.systemFont(ofSize: 14)
        let attributes = [NSAttributedString.Key.font: font]
        let textSize = (text as NSString).size(withAttributes: attributes)
        return CGSize(width: textSize.width + padding, height: 36)
    }

    private func chipView(_ item: String) -> some View {
        let isSelected = selectedItems.contains(item)
        let isDisabled = !isSelected && (maxSelection != nil && selectedItems.count >= maxSelection!)
        return Text(item)
            .font(.system(size: 14))
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(isSelected ? AppTheme.accentColor : AppTheme.cardBackground)
            .cornerRadius(16)
            .opacity(isDisabled ? 0.5 : 1.0)
            .onTapGesture {
                if isDisabled { return }
                if isSelected {
                    selectedItems.removeAll { $0 == item }
                } else {
                    selectedItems.append(item)
                }
                onSelectionChanged()
            }
    }

    struct RowItem {
        var items: [String] = []
    }
}

// MARK: - Quiz Support Structure
struct Question {
    let text: String
    let options: [String]
}

// MARK: - CombinedQuizzesSection Definition
struct CombinedQuizzesSection: View {
    @Binding var goingOutQuizAnswers: [String]
    @Binding var weekendQuizAnswers: [String]
    @Binding var phoneQuizAnswers: [String]
    
    let onQuizComplete: () -> Void
    
    @State private var showingGoingOutQuiz = false
    @State private var showingWeekendsQuiz = false
    @State private var showingMyPhoneQuiz = false

    var body: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 12) {
                Text("GOING OUT QUIZ")
                    .font(AppTheme.subtitleFont)
                    .foregroundColor(AppTheme.primaryColor)
                if goingOutQuizAnswers.isEmpty {
                    Text("Not taken yet")
                        .font(AppTheme.bodyFont)
                        .foregroundColor(.gray)
                } else {
                    ForEach(goingOutQuizAnswers, id: \.self) { answer in
                        Text(answer)
                            .font(AppTheme.bodyFont)
                            .foregroundColor(.primary)
                    }
                }
                Button(action: { showingGoingOutQuiz = true }) {
                    Text(goingOutQuizAnswers.isEmpty ? "Take Quiz" : "Retake Quiz")
                        .font(AppTheme.bodyFont)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.primaryColor)
                        .foregroundColor(.white)
                        .cornerRadius(AppTheme.defaultCornerRadius)
                }
            }
            .padding(AppTheme.defaultPadding)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.defaultCornerRadius)
                    .fill(AppTheme.cardBackground.opacity(0.8))
            )
            .shadow(radius: 5)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("WEEKENDS QUIZ")
                    .font(AppTheme.subtitleFont)
                    .foregroundColor(AppTheme.primaryColor)
                if weekendQuizAnswers.isEmpty {
                    Text("Not taken yet")
                        .font(AppTheme.bodyFont)
                        .foregroundColor(.gray)
                } else {
                    ForEach(weekendQuizAnswers, id: \.self) { answer in
                        Text(answer)
                            .font(AppTheme.bodyFont)
                            .foregroundColor(.primary)
                    }
                }
                Button(action: { showingWeekendsQuiz = true }) {
                    Text(weekendQuizAnswers.isEmpty ? "Take Quiz" : "Retake Quiz")
                        .font(AppTheme.bodyFont)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.primaryColor)
                        .foregroundColor(.white)
                        .cornerRadius(AppTheme.defaultCornerRadius)
                }
            }
            .padding(AppTheme.defaultPadding)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.defaultCornerRadius)
                    .fill(AppTheme.cardBackground.opacity(0.8))
            )
            .shadow(radius: 5)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("+ MY PHONE QUIZ")
                    .font(AppTheme.subtitleFont)
                    .foregroundColor(AppTheme.primaryColor)
                if phoneQuizAnswers.isEmpty {
                    Text("Not taken yet")
                        .font(AppTheme.bodyFont)
                        .foregroundColor(.gray)
                } else {
                    ForEach(phoneQuizAnswers, id: \.self) { answer in
                        Text(answer)
                            .font(AppTheme.bodyFont)
                            .foregroundColor(.primary)
                    }
                }
                Button(action: { showingMyPhoneQuiz = true }) {
                    Text(phoneQuizAnswers.isEmpty ? "Take Quiz" : "Retake Quiz")
                        .font(AppTheme.bodyFont)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.primaryColor)
                        .foregroundColor(.white)
                        .cornerRadius(AppTheme.defaultCornerRadius)
                }
            }
            .padding(AppTheme.defaultPadding)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.defaultCornerRadius)
                    .fill(AppTheme.cardBackground.opacity(0.8))
            )
            .shadow(radius: 5)
        }
        .sheet(isPresented: $showingGoingOutQuiz) {
            QuizView(
                quizTitle: "Going Out Quiz",
                quizQuestions: goingOutQuizQuestions,
                onComplete: { answers in
                    self.goingOutQuizAnswers = answers
                    showingGoingOutQuiz = false
                    onQuizComplete()
                }
            )
        }
        .sheet(isPresented: $showingWeekendsQuiz) {
            QuizView(
                quizTitle: "Weekends Quiz",
                quizQuestions: weekendsQuizQuestions,
                onComplete: { answers in
                    self.weekendQuizAnswers = answers
                    showingWeekendsQuiz = false
                    onQuizComplete()
                }
            )
        }
        .sheet(isPresented: $showingMyPhoneQuiz) {
            QuizView(
                quizTitle: "+ My Phone Quiz",
                quizQuestions: myPhoneQuizQuestions,
                onComplete: { answers in
                    self.phoneQuizAnswers = answers
                    showingMyPhoneQuiz = false
                    onQuizComplete()
                }
            )
        }
    }
}

// MARK: - QuizView Definition
struct QuizView: View {
    let quizTitle: String
    let quizQuestions: [QuizQuestion]
    let onComplete: ([String]) -> Void

    @State private var currentQuestionIndex = 0
    @State private var selectedAnswers: [String] = []

    var body: some View {
        Group {
            if currentQuestionIndex < quizQuestions.count {
                VStack(spacing: 20) {
                    Text(quizTitle)
                        .font(AppTheme.titleFont)
                        .padding(.top)
                    
                    Text(quizQuestions[currentQuestionIndex].question)
                        .font(AppTheme.subtitleFont)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    ForEach(quizQuestions[currentQuestionIndex].options, id: \.self) { option in
                        Button(action: {
                            selectedAnswers.append(option)
                            if currentQuestionIndex < quizQuestions.count - 1 {
                                withAnimation {
                                    currentQuestionIndex += 1
                                }
                            } else {
                                onComplete(selectedAnswers)
                            }
                        }) {
                            Text(option)
                                .font(AppTheme.bodyFont)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppTheme.primaryColor)
                                .foregroundColor(.white)
                                .cornerRadius(AppTheme.defaultCornerRadius)
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                }
                .padding()
            } else {
                EmptyView()
            }
        }
    }
}
