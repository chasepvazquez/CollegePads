//
//  AdvancedFilterView.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//
//  This view provides a form for specifying advanced filter criteria for potential roommate matches.
//  It includes pickers for grade group, housing status, and lease duration (if applicable),
//  a text field for interests, and a slider for maximum distance.
//  The filtered results are displayed in a list.
import SwiftUI
import CoreLocation

struct AdvancedFilterView: View {
    @StateObject private var viewModel = AdvancedFilterViewModel()
    @StateObject private var locationManager = LocationManager() // Ensure you have an implementation.
    
    // Options for pickers.
    let gradeLevels = ["Freshman", "Underclassmen", "Upperclassmen", "Graduate"]
    let housingStatuses = ["Dorm Resident", "Apartment Resident", "House Owner/Renter", "Subleasing", "Looking for Roommate", "Looking for Lease", "Other"]
    let leaseDurations = ["Current Lease", "Short Term (<6 months)", "Medium Term (6-12 months)", "Long Term (1 year+)", "Future: Next Year", "Future: 2+ Years", "Not Applicable"]
    
    // Extract the alert binding to reduce complexity.
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
        NavigationView {
            VStack {
                Form {
                    // Using older Section initializer syntax.
                    Section(header: Text("Filter Criteria"), content: {
                        // Grade Group Picker
                        Picker("Grade Group", selection: $viewModel.filterGradeGroup) {
                            Text("All").tag("")
                            ForEach(gradeLevels, id: \.self) { level in
                                Text(level).tag(level)
                            }
                        }
                        
                        // Housing Status Picker
                        Picker("Housing Status", selection: $viewModel.filterHousingStatus) {
                            Text("All").tag("")
                            ForEach(housingStatuses, id: \.self) { status in
                                Text(status).tag(status)
                            }
                        }
                        
                        // Lease Duration Picker (using filterBudgetRange as a placeholder; consider adding a dedicated property)
                        Picker("Lease Duration", selection: $viewModel.filterBudgetRange) {
                            Text("All").tag("")
                            ForEach(leaseDurations, id: \.self) { duration in
                                Text(duration).tag(duration)
                            }
                        }
                        
                        // Interests Text Field
                        TextField("Interests (comma-separated)", text: $viewModel.filterInterests)
                            .autocapitalization(.none)
                        
                        // Maximum Distance Slider
                        VStack {
                            Text("Max Distance: \(Int(viewModel.maxDistance)) km")
                            Slider(value: $viewModel.maxDistance, in: 1...50, step: 1)
                        }
                    })
                    
                    Section(header: Text(""), content: {
                        Button("Apply Filters") {
                            viewModel.applyFilters(currentLocation: locationManager.currentLocation)
                        }
                    })
                }
                
                // Display filtered matches.
                List(viewModel.filteredUsers) { user in
                    VStack(alignment: .leading) {
                        Text(user.email)
                            .font(.headline)
                        if let grade = user.gradeLevel {
                            Text("Grade: \(grade)")
                                .font(.subheadline)
                        }
                        if let housing = user.housingStatus {
                            Text("Housing: \(housing)")
                                .font(.subheadline)
                        }
                        if let interests = user.interests {
                            Text("Interests: \(interests.joined(separator: ", "))")
                                .font(.footnote)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .navigationTitle("Advanced Filters")
            .alert(item: alertBinding) { alertError in
                Alert(title: Text("Error"), message: Text(alertError.message), dismissButton: .default(Text("OK")))
            }
        }
    }
}

struct AdvancedFilterView_Previews: PreviewProvider {
    static var previews: some View {
        AdvancedFilterView()
    }
}
