import SwiftUI
import CoreLocation

struct AdvancedFilterView: View {
    @StateObject private var viewModel = AdvancedFilterViewModel()
    @StateObject private var locationManager = LocationManager()

    // Options for other filters.
    let preferredGenders = ["Any", "Male", "Female", "Other"]
    
    // Use the shared GradeLevel enum from MyProfileView.
    @State private var selectedGradeLevel: MyProfileView.GradeLevel = .freshman
    @State private var localFilterMode: FilterMode = .university
    
    // College search state.
    @State private var collegeSearchQuery: String = ""
    @State private var filteredColleges: [String] = []
    
    // Alert binding helper.
    private var alertBinding: Binding<GenericAlertError?> {
        Binding<GenericAlertError?>(
            get: { self.getAlertError() },
            set: { self.setAlertError($0) }
        )
    }
    
    private func getAlertError() -> GenericAlertError? {
        if let errorMessage = viewModel.errorMessage {
            return GenericAlertError(message: errorMessage)
        }
        return nil
    }
    
    private func setAlertError(_ newValue: GenericAlertError?) {
        viewModel.errorMessage = newValue?.message
    }
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient.ignoresSafeArea()
            List {
                // Filtering Mode Section.
                Section {
                    Picker("Filter Mode", selection: $localFilterMode) {
                        ForEach(FilterMode.allCases) { mode in
                            Text(mode == .university ? "By College" : "By Distance")
                                .tag(mode)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: localFilterMode) { newMode in
                        viewModel.filterMode = newMode
                        if newMode == .university {
                            viewModel.maxDistance = 50.0
                        } else {
                            viewModel.filterCollegeName = ""
                        }
                        autoApplyAndSave()
                    }
                } header: {
                    Text("Filtering Mode")
                        .font(AppTheme.subtitleFont)
                }
                
                // Filter Criteria Section – now calls MyProfileView's properties.
                FilterCriteriaSection(
                    selectedGradeLevel: $selectedGradeLevel,
                    collegeSearchQuery: $collegeSearchQuery,
                    filteredColleges: $filteredColleges,
                    viewModel: viewModel,
                    localFilterMode: localFilterMode,
                    preferredGenders: preferredGenders,
                    autoApplyAndSave: autoApplyAndSave
                )
                
                // Filtered Users Section.
                if !viewModel.filteredUsers.isEmpty {
                    Section {
                        ForEach(viewModel.filteredUsers) { user in
                            VStack(alignment: .leading) {
                                if let firstName = user.firstName,
                                   let lastName = user.lastName,
                                   !firstName.isEmpty && !lastName.isEmpty {
                                    Text("\(firstName) \(lastName)")
                                        .font(AppTheme.titleFont)
                                } else {
                                    Text("Name not provided")
                                        .font(AppTheme.titleFont)
                                }
                                if let grade = user.gradeLevel {
                                    Text("Grade: \(grade)")
                                        .font(AppTheme.bodyFont)
                                }
                                if let housing = user.housingStatus {
                                    Text("Housing: \(housing)")
                                        .font(AppTheme.bodyFont)
                                }
                                if let interests = user.interests {
                                    Text("Interests: \(interests.joined(separator: ", "))")
                                        .font(AppTheme.bodyFont)
                                        .foregroundColor(AppTheme.secondaryColor)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    } header: {
                        Text("Filtered Users")
                            .font(AppTheme.subtitleFont)
                    }
                } else {
                    Section {
                        Text("No users found with current filters.")
                            .font(AppTheme.bodyFont)
                            .foregroundColor(.gray)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.backgroundGradient)
            .listStyle(InsetGroupedListStyle())
            .font(AppTheme.bodyFont)
            .alert(item: alertBinding) { alertError in
                Alert(title: Text("Error"),
                      message: Text(alertError.message),
                      dismissButton: .default(Text("OK")))
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Advanced Search")
                        .font(AppTheme.titleFont)
                        .foregroundColor(.primary)
                }
            }
        }
        .onAppear {
            viewModel.loadFiltersFromUserDoc {
                viewModel.applyFilters(currentLocation: locationManager.currentLocation)
            }
            UniversityDataProvider.shared.loadUniversities { colleges in
                filteredColleges = colleges
                print("AdvancedFilterView loaded \(colleges.count) colleges.")
            }
        }
    }
    
    private func autoApplyAndSave() {
        viewModel.applyFilters(currentLocation: locationManager.currentLocation)
        viewModel.saveFiltersToUserDoc()
    }
}
private struct FilterCriteriaSection: View {
    @Binding var selectedGradeLevel: MyProfileView.GradeLevel
    @Binding var collegeSearchQuery: String
    @Binding var filteredColleges: [String]
    @ObservedObject var viewModel: AdvancedFilterViewModel
    let localFilterMode: FilterMode
    let preferredGenders: [String]
    let autoApplyAndSave: () -> Void

    // Group for Grade and Housing Pickers.
    private var gradeAndHousing: some View {
        VStack(spacing: 8) {
            Picker("Grade Group", selection: $selectedGradeLevel) {
                ForEach(MyProfileView.GradeLevel.allCases) { level in
                    Text(level.rawValue).tag(level)
                }
            }
            .onChange(of: selectedGradeLevel) { newLevel in
                viewModel.filterGradeGroup = newLevel.rawValue
                autoApplyAndSave()
            }
            Picker("Housing Preference", selection: $viewModel.filterHousingPreference) {
                Text("All").tag(Optional<PrimaryHousingPreference>(nil))
                ForEach(PrimaryHousingPreference.allCases) { status in
                    Text(status.rawValue).tag(Optional(status))
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .onChange(of: viewModel.filterHousingPreference) { _ in autoApplyAndSave() }
            Picker("Room Type", selection: $viewModel.filterRoomType) {
                Text("All").tag("")
                Text("Private Room").tag("Private Room")
                Text("Shared Room").tag("Shared Room")
                Text("Studio").tag("Studio")
            }
            .onChange(of: viewModel.filterRoomType) { _ in autoApplyAndSave() }
        }
    }
    
    // Group for Amenities and Toggles.
        private var amenitiesAndToggles: some View {
            VStack(spacing: 8) {
                MultiSelectChipView(
                    options: viewModel.propertyAmenitiesOptions,  // Using the view model property
                    selectedItems: $viewModel.filterAmenities
                ) {
                    autoApplyAndSave()
                }
                Toggle("Must be Pet Friendly", isOn: Binding(
                    get: { viewModel.filterPetFriendly ?? false },
                    set: { viewModel.filterPetFriendly = $0; autoApplyAndSave() }
                ))
                Toggle("Smoker OK", isOn: Binding(
                    get: { viewModel.filterSmoker ?? false },
                    set: { viewModel.filterSmoker = $0; autoApplyAndSave() }
                ))
                Toggle("Drinker OK", isOn: Binding(
                    get: { viewModel.filterDrinker ?? false },
                    set: { viewModel.filterDrinker = $0; autoApplyAndSave() }
                ))
                Toggle("Marijuana Use OK", isOn: Binding(
                    get: { viewModel.filterMarijuana ?? false },
                    set: { viewModel.filterMarijuana = $0; autoApplyAndSave() }
                ))
                Toggle("Workout Regularly", isOn: Binding(
                    get: { viewModel.filterWorkout ?? false },
                    set: { viewModel.filterWorkout = $0; autoApplyAndSave() }
                ))
            }
        }
        
        // Group for Cleanliness and Sleep Schedule.
        private var cleanlinessAndSleep: some View {
            VStack(spacing: 8) {
                Picker("Cleanliness", selection: Binding(
                    get: { viewModel.filterCleanliness ?? 0 },
                    set: { viewModel.filterCleanliness = $0; autoApplyAndSave() }
                )) {
                    ForEach(1..<6) { number in
                        let desc = viewModel.cleanlinessDescriptions[number] ?? ""
                        Text("\(number) - \(desc)").tag(number)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                Picker("Sleep Schedule", selection: $viewModel.filterSleepSchedule) {
                    Text("All").tag("")
                    Text("Early Bird").tag("Early Bird")
                    Text("Night Owl").tag("Night Owl")
                    Text("Flexible").tag("Flexible")
                }
                .onChange(of: viewModel.filterSleepSchedule) { _ in autoApplyAndSave() }
            }
        }
    
    // Group for Rent/College Search based on mode.
    private var rentOrCollege: some View {
        VStack(spacing: 8) {
            if viewModel.filterHousingPreference == .lookingForLease {
                VStack(alignment: .leading) {
                    Text("Monthly Rent Range")
                    HStack {
                        Text("Min: \(Int(viewModel.filterMonthlyRentMin ?? 0))")
                        Slider(value: Binding(
                            get: { viewModel.filterMonthlyRentMin ?? 0 },
                            set: { viewModel.filterMonthlyRentMin = $0; autoApplyAndSave() }
                        ), in: 0...5000, step: 50)
                    }
                    HStack {
                        Text("Max: \(Int(viewModel.filterMonthlyRentMax ?? 5000))")
                        Slider(value: Binding(
                            get: { viewModel.filterMonthlyRentMax ?? 5000 },
                            set: { viewModel.filterMonthlyRentMax = $0; autoApplyAndSave() }
                        ), in: 0...5000, step: 50)
                    }
                }
            } else if localFilterMode == .university {
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
                                ForEach(filteredColleges, id: \.self) { uni in
                                    Text(uni)
                                        .padding(8)
                                        .onTapGesture {
                                            viewModel.filterCollegeName = uni
                                            collegeSearchQuery = uni
                                            filteredColleges = []
                                            autoApplyAndSave()
                                        }
                                }
                            }
                        }
                        .frame(maxHeight: 150)
                        .background(AppTheme.cardBackground.opacity(0.8))
                        .cornerRadius(8)
                    }
                }
            } else {
                VStack(alignment: .leading) {
                    Text("Max Distance: \(Int(viewModel.maxDistance)) km")
                    Slider(value: $viewModel.maxDistance, in: 1...50, step: 1)
                        .onChange(of: viewModel.maxDistance) { _ in autoApplyAndSave() }
                }
            }
        }
    }
    
    // Group for Preferred Gender and Age Difference.
    private var genderAndAge: some View {
        VStack(spacing: 8) {
            Picker("Preferred Gender", selection: $viewModel.filterPreferredGender) {
                ForEach(preferredGenders, id: \.self) { gender in
                    Text(gender).tag(gender)
                }
            }
            .onChange(of: viewModel.filterPreferredGender) { _ in autoApplyAndSave() }
            VStack(alignment: .leading) {
                Text("Max Age Difference: \(Int(viewModel.maxAgeDifference)) years")
                Slider(value: $viewModel.maxAgeDifference, in: 0...10, step: 1)
                    .onChange(of: viewModel.maxAgeDifference) { _ in autoApplyAndSave() }
            }
        }
    }
    
    var body: some View {
        Section {
            VStack(spacing: 16) {
                gradeAndHousing
                amenitiesAndToggles
                cleanlinessAndSleep
                rentOrCollege
                genderAndAge
            }
        } header: {
            Text("Filter Criteria")
                .font(AppTheme.subtitleFont)
        }
    }
}
