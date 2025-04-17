// AdvancedFilterView.swift

import SwiftUI
import CoreLocation

struct AdvancedFilterView: View {
    @StateObject private var viewModel = AdvancedFilterViewModel()
    @StateObject private var locationManager = LocationManager()
    
    let preferredGenders = ["Any", "Male", "Female", "Other"]
    @State private var selectedGradeLevel: MyProfileView.GradeLevel = .freshman
    @State private var localFilterMode: FilterMode = .university
    
    /// allColleges holds the full list, loaded once on appear
    @State private var allColleges: [String] = []
    
    // College search state:
    @State private var collegeSearchQuery: String = ""
    @State private var filteredColleges: [String] = []
    
    private var alertBinding: Binding<GenericAlertError?> {
      Binding(
        get: { viewModel.errorMessage.map(GenericAlertError.init) },
        set: { _ in viewModel.errorMessage = nil }
      )
    }

    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient.ignoresSafeArea()
            List {
                Section {
                    Picker("Filter Mode", selection: $localFilterMode) {
                        ForEach(FilterMode.allCases) { mode in
                            Text(mode == .university ? "By College" : "By Distance")
                                .tag(mode)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: localFilterMode) { new in
                        viewModel.filterMode = new
                        if new == .university {
                            viewModel.maxDistance = 50.0
                        } else {
                            viewModel.filterCollegeName = ""
                        }
                        autoApplyAndSave()
                    }
                } header: {
                    Text("Filtering Mode").font(AppTheme.subtitleFont)
                }
                
                FilterCriteriaSection(
                    selectedGradeLevel: $selectedGradeLevel,
                    collegeSearchQuery: $collegeSearchQuery,
                    filteredColleges: $filteredColleges,
                    viewModel: viewModel,
                    localFilterMode: localFilterMode,
                    preferredGenders: preferredGenders,
                    autoApplyAndSave: autoApplyAndSave
                )
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.backgroundGradient)
            .listStyle(InsetGroupedListStyle())
            .font(AppTheme.bodyFont)
            .alert(item: alertBinding) { err in
                Alert(title: Text("Error"), message: Text(err.message), dismissButton: .default(Text("OK")))
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Advanced Search").font(AppTheme.titleFont)
                }
            }
        }
        .onAppear {
            // 1️⃣ Load saved filters & sync UI state
            viewModel.loadFiltersFromUserDoc {
                localFilterMode       = viewModel.filterMode
                selectedGradeLevel    = MyProfileView.GradeLevel(rawValue: viewModel.filterGradeGroup) ?? .freshman
                collegeSearchQuery    = viewModel.filterCollegeName
                viewModel.applyFilters(currentLocation: locationManager.currentLocation)
            }
            // 2️⃣ Then load the college list
            UniversityDataProvider.shared.loadUniversities { colleges in
                allColleges = colleges
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
    
    private var gradeAndHousing: some View {
        VStack(spacing: 8) {
            Picker("Grade Group", selection:
                Binding<MyProfileView.GradeLevel>(
                  get: {
                    // On each display, read the stored string and map back to the enum
                    MyProfileView.GradeLevel(rawValue: viewModel.filterGradeGroup)
                      ?? .freshman
                  },
                  set: { newLevel in
                    // When the user picks, store and save immediately
                    viewModel.filterGradeGroup = newLevel.rawValue
                    autoApplyAndSave()
                  }
                )
            ) {
                ForEach(MyProfileView.GradeLevel.allCases) { level in
                    Text(level.rawValue).tag(level)
                }
            }
            Picker("Housing Preference", selection: $viewModel.filterHousingPreference) {
                Text("All").tag(Optional<PrimaryHousingPreference>(nil))
                ForEach(PrimaryHousingPreference.allCases) {
                    Text($0.rawValue).tag(Optional($0))
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
    
    private var amenitiesAndToggles: some View {
        VStack(spacing: 8) {
            MultiSelectChipView(options: viewModel.propertyAmenitiesOptions,
                                selectedItems: $viewModel.filterAmenities) {
                autoApplyAndSave()
            }
            Toggle("Must be Pet Friendly",
                   isOn: Binding(get: { viewModel.filterPetFriendly ?? false },
                                 set: { viewModel.filterPetFriendly = $0; autoApplyAndSave() }))
            Toggle("Smoker OK",
                   isOn: Binding(get: { viewModel.filterSmoker ?? false },
                                 set: { viewModel.filterSmoker = $0; autoApplyAndSave() }))
            Toggle("Drinker OK",
                   isOn: Binding(get: { viewModel.filterDrinker ?? false },
                                 set: { viewModel.filterDrinker = $0; autoApplyAndSave() }))
            Toggle("Marijuana Use OK",
                   isOn: Binding(get: { viewModel.filterMarijuana ?? false },
                                 set: { viewModel.filterMarijuana = $0; autoApplyAndSave() }))
            Toggle("Workout Regularly",
                   isOn: Binding(get: { viewModel.filterWorkout ?? false },
                                 set: { viewModel.filterWorkout = $0; autoApplyAndSave() }))
        }
    }
    
    private var cleanlinessAndSleep: some View {
        VStack(spacing: 8) {
            Picker("Cleanliness", selection:
                Binding(get: { viewModel.filterCleanliness ?? 0 },
                        set: { viewModel.filterCleanliness = $0; autoApplyAndSave() })) {
                ForEach(1..<6) {
                    Text("\($0) – \(viewModel.cleanlinessDescriptions[$0]!)").tag($0)
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
    
    // MARK: — Housing & College/Distance
        private var housingSpecificFilters: some View {
            VStack(spacing: 16) {
                // 1️⃣ Lease sliders
                if viewModel.filterHousingPreference == .lookingForLease {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Monthly Rent Range").font(.headline)
                        HStack {
                            Text("Min: \(Int(viewModel.filterMonthlyRentMin ?? 0))")
                            Slider(
                                value: Binding(
                                    get: { viewModel.filterMonthlyRentMin ?? 0 },
                                    set: {
                                        viewModel.filterMonthlyRentMin = $0
                                        autoApplyAndSave()
                                    }
                                ),
                                in: 0...5000, step: 50
                            )
                        }
                        HStack {
                            Text("Max: \(Int(viewModel.filterMonthlyRentMax ?? 5000))")
                            Slider(
                                value: Binding(
                                    get: { viewModel.filterMonthlyRentMax ?? 5000 },
                                    set: {
                                        viewModel.filterMonthlyRentMax = $0
                                        autoApplyAndSave()
                                    }
                                ),
                                in: 0...5000, step: 50
                            )
                        }
                    }
                }
                // 2️⃣ Find‑Together budget sliders
                else if viewModel.filterHousingPreference == .lookingToFindTogether
                     || viewModel.filterHousingPreference == .lookingForRoommate {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Budget Range").font(.headline)
                        HStack {
                            Text("Min: \(Int(viewModel.filterBudgetMin ?? 0))")
                            Slider(
                                value: Binding(
                                    get: { viewModel.filterBudgetMin ?? 0 },
                                    set: {
                                        viewModel.filterBudgetMin = $0
                                        autoApplyAndSave()
                                    }
                                ),
                                in: 0...5000, step: 50
                            )
                        }
                        HStack {
                            Text("Max: \(Int(viewModel.filterBudgetMax ?? 5000))")
                            Slider(
                                value: Binding(
                                    get: { viewModel.filterBudgetMax ?? 5000 },
                                    set: {
                                        viewModel.filterBudgetMax = $0
                                        autoApplyAndSave()
                                    }
                                ),
                                in: 0...5000, step: 50
                            )
                        }
                    }
                }
                // 3️⃣ By College search
                if localFilterMode == .university {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("College").font(.headline)
                        TextField("Search College", text: $collegeSearchQuery)
                            .disableAutocorrection(true)
                            .textInputAutocapitalization(.never)
                            .padding(8)
                            .background(AppTheme.cardBackground)
                            .cornerRadius(8)
                            .onChange(of: collegeSearchQuery) { q in
                                let trimmed = q.trimmingCharacters(in: .whitespaces)
                                filteredColleges = trimmed.isEmpty
                                    ? []
                                    : UniversityDataProvider.shared.searchUniversities(query: trimmed)
                            }
                        if !filteredColleges.isEmpty {
                            ScrollView {
                                VStack(alignment: .leading, spacing: 4) {
                                    ForEach(filteredColleges, id: \.self) { college in
                                        Text(college)
                                            .padding(8)
                                            .onTapGesture {
                                                collegeSearchQuery = college
                                                viewModel.filterCollegeName = college
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
                }
                // 4️⃣ By Distance slider
                if localFilterMode == .distance {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Max Distance: \(Int(viewModel.maxDistance)) km")
                            .font(.headline)
                        Slider(
                            value: Binding(
                                get: { viewModel.maxDistance },
                                set: {
                                    viewModel.maxDistance = $0
                                    autoApplyAndSave()
                                }
                            ),
                            in: 0...100,
                            step: 1
                        )
                    }
                }
            }
        }
    
    private var genderAndAge: some View {
        VStack(spacing: 8) {
            Picker("Preferred Gender", selection: $viewModel.filterPreferredGender) {
                ForEach(preferredGenders, id: \.self) { Text($0).tag($0) }
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
        Section(header: Text("Filter Criteria").font(AppTheme.subtitleFont)) {
            VStack(spacing: 16) {
                gradeAndHousing
                amenitiesAndToggles
                cleanlinessAndSleep
                housingSpecificFilters
                genderAndAge
            }
        }
    }
}
