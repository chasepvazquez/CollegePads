import SwiftUI
import CoreLocation

struct AdvancedFilterView: View {
    @StateObject private var viewModel = AdvancedFilterViewModel()
    @StateObject private var locationManager = LocationManager()
    
    // Options for pickers.
    let gradeLevels = ["Freshman", "Underclassmen", "Upperclassmen", "Graduate"]
    let housingStatuses = ["Dorm Resident", "Apartment Resident", "House Owner/Renter", "Subleasing", "Looking for Roommate", "Looking for Lease", "Other"]
    let leaseDurations = ["Current Lease", "Short Term (<6 months)", "Medium Term (6-12 months)", "Long Term (1 year+)", "Future: Next Year", "Future: 2+ Years", "Not Applicable"]
    // New options for Preferred Gender filter.
    let preferredGenders = ["Any", "Male", "Female", "Other"]
    
    // New: Filtering mode segmented control (university vs. distance).
    @State private var localFilterMode: FilterMode = .university
    // New: List of universities loaded from CSV.
    @State private var universities: [String] = []
    
    // Alert binding.
    private var alertBinding: Binding<GenericAlertError?> {
        Binding<GenericAlertError?>(
            get: {
                if let error = viewModel.errorMessage {
                    return GenericAlertError(message: error)
                }
                return nil
            },
            set: { (newValue: GenericAlertError?) in
                viewModel.errorMessage = newValue?.message
            }
        )
    }
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient.ignoresSafeArea()
            
            List {
                // New Section: Filter Mode
                Section {
                    Picker("Filter Mode", selection: $localFilterMode) {
                        ForEach(FilterMode.allCases) { mode in
                            Text(mode == .university ? "By College" : "By Distance").tag(mode)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: localFilterMode) { newMode in
                        viewModel.filterMode = newMode
                        // When switching modes, clear the unused filter.
                        if newMode == .university {
                            viewModel.maxDistance = 50.0 // set a non-restrictive default if needed
                        } else {
                            viewModel.filterCollegeName = ""
                        }
                        autoApplyAndSave()
                    }
                } header: {
                    Text("Filtering Mode")
                        .font(AppTheme.subtitleFont)
                }
                
                // SECTION 1: Filter Criteria
                Section {
                    // Grade Group Picker
                    Picker("Grade Group", selection: $viewModel.filterGradeGroup) {
                        Text("All").tag("")
                        ForEach(gradeLevels, id: \.self) { level in
                            Text(level).tag(level)
                        }
                    }
                    .onChange(of: viewModel.filterGradeGroup) { _ in
                        autoApplyAndSave()
                    }
                    
                    // Housing Status Picker
                    Picker("Housing Status", selection: $viewModel.filterHousingStatus) {
                        Text("All").tag("")
                        ForEach(housingStatuses, id: \.self) { status in
                            Text(status).tag(status)
                        }
                    }
                    .onChange(of: viewModel.filterHousingStatus) { _ in
                        autoApplyAndSave()
                    }
                    
                    // Lease Duration Picker
                    Picker("Lease Duration", selection: $viewModel.filterBudgetRange) {
                        Text("All").tag("")
                        ForEach(leaseDurations, id: \.self) { duration in
                            Text(duration).tag(duration)
                        }
                    }
                    .onChange(of: viewModel.filterBudgetRange) { _ in
                        autoApplyAndSave()
                    }
                    
                    // Interests Text Field
                    TextField("Interests (comma-separated)", text: $viewModel.filterInterests)
                        .autocapitalization(.none)
                        .onChange(of: viewModel.filterInterests) { _ in
                            autoApplyAndSave()
                        }
                    
                    // Conditionally show either the University Picker or the Distance Slider.
                    if localFilterMode == .university {
                        // University Picker populated from the CSV.
                        Picker("College", selection: $viewModel.filterCollegeName) {
                            Text("All").tag("")
                            ForEach(universities, id: \.self) { uni in
                                Text(uni).tag(uni)
                            }
                        }
                        .onChange(of: viewModel.filterCollegeName) { _ in
                            autoApplyAndSave()
                        }
                    } else {
                        // Maximum Distance Slider
                        VStack(alignment: .leading) {
                            Text("Max Distance: \(Int(viewModel.maxDistance)) km")
                            Slider(value: $viewModel.maxDistance, in: 1...50, step: 1)
                                .onChange(of: viewModel.maxDistance) { _ in
                                    autoApplyAndSave()
                                }
                        }
                    }
                    
                    // Preferred Roommate Gender Picker
                    Picker("Preferred Gender", selection: $viewModel.filterPreferredGender) {
                        ForEach(preferredGenders, id: \.self) { gender in
                            Text(gender).tag(gender)
                        }
                    }
                    .onChange(of: viewModel.filterPreferredGender) { _ in
                        autoApplyAndSave()
                    }
                    
                    // Maximum Age Difference Slider
                    VStack(alignment: .leading) {
                        Text("Max Age Difference: \(Int(viewModel.maxAgeDifference)) years")
                        Slider(value: $viewModel.maxAgeDifference, in: 0...10, step: 1)
                            .onChange(of: viewModel.maxAgeDifference) { _ in
                                autoApplyAndSave()
                            }
                    }
                } header: {
                    Text("Filter Criteria")
                        .font(AppTheme.subtitleFont)
                }
                
                // SECTION 2: Filtered Matches
                if !viewModel.filteredUsers.isEmpty {
                    Section {
                        ForEach(viewModel.filteredUsers) { user in
                            VStack(alignment: .leading) {
                                // Display candidate's full name if available.
                                if let firstName = user.firstName, let lastName = user.lastName,
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
            // Load any previously saved filters.
            viewModel.loadFiltersFromUserDoc {
                viewModel.applyFilters(currentLocation: locationManager.currentLocation)
            }
            // Load the CSV from the app bundle.
            self.universities = loadUniversities()
        }
    }
    
    /// Loads the CSV file bundled in the app and parses out the list of university names.
    /// Assumes that the CSV has a header row and one column named "INSTNM" (or containing "institution").
    private func loadUniversities() -> [String] {
        guard let url = Bundle.main.url(forResource: "Most-Recent-Cohorts-Institution", withExtension: "csv") else {
            print("CSV file not found")
            return []
        }
        do {
            let content = try String(contentsOf: url)
            var lines = content.components(separatedBy: "\n")
            guard let headerLine = lines.first else { return [] }
            let headers = headerLine.components(separatedBy: ",")
            // Look for the column header that holds the institution name.
            let universityNameIndex: Int?
            if let idx = headers.firstIndex(where: { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "instnm" }) {
                universityNameIndex = idx
            } else if let idx = headers.firstIndex(where: { $0.lowercased().contains("institution") }) {
                universityNameIndex = idx
            } else {
                print("Institution name column not found in CSV")
                return []
            }
            let index = universityNameIndex!
            // Parse the remaining lines.
            var unis = [String]()
            for line in lines.dropFirst() {
                // Ignore empty lines.
                if line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { continue }
                let fields = line.components(separatedBy: ",")
                if fields.count > index {
                    let name = fields[index].trimmingCharacters(in: .whitespacesAndNewlines)
                    if !name.isEmpty {
                        unis.append(name)
                    }
                }
            }
            return unis.sorted()
        } catch {
            print("Error reading CSV: \(error.localizedDescription)")
            return []
        }
    }
    
    private func autoApplyAndSave() {
        viewModel.applyFilters(currentLocation: locationManager.currentLocation)
        viewModel.saveFiltersToUserDoc()
    }
}

struct AdvancedFilterView_Previews: PreviewProvider {
    static var previews: some View {
        AdvancedFilterView()
    }
}
