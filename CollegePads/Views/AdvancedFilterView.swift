//
//  AdvancedFilterView.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//

import SwiftUI

struct AdvancedFilterView: View {
    @StateObject private var viewModel = AdvancedFilterViewModel()

    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section(header: Text("Filter Criteria")) {
                        TextField("Dorm Type (On-Campus, Off-Campus)", text: $viewModel.filterDormType)
                        TextField("College Name (e.g., Engineering)", text: $viewModel.filterCollegeName)
                        TextField("Budget Range (exact match)", text: $viewModel.filterBudgetRange)
                        TextField("Grade Level (e.g., Freshman)", text: $viewModel.filterGradeLevel)
                    }

                    Button("Apply Filters") {
                        viewModel.applyFilters()
                    }
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                }

                List(viewModel.filteredUsers) { user in
                    VStack(alignment: .leading) {
                        Text(user.email)
                            .font(.headline)
                        if let dorm = user.dormType {
                            Text("Dorm: \(dorm)")
                        }
                        if let college = user.collegeName {
                            Text("College: \(college)")
                        }
                        if let budget = user.budgetRange {
                            Text("Budget: \(budget)")
                        }
                        if let grade = user.gradeLevel {
                            Text("Grade: \(grade)")
                        }
                    }
                }
            }
            .navigationTitle("Advanced Filter")
        }
    }
}

struct AdvancedFilterView_Previews: PreviewProvider {
    static var previews: some View {
        AdvancedFilterView()
    }
}
