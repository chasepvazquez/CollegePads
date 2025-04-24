import SwiftUI
import PhotosUI
import FirebaseAuth
import MapKit
import FirebaseFirestore
import Combine

// MARK: — Section styling modifier
struct SectionContainer: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(AppTheme.cardBackground.opacity(0.8))
            .cornerRadius(15)
            .shadow(radius: 5)
    }
}
extension View {
    /// Apply the standard “card” look
    func sectionStyle() -> some View {
        modifier(SectionContainer())
    }
}

// MARK: - Missing Enum Definitions
enum PrimaryHousingPreference: String, CaseIterable, Identifiable {
    case lookingToFindTogether = "Looking to Find Together"
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
    @State private var budgetMin: Double = 0
    @State private var budgetMax: Double = 5000
    @State private var cleanliness = 3
    @State private var sleepSchedule = "Flexible"
    @State private var smoker = false
    @State private var petFriendly = false
    @State private var interestsText = ""

    // New state variables for roommate count inputs
    @State private var roommateCountNeeded: Int = 0
    @State private var roommateCountExisting: Int = 0

    // MARK: - Property Details & Media State
    @State private var propertyDetails: String = ""
    // Use only one unified array for property/floorplan images.
    @State private var propertyImageUrls: [String] = []
    // NEW: State for property address entry (only used for roommate mode)
    @State private var propertyAddress: String = ""
    @State private var propertyCoordinate: CLLocationCoordinate2D? = nil
    @StateObject private var addressLocationService = AddressLocationService()

    // MARK: - Amenities State (New Multi-Select)
    @State private var selectedAmenities: [String] = []
    private let propertyAmenitiesOptions = [
        "In-Unit Laundry", "On-Site Laundry", "Air Conditioning", "Heating",
        "Furnished", "Unfurnished", "High-Speed Internet", "Utilities Included",
        "Pet Friendly", "Parking Available", "Garage Parking", "Balcony / Patio",
        "Private Bathroom", "Shared Bathroom", "Gym / Fitness Center", "Common Area / Lounge",
        "Pool Access", "Rooftop Access", "Bike Storage", "Dishwasher", "Microwave",
        "Elevator Access", "Wheelchair Accessible", "24/7 Security", "Gated Community",
        "Study Rooms", "Game Room", "Smoke-Free", "Quiet Hours Enforced"
    ]
    
    // MARK: - Lease & Pricing Details State (for Lease/Sublease users)
    @State private var leaseStartDate: Date = Date()
    @State private var leaseDurationText: String = ""
    @State private var rentMin: Double = 0
    @State private var rentMax: Double = 5000
    @State private var selectedSpecialLeaseConditions: [String] = []
    private let specialLeaseConditionsOptions: [String] = [
        "Start date negotiable", "Early move-in available", "Late move-out allowed",
        "Rent negotiable", "First month free", "Utilities included", "Partial months prorated",
        "Furnished room", "Unfurnished but furniture available for purchase", "Room includes mattress/desk/chair",
        "Must be approved by landlord", "Temporary sublease only", "Must sign roommate agreement",
        "Deposit required", "No deposit required", "Split rent with roommate", "Venmo/Zelle accepted",
        "Pet allowed (with conditions)", "No smoking", "Must be okay with overnight guests",
        "Cleanliness expectations", "Quiet hours after 10 PM", "No parties", "Gated entry",
        "Keycard access only", "Limited guest parking"
    ]
    
    // MARK: - Room Type State
    @State private var roomType: String = ""
    
    // MARK: - Lifestyle State
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
    private let petOptions = ["Dog","Cat","Reptile","Amphibian","Bird","Fish","Don't have but love others","Turtle","Hamster","Rabbit","Pet-free","Want a pet","Allergic to pets"]
    private let drinkingOptions = ["Not for me","Sober","Sober curious","On special occasions","Socially on weekends","Most nights"]
    private let smokingOptions = ["Non-smoker","Smoker","Smoker when drinking","Trying to quit"]
    private let cannabisOptions = ["Yes","Occasionally","Socially","Never"]
    private let workoutOptions = ["Everyday","Often","Sometimes","Never"]
    private let dietaryOptions = ["Vegan","Vegetarian","Pescatarian","Kosher","Halal","Carnivore","Omnivore","Other"]
    private let socialMediaOptions = ["Influencer status","Socially active","Off the grid","Passive scroller"]
    private let sleepingHabitsOptions = ["Early bird","Night owl","In a spectrum"]

    // New desired lease housing type options
    private let leaseTypeForLease = ["Dorm","Apartment","House"]
    private let leaseTypeForRoommate = ["Dorm","Apartment","House","Subleasing"]
    
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
    let sleepScheduleOptions = ["Early Bird","Night Owl","Flexible"]
    
    // MARK: - Cleanliness Descriptions
    private let cleanlinessDescriptions: [Int:String] = [
        1:"Very Messy",2:"Messy",3:"Average",4:"Tidy",5:"Very Tidy"
    ]
    
    // MARK: - Auto-Save Debouncer
    @State private var autoSaveWorkItem: DispatchWorkItem?

    // MARK: - Enumerations
    enum GradeLevel: String, CaseIterable, Identifiable {
        case freshman="Freshman", sophomore="Sophomore", junior="Junior",
             senior="Senior", graduate="Graduate", phd="PhD", other="Other"
        var id: String { self.rawValue }
    }
    enum LeaseDuration: String, CaseIterable, Identifiable {
        case current="Current Lease", shortTerm="Short Term (<6 months)",
             mediumTerm="6-12 months", longTerm="1 year+", futureNextYear="Future: Next Year",
             futureTwoPlus="Future: 2+ Years", notApplicable="Not Applicable"
        var id: String { self.rawValue }
    }
    
    // Updated: Lease & Pricing Details are always saved
    private var isLeaseOrSublease: Bool {
        primaryHousingPreference == .lookingForRoommate
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
                                ProfileCompletionView(completion:
                                    ProfileCompletionCalculator.calculateCompletion(for: profile))
                            }
                            MediaGridView(
                                imageUrls: viewModel.userProfile?.profileImageUrls ?? [],
                                onTapAddOrEdit: { index in
                                    tappedImageIndex = index
                                    newProfileImage = nil
                                    isPickerActive = true
                                    showingPhotoPicker = true
                                },
                                onRemoveImage: { index in removeImage(at: index) }
                            )
                            aboutMeSection
                            basicsSection
                            academicsSection
                            if let pref = primaryHousingPreference {
                                if pref == .lookingForLease {
                                    housingSection
                                    roomTypeSection
                                    amenitiesSection
                                } else if pref == .lookingForRoommate {
                                    housingSection
                                    propertyDetailsSection
                                    roomTypeSection
                                    leasePricingSection
                                    amenitiesSection
                                } else if pref == .lookingToFindTogether {
                                    housingSection
                                }
                            } else {
                                housingSection
                            }
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
           // As soon as `userProfile` becomes non-nil, fill all your local @State fields:
           .onReceive(viewModel.$userProfile.compactMap { $0 }) { profile in
               populateLocalFields(from: profile)
           }
            .onAppear {
                UniversityDataProvider.shared.loadUniversities { colleges in
                    validColleges = colleges
                    print("[MyProfileView] Loaded \(colleges.count) colleges.")
                }
            }
        .sheet(isPresented: $showingPhotoPicker) {
            CustomImagePicker(image: $newProfileImage)
        }
        .sheet(isPresented: $showingPropertyMediaPicker) {
            CustomImagePicker(image: $newPropertyMediaImage)
        }
        .onChange(of: newProfileImage) { image in if image != nil { handlePhotoSelected() } }
        .onChange(of: newPropertyMediaImage) { image in if image != nil { handlePropertyMediaSelected() } }
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
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }

    private var aboutMeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ABOUT ME").font(.headline)
            TextEditor(text: $aboutMe)
                .scrollContentBackground(.hidden)
                .background(AppTheme.cardBackground)
                .cornerRadius(AppTheme.defaultCornerRadius)
                .frame(minHeight: 100)
                .padding(6)
                .onChange(of: aboutMe) { _ in scheduleAutoSave() }
        }
        .sectionStyle()
    }

    private var basicsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("BASICS").font(.headline)
            Group {
                LabeledField(label: "First Name", text: $firstName)
                LabeledField(label: "Last Name", text: $lastName)
                LabeledField(label: "Date of Birth (YYYY-MM-DD)", text: $dateOfBirth)
                Picker("Gender", selection: $gender) {
                    Text("Male").tag("Male")
                    Text("Female").tag("Female")
                    Text("Other").tag("Other")
                }
                .pickerStyle(.segmented)
                .onChange(of: gender) { _ in scheduleAutoSave() }
                Picker("Height", selection: $selectedHeight) {
                    Text("Select Height").tag("")
                    ForEach(heightOptions, id: \.self) { h in Text(h).tag(h) }
                }
                .pickerStyle(.menu)
                .onChange(of: selectedHeight) { _ in scheduleAutoSave() }
            }
        }
        .sectionStyle()
    }

    private var academicsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ACADEMICS").font(.headline)
            Picker("Grade Level", selection: $selectedGradeLevel) {
                ForEach(GradeLevel.allCases) { level in Text(level.rawValue).tag(level) }
            }
            .onChange(of: selectedGradeLevel) { _ in scheduleAutoSave() }
            LabeledField(label: "Major", text: $major)
            VStack(alignment: .leading, spacing: 4) {
                Text("College").foregroundColor(.secondary)
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
        .sectionStyle()
    }

    private var housingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("HOUSING").font(.headline)
            Picker("Primary Preference", selection: $primaryHousingPreference) {
                ForEach(PrimaryHousingPreference.allCases) { pref in
                    Text(pref.rawValue).tag(Optional(pref))
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: primaryHousingPreference) { _ in
                scheduleAutoSave()
                secondaryHousingType = ""
            }

            if let primary = primaryHousingPreference {
                Picker("Housing Type", selection: $secondaryHousingType) {
                    Text("Select Type").tag("")
                    if primary == .lookingForLease || primary == .lookingToFindTogether {
                        ForEach(leaseTypeForLease, id: \.self) { type in Text(type).tag(type) }
                    } else {
                        ForEach(leaseTypeForRoommate, id: \.self) { type in Text(type).tag(type) }
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: secondaryHousingType) { _ in scheduleAutoSave() }
            }

            if primaryHousingPreference == .lookingForLease
                || primaryHousingPreference == .lookingToFindTogether {
                VStack(alignment: .leading) {
                    Text("Budget: \(Int(budgetMin))–\(Int(budgetMax)) USD")
                        .font(.headline)
                    HStack {
                        Text("Min: \(Int(budgetMin))")
                        Slider(value: $budgetMin, in: 0...5000, step: 50)
                            .onChange(of: budgetMin) { _ in scheduleAutoSave() }
                    }
                    HStack {
                        Text("Max: \(Int(budgetMax))")
                        Slider(value: $budgetMax, in: 0...5000, step: 50)
                            .onChange(of: budgetMax) { _ in scheduleAutoSave() }
                    }
                }
            }
        }
        .sectionStyle()
    }

    private var propertyDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PROPERTY DETAILS").font(.headline)
            TextEditor(text: $propertyDetails)
                .scrollContentBackground(.hidden)
                .background(AppTheme.cardBackground)
                .cornerRadius(AppTheme.defaultCornerRadius)
                .frame(minHeight: 100)
                .padding(6)
                .onChange(of: propertyDetails) { _ in scheduleAutoSave() }

            VStack(alignment: .leading, spacing: 4) {
                Text("Property Address").foregroundColor(.secondary)
                TextField("Enter property address", text: $propertyAddress)
                    .padding(8)
                    .background(AppTheme.cardBackground)
                    .cornerRadius(8)
                    .onChange(of: propertyAddress) { newValue in
                        addressLocationService.queryFragment = newValue
                        scheduleAutoSave()
                    }
                if !addressLocationService.suggestions.isEmpty {
                    ScrollView(.vertical) {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(addressLocationService.suggestions, id: \.self) { suggestion in
                                Button(action: {
                                    let fullAddress = suggestion.title + " " + suggestion.subtitle
                                    propertyAddress = fullAddress
                                    addressLocationService.suggestions = []
                                    addressLocationService.getCoordinate(for: fullAddress) { coordinate in
                                        DispatchQueue.main.async {
                                            propertyCoordinate = coordinate
                                            scheduleAutoSave()
                                        }
                                    }
                                }) {
                                    Text(suggestion.title + " " + suggestion.subtitle)
                                        .foregroundColor(.primary)
                                        .padding(8)
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 150)
                    .background(AppTheme.cardBackground.opacity(0.8))
                    .cornerRadius(8)
                }
            }

            Text("Property & Floorplan Images").font(.subheadline)
            SinglePropertyMediaGridView(
                imageUrls: $propertyImageUrls,
                onAddMedia: {
                    tappedPropertyMediaIndex = nil
                    newPropertyMediaImage = nil
                    showingPropertyMediaPicker = true
                },
                onRemoveMedia: { index in removePropertyMedia(at: index) }
            )
        }
        .sectionStyle()
    }

    private var roomTypeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ROOM TYPE").font(.headline)
            Picker("Room Type", selection: $roomType) {
                Text("Private Room").tag("Private Room")
                Text("Shared Room").tag("Shared Room")
                Text("Studio").tag("Studio")
            }
            .pickerStyle(.segmented)
            .onChange(of: roomType) { _ in scheduleAutoSave() }
        }
        .sectionStyle()
    }

    private var leasePricingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("LEASE & PRICING DETAILS").font(.headline)
            DatePicker("Lease Start Date", selection: $leaseStartDate, displayedComponents: .date)
                .datePickerStyle(.compact)
            LabeledField(label: "Lease Duration", text: $leaseDurationText)
            VStack(alignment: .leading) {
                Text("Monthly Rent: \(Int(rentMin))–\(Int(rentMax)) USD")
                    .font(.headline)
                HStack {
                    Text("Min: \(Int(rentMin))")
                    Slider(value: $rentMin, in: 0...5000, step: 50)
                        .onChange(of: rentMin) { _ in scheduleAutoSave() }
                }
                HStack {
                    Text("Max: \(Int(rentMax))")
                    Slider(value: $rentMax, in: 0...5000, step: 50)
                        .onChange(of: rentMax) { _ in scheduleAutoSave() }
                }
            }
            .keyboardType(.decimalPad)
            Text("Special Lease Conditions").font(.subheadline)
            MultiSelectChipView(
                options: specialLeaseConditionsOptions,
                selectedItems: $selectedSpecialLeaseConditions,
                onSelectionChanged: { scheduleAutoSave() }
            )
        }
        .sectionStyle()
    }

    private var amenitiesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("AMENITIES").font(.headline)
            MultiSelectChipView(
                options: propertyAmenitiesOptions,
                selectedItems: $selectedAmenities,
                onSelectionChanged: { scheduleAutoSave() }
            )
        }
        .sectionStyle()
    }

    private var lifestyleSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("LIFESTYLE").font(.headline).padding(.bottom, 4)
            VStack(alignment: .leading, spacing: 4) {
                Text("Cleanliness").font(AppTheme.bodyFont)
                Picker("Cleanliness", selection: $cleanliness) {
                    ForEach(1..<6) { number in
                        Text("\(number) - \(cleanlinessDescriptions[number] ?? "")").tag(number)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: cleanliness) { _ in scheduleAutoSave() }
            }
            Text("Do you have any pets?").font(AppTheme.bodyFont)
            MultiSelectChipView(
                options: petOptions,
                selectedItems: $selectedPets,
                onSelectionChanged: { scheduleAutoSave() }
            )
            .padding(.bottom, 8)
            Text("How often do you drink?").font(AppTheme.bodyFont)
            Picker("Drinking", selection: $selectedDrinking) {
                ForEach(drinkingOptions, id: \.self) { Text($0).tag($0) }
            }
            .pickerStyle(.menu)
            .onChange(of: selectedDrinking) { _ in scheduleAutoSave() }
            .padding(.bottom, 8)
            Text("How often do you smoke?").font(AppTheme.bodyFont)
            Picker("Smoking", selection: $selectedSmoking) {
                ForEach(smokingOptions, id: \.self) { Text($0).tag($0) }
            }
            .pickerStyle(.menu)
            .onChange(of: selectedSmoking) { _ in scheduleAutoSave() }
            .padding(.bottom, 8)
            Text("Are you 420 friendly?").font(AppTheme.bodyFont)
            Picker("Cannabis", selection: $selectedCannabis) {
                ForEach(cannabisOptions, id: \.self) { Text($0).tag($0) }
            }
            .pickerStyle(.menu)
            .onChange(of: selectedCannabis) { _ in scheduleAutoSave() }
            .padding(.bottom, 8)
            Text("Do you workout?").font(AppTheme.bodyFont)
            Picker("Workout", selection: $selectedWorkout) {
                ForEach(workoutOptions, id: \.self) { Text($0).tag($0) }
            }
            .pickerStyle(.menu)
            .onChange(of: selectedWorkout) { _ in scheduleAutoSave() }
            .padding(.bottom, 8)
            Text("What are your dietary preferences?").font(AppTheme.bodyFont)
            MultiSelectChipView(
                options: dietaryOptions,
                selectedItems: $selectedDietaryPreferences,
                onSelectionChanged: { scheduleAutoSave() }
            )
            .padding(.bottom, 8)
            Text("How active are you on social media?").font(AppTheme.bodyFont)
            Picker("Social Media", selection: $selectedSocialMedia) {
                ForEach(socialMediaOptions, id: \.self) { Text($0).tag($0) }
            }
            .pickerStyle(.menu)
            .onChange(of: selectedSocialMedia) { _ in scheduleAutoSave() }
            .padding(.bottom, 8)
            Text("What are your sleeping habits?").font(AppTheme.bodyFont)
            Picker("Sleeping Habits", selection: $selectedSleepingHabits) {
                ForEach(sleepingHabitsOptions, id: \.self) { Text($0).tag($0) }
            }
            .pickerStyle(.menu)
            .onChange(of: selectedSleepingHabits) { _ in scheduleAutoSave() }
            .padding(.bottom, 8)
        }
        .sectionStyle()
    }

    private var interestsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("INTERESTS").font(.headline)
            TextField("Interests (comma-separated)", text: $interestsText)
                .autocapitalization(.none)
                .padding(AppTheme.defaultPadding)
                .background(AppTheme.cardBackground)
                .cornerRadius(AppTheme.defaultCornerRadius)
                .onChange(of: interestsText) { _ in scheduleAutoSave() }
        }
        .sectionStyle()
    }

    @ViewBuilder
    func LabeledField(label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.subheadline).foregroundColor(.secondary)
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
                                    ProgressView().frame(width: 100, height: 100)
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

    struct SinglePropertyMediaGridView: View {
        @Binding var imageUrls: [String]
        let onAddMedia: () -> Void
        let onRemoveMedia: (Int) -> Void

        private let columns = Array(repeating: GridItem(.flexible()), count: 3)
        
        var body: some View {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(0..<9, id: \.self) { index in
                    ZStack(alignment: .topTrailing) {
                        if index < imageUrls.count, let url = URL(string: imageUrls[index]) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView().frame(width: 100, height: 100)
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
                            .overlay(
                                Group {
                                    if index == 0 {
                                        Text("Floorplan")
                                            .font(.caption)
                                            .padding(4)
                                            .background(Color.black.opacity(0.7))
                                            .foregroundColor(.white)
                                            .cornerRadius(4)
                                            .padding(4)
                                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                                    }
                                }
                            )
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
                                if index == 0 {
                                    Text("Floorplan")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .padding(4)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 4)
                                                .stroke(Color.gray, lineWidth: 1)
                                        )
                                } else {
                                    Image(systemName: "plus")
                                        .font(.system(size: 24))
                                        .foregroundColor(.gray)
                                }
                            }
                            .onTapGesture { onAddMedia() }
                        }
                    }
                }
            }
            .padding(.horizontal, 8)
        }
    }

    private func handlePhotoSelected() {
        guard let newImg = newProfileImage,
              var updatedProfile = viewModel.userProfile,
              let index = tappedImageIndex else {
            print("[MyProfileView] Error: userProfile is nil while handling photo selection.")
            return
        }
        viewModel.uploadProfileImage(image: newImg) { result in
            switch result {
            case .success(let downloadURL):
                var urls = updatedProfile.profileImageUrls ?? []
                if index < urls.count { urls[index] = downloadURL }
                else { urls.append(downloadURL) }
                updatedProfile.profileImageUrls = Array(urls.prefix(9))
                updatedProfile.profileImageUrl = updatedProfile.profileImageUrls?.first
                viewModel.updateUserProfile(updatedProfile: updatedProfile) { _ in }
            case .failure(let error):
                print("[MyProfileView] Error uploading profile image: \(error.localizedDescription)")
            }
            DispatchQueue.main.async {
                showingPhotoPicker = false
                isPickerActive = false
                newProfileImage = nil
            }
        }
    }

    private func handlePropertyMediaSelected() {
        guard let newImg = newPropertyMediaImage,
              var updatedProfile = viewModel.userProfile else {
            print("[MyProfileView] Error: userProfile is nil while handling property media selection.")
            return
        }
        let folder = "propertyMedia"
        viewModel.uploadPropertyMedia(image: newImg, folder: folder) { result in
            switch result {
            case .success(let downloadURL):
                var arr = updatedProfile.propertyImageUrls ?? []
                arr.append(downloadURL)
                updatedProfile.propertyImageUrls = arr
                DispatchQueue.main.async { propertyImageUrls = arr }
                viewModel.updateUserProfile(updatedProfile: updatedProfile) { _ in }
            case .failure(let error):
                print("[MyProfileView] Error uploading property media: \(error.localizedDescription)")
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

    private func removePropertyMedia(at index: Int) {
        guard var profile = viewModel.userProfile,
              var urls = profile.propertyImageUrls, index < urls.count else { return }
        urls.remove(at: index)
        profile.propertyImageUrls = urls
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
        collegeSearchQuery = profile.collegeName ?? ""
        secondaryHousingType = profile.desiredLeaseHousingType ?? ""
        roommateCountNeeded = profile.roommateCountNeeded ?? 0
        roommateCountExisting = profile.roommateCountExisting ?? 0
        budgetMin = profile.budgetMin ?? 0
        budgetMax = profile.budgetMax ?? 5000
        cleanliness = profile.cleanliness ?? 3
        sleepSchedule = profile.sleepSchedule ?? "Flexible"
        smoker = profile.smoker ?? false
        petFriendly = profile.petFriendly ?? false
        interestsText = (profile.interests ?? []).joined(separator: ", ")
        selectedGradeLevel = GradeLevel(rawValue: profile.gradeLevel ?? "") ?? .freshman
        
        if let primary = profile.housingStatus,
           let pref = PrimaryHousingPreference(rawValue: primary) {
            primaryHousingPreference = pref
        } else {
            primaryHousingPreference = nil
        }
        secondaryHousingType = profile.desiredLeaseHousingType ?? ""
        propertyDetails = profile.propertyDetails ?? ""
        propertyImageUrls = profile.propertyImageUrls ?? []
        propertyAddress = profile.propertyAddress ?? ""
        if let loc = profile.location {
            propertyCoordinate = CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude)
        } else {
            propertyCoordinate = nil
        }
        selectedAmenities = profile.amenities ?? []
        
        leaseStartDate = profile.leaseStartDate ?? Date()
        leaseDurationText = profile.leaseDuration ?? ""
        selectedSpecialLeaseConditions = profile.specialLeaseConditions ?? []
        roomType = profile.roomType ?? ""
        rentMin = profile.monthlyRentMin ?? 0
        rentMax = profile.monthlyRentMax ?? 5000
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
        updatedProfile.budgetMin = budgetMin
        updatedProfile.budgetMax = budgetMax
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
        updatedProfile.propertyAddress = propertyAddress
        updatedProfile.location = propertyCoordinate != nil
            ? GeoPoint(latitude: propertyCoordinate!.latitude, longitude: propertyCoordinate!.longitude)
            : nil
        
        updatedProfile.amenities = selectedAmenities
        
        updatedProfile.leaseStartDate = leaseStartDate
        updatedProfile.leaseDuration = leaseDurationText
        updatedProfile.monthlyRentMin = rentMin
        updatedProfile.monthlyRentMax = rentMax
        updatedProfile.specialLeaseConditions = selectedSpecialLeaseConditions
        updatedProfile.roomType = roomType
        
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
            if case .success = result {
                updatedProfile.createdAt = originalCreatedAt
            }
        }
    }
}

// MARK: - MultiSelectChipView (For Pets, Dietary Preferences, and Amenities)
struct MultiSelectChipView: View {
    let options: [String]
    @Binding var selectedItems: [String]
    var onSelectionChanged: () -> Void = {}
    var maxSelection: Int? = nil

    var body: some View {
        FlowLayout(options,
                   selectedItems: $selectedItems,
                   onSelectionChanged: onSelectionChanged,
                   maxSelection: maxSelection)
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
        GeometryReader { geo in content(in: geo) }
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
        if !currentRow.items.isEmpty { rows.append(currentRow) }
        DispatchQueue.main.async { totalHeight = CGFloat(rows.count) * 40 }

        return VStack(alignment: .leading, spacing: 8) {
            ForEach(rows.indices, id: \.self) { rowIndex in
                HStack(spacing: 8) {
                    ForEach(rows[rowIndex].items, id: \.self) { item in chipView(item) }
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
                    goingOutQuizAnswers = answers
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
                    weekendQuizAnswers = answers
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
                    phoneQuizAnswers = answers
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
                                withAnimation { currentQuestionIndex += 1 }
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
