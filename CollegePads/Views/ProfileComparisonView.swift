import SwiftUI

struct ProfileComparisonView: View {
    let candidate: UserModel
    
    // pull the current user
    private var currentUser: UserModel? {
        ProfileViewModel.shared.userProfile
    }
    
    // decide whether to show “Rent” (roommate mode) or “Budget”
    private var isComparisonRoommate: Bool {
        guard let current = currentUser else { return false }
        return current.housingStatus == PrimaryHousingPreference.lookingForRoommate.rawValue
            || candidate.housingStatus == PrimaryHousingPreference.lookingForRoommate.rawValue
    }
    
    // format a numeric min/max range as “X–Y USD”
    private func formattedRange(min: Double?, max: Double?) -> String {
        let lo = Int(min ?? 0)
        let hi = Int(max ?? 0)
        return "\(lo)–\(hi) USD"
    }
    
    var body: some View {
        NavigationView {
            if let current = currentUser {
                List {
                    ComparisonRow(field: "Grade",
                                  currentValue: current.gradeLevel,
                                  candidateValue: candidate.gradeLevel)
                    ComparisonRow(field: "Major",
                                  currentValue: current.major,
                                  candidateValue: candidate.major)
                    ComparisonRow(field: "College",
                                  currentValue: current.collegeName,
                                  candidateValue: candidate.collegeName)
                    ComparisonRow(field: "Dorm",
                                  currentValue: current.dormType,
                                  candidateValue: candidate.dormType)
                    
                    // ↳ Rent vs Budget
                    if isComparisonRoommate {
                        ComparisonRow(
                            field: "Rent",
                            currentValue: formattedRange(min: current.monthlyRentMin, max: current.monthlyRentMax),
                            candidateValue: formattedRange(min: candidate.monthlyRentMin, max: candidate.monthlyRentMax)
                        )
                    } else {
                        ComparisonRow(
                            field: "Budget",
                            currentValue: formattedRange(min: current.budgetMin, max: current.budgetMax),
                            candidateValue: formattedRange(min: candidate.budgetMin, max: candidate.budgetMax)
                        )
                    }
                    
                    ComparisonRow(field: "Cleanliness",
                                  currentValue: current.cleanliness.map { "\($0)" },
                                  candidateValue: candidate.cleanliness.map { "\($0)" })
                    ComparisonRow(field: "Sleep",
                                  currentValue: current.sleepSchedule,
                                  candidateValue: candidate.sleepSchedule)
                    ComparisonRow(field: "Living Style",
                                  currentValue: current.livingStyle,
                                  candidateValue: candidate.livingStyle)
                    ComparisonRow(field: "Interests",
                                  currentValue: current.interests?.joined(separator: ", "),
                                  candidateValue: candidate.interests?.joined(separator: ", "))
                }
                .listStyle(InsetGroupedListStyle())
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("Profile Comparison")
                            .font(AppTheme.titleFont)
                            .foregroundColor(.primary)
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            // parent handles dismiss
                        }
                    }
                }
            } else {
                ProgressView("Loading Your Profile…")
                    .font(AppTheme.bodyFont)
            }
        }
    }
}

struct ComparisonRow: View {
    let field: String
    let currentValue: String?
    let candidateValue: String?
    
    var body: some View {
        HStack {
            Text(field)
                .font(AppTheme.bodyFont.weight(.bold))
                .frame(width: 120, alignment: .leading)
            
            Spacer()
            
            VStack(alignment: .leading) {
                Text("You: \(currentValue ?? "-")")
                    .font(AppTheme.bodyFont)
                    .foregroundColor(AppTheme.primaryColor)
                Text("Candidate: \(candidateValue ?? "-")")
                    .font(AppTheme.bodyFont)
                    .foregroundColor(AppTheme.accentColor)
            }
            
            if let c = currentValue, let d = candidateValue,
               c.lowercased() == d.lowercased() {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ProfileComparisonView_Previews: PreviewProvider {
    static var previews: some View {
        // set up a dummy candidate
        let candidate = UserModel(
            email: "candidate@example.com",
            isEmailVerified: true,
            gradeLevel:       "Freshman",
            major:            "Computer Science",
            collegeName:      "Engineering",
            dormType:         "On-Campus",
            monthlyRentMin:   550, monthlyRentMax: 950,
            budgetMin:        500, budgetMax:      1000,
            cleanliness:      4,
            sleepSchedule:    "Flexible",
            smoker:           false,
            petFriendly:      true,
            livingStyle:      "Social",
            interests:        ["music", "coding"]
        )
        
        // and the current user
        ProfileViewModel.shared.userProfile = UserModel(
            email:             "current@example.com",
            isEmailVerified:   true,
            gradeLevel:        "Freshman",
            major:             "Computer Science",
            collegeName:       "Engineering",
            dormType:          "On-Campus",
            monthlyRentMin:    650, monthlyRentMax: 1000,
            budgetMin:         600, budgetMax:      1100,
            cleanliness:       5,
            sleepSchedule:     "Flexible",
            smoker:            false,
            petFriendly:       true,
            livingStyle:       "Social",
            interests:         ["coding", "sports"]
        )
        
        // finally return the comparison view
        return ProfileComparisonView(candidate: candidate)
    }
}
