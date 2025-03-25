import SwiftUI
import CoreLocation

struct AdvancedFilterView: View {
    @StateObject private var viewModel = AdvancedFilterViewModel()
    @StateObject private var locationManager = LocationManager()
    
    // Options for pickers.
    let gradeLevels = ["Freshman", "Underclassmen", "Upperclassmen", "Graduate"]
    let housingStatuses = ["Dorm Resident", "Apartment Resident", "House Owner/Renter", "Subleasing", "Looking for Roommate", "Looking for Lease", "Other"]
    let leaseDurations = ["Current Lease", "Short Term (<6 months)", "Medium Term (6-12 months)", "Long Term (1 year+)", "Future: Next Year", "Future: 2+ Years", "Not Applicable"]
    
    // Alert binding.
    private var alertBinding: Binding<GenericAlertError?> {
        Binding<GenericAlertError?>(
            get: {
                if let error = viewModel.errorMessage {
                    return GenericAlertError(message: error)
                }
                return nil
            },
            set: { _ in viewModel.errorMessage = nil }
        )
    }
    
    var body: some View {
        ZStack {
            // Global background gradient.
            AppTheme.backgroundGradient.ignoresSafeArea()
            
            // Single List containing all sections (filter form + filtered results).
            List {
                // SECTION 1: Filter Criteria
                Section(header: Text("Filter Criteria")
                            .font(AppTheme.subtitleFont)) {
                    
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
                    
                    // Maximum Distance Slider
                    VStack(alignment: .leading) {
                        Text("Max Distance: \(Int(viewModel.maxDistance)) km")
                        Slider(value: $viewModel.maxDistance, in: 1...50, step: 1)
                            .onChange(of: viewModel.maxDistance) { _ in
                                autoApplyAndSave()
                            }
                    }
                }
                
                // SECTION 2: Filtered Matches
                if !viewModel.filteredUsers.isEmpty {
                    Section(header: Text("Filtered Users")
                                .font(AppTheme.subtitleFont)) {
                        ForEach(viewModel.filteredUsers) { user in
                            VStack(alignment: .leading) {
                                Text(user.email)
                                    .font(AppTheme.bodyFont)
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
                    }
                } else {
                    // If no users found, show an empty state (optional).
                    Section {
                        Text("No users found with current filters.")
                            .font(AppTheme.bodyFont)
                            .foregroundColor(.gray)
                    }
                }
            }
            // Hide the default list background so your gradient shows through.
            .scrollContentBackground(.hidden)
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
            // Optionally load saved filters from Firestore (if you want them to persist).
            viewModel.loadFiltersFromUserDoc {
                // Once loaded, apply filters automatically.
                viewModel.applyFilters(currentLocation: locationManager.currentLocation)
            }
        }
    }
    
    // Called whenever a filter changes.
    private func autoApplyAndSave() {
        // 1) Apply filters to see immediate results.
        viewModel.applyFilters(currentLocation: locationManager.currentLocation)
        // 2) Save filters to Firestore so they persist across sessions.
        viewModel.saveFiltersToUserDoc()
    }
}

struct AdvancedFilterView_Previews: PreviewProvider {
    static var previews: some View {
        AdvancedFilterView()
    }
}
