import SwiftUI
import CoreLocation

struct AdvancedFilterView: View {
    @StateObject private var viewModel = AdvancedFilterViewModel()
    @StateObject private var locationManager = LocationManager()
    
    // Options for other filters.
    let housingStatuses = ["Dorm Resident", "Apartment Resident", "House Owner/Renter", "Subleasing", "Looking for Roommate", "Looking for Lease", "Other"]
    let leaseDurations = ["Current Lease", "Short Term (<6 months)", "Medium Term (6-12 months)", "Long Term (1 year+)", "Future: Next Year", "Future: 2+ Years", "Not Applicable"]
    let preferredGenders = ["Any", "Male", "Female", "Other"]
    
    // New: Use the shared GradeLevel enum from MyProfileView.
    @State private var selectedGradeLevel: MyProfileView.GradeLevel = .freshman
    // Remove the old local gradeLevels array.
    
    @State private var localFilterMode: FilterMode = .university
    @State private var universities: [String] = []
    
    private var alertBinding: Binding<GenericAlertError?> {
        Binding<GenericAlertError?>(
            get: {
                if let error = viewModel.errorMessage {
                    return GenericAlertError(message: error)
                }
                return nil
            },
            set: { newValue in
                viewModel.errorMessage = newValue?.message
            }
        )
    }
    
    var body: some View {
        ZStack {
            // Use the proper theme background
            AppTheme.backgroundGradient.ignoresSafeArea()
            
            List {
                // Filtering Mode Section
                Section {
                    Picker("Filter Mode", selection: $localFilterMode) {
                        ForEach(FilterMode.allCases) { mode in
                            Text(mode == .university ? "By College" : "By Distance").tag(mode)
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
                    Text("Filtering Mode").font(AppTheme.subtitleFont)
                }
                
                // Filter Criteria Section
                Section {
                    // Grade Group Picker using the shared enum.
                    Picker("Grade Group", selection: $selectedGradeLevel) {
                        ForEach(MyProfileView.GradeLevel.allCases) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                    .onChange(of: selectedGradeLevel) { newLevel in
                        viewModel.filterGradeGroup = newLevel.rawValue
                        autoApplyAndSave()
                    }
                    
                    Picker("Housing Status", selection: $viewModel.filterHousingStatus) {
                        Text("All").tag("")
                        ForEach(housingStatuses, id: \.self) { status in
                            Text(status).tag(status)
                        }
                    }
                    .onChange(of: viewModel.filterHousingStatus) { _ in autoApplyAndSave() }
                    
                    Picker("Lease Duration", selection: $viewModel.filterBudgetRange) {
                        Text("All").tag("")
                        ForEach(leaseDurations, id: \.self) { duration in
                            Text(duration).tag(duration)
                        }
                    }
                    .onChange(of: viewModel.filterBudgetRange) { _ in autoApplyAndSave() }
                    
                    TextField("Interests (comma-separated)", text: $viewModel.filterInterests)
                        .autocapitalization(.none)
                        .onChange(of: viewModel.filterInterests) { _ in autoApplyAndSave() }
                    
                    if localFilterMode == .university {
                        Picker("College", selection: $viewModel.filterCollegeName) {
                            Text("All").tag("")
                            ForEach(universities, id: \.self) { uni in
                                Text(uni).tag(uni)
                            }
                        }
                        .onChange(of: viewModel.filterCollegeName) { _ in autoApplyAndSave() }
                    } else {
                        VStack(alignment: .leading) {
                            Text("Max Distance: \(Int(viewModel.maxDistance)) km")
                            Slider(value: $viewModel.maxDistance, in: 1...50, step: 1)
                                .onChange(of: viewModel.maxDistance) { _ in autoApplyAndSave() }
                        }
                    }
                    
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
                } header: {
                    Text("Filter Criteria").font(AppTheme.subtitleFont)
                }
                
                // Filtered Users Section
                if !viewModel.filteredUsers.isEmpty {
                    Section {
                        ForEach(viewModel.filteredUsers) { user in
                            VStack(alignment: .leading) {
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
                        Text("Filtered Users").font(AppTheme.subtitleFont)
                    }
                } else {
                    Section {
                        Text("No users found with current filters.")
                            .font(AppTheme.bodyFont)
                            .foregroundColor(.gray)
                    }
                }
            }
            // Apply the proper themed background.
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
            // Asynchronously load and cache valid college names.
            UniversityDataProvider.shared.loadUniversities { colleges in
                self.universities = colleges
                print("AdvancedFilterView loaded \(colleges.count) colleges.")
            }
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
