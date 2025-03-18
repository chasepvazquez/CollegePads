//
//  AdvancedFilterView.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//

import SwiftUI
import CoreLocation

struct AdvancedFilterView: View {
    @StateObject private var viewModel = AdvancedFilterViewModel()
    @StateObject private var locationManager = LocationManager() // Ensure you have a LocationManager
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Filter Criteria")) {
                    TextField("Dorm Type (On-Campus, Off-Campus)", text: $viewModel.filterDormType)
                    TextField("College Name", text: $viewModel.filterCollegeName)
                    TextField("Budget Range", text: $viewModel.filterBudgetRange)
                    
                    // New Grade Group Filter
                    Picker("Grade Group", selection: $viewModel.filterGradeGroup) {
                        Text("All").tag("")
                        Text("Freshman").tag("Freshman")
                        Text("Underclassmen").tag("Underclassmen")
                        Text("Upperclassmen").tag("Upperclassmen")
                        Text("Graduate").tag("Graduate")
                    }
                    
                    TextField("Interests (comma-separated)", text: $viewModel.filterInterests)
                        .autocapitalization(.none)
                    
                    VStack {
                        Text("Max Distance: \(Int(viewModel.maxDistance)) km")
                        Slider(value: $viewModel.maxDistance, in: 1...50, step: 1)
                    }
                }
                
                Section {
                    Button("Apply Filters") {
                        viewModel.applyFilters(currentLocation: locationManager.currentLocation)
                    }
                }
            }
            .navigationTitle("Advanced Filters")
            .alert(item: Binding(
                get: {
                    if let error = viewModel.errorMessage {
                        return GenericAlertError(message: error)
                    }
                    return nil
                },
                set: { _ in viewModel.errorMessage = nil }
            )) { alertError in
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
