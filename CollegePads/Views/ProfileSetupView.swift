//
//  ProfileSetupView.swift
//  CollegePads
//
//  Updated to include input validations, improved user feedback, and refined UI
//

import SwiftUI
import FirebaseAuth

struct ProfileSetupView: View {
    @StateObject private var viewModel = ProfileViewModel.shared

    // MARK: - Freeform Fields
    @State private var major: String = ""
    @State private var collegeName: String = ""
    @State private var interestsText: String = ""
    @State private var budgetRange: String = ""
    
    // Other freeform fields
    @State private var cleanliness: Int = 3
    @State private var sleepSchedule: String = "Flexible"
    @State private var smoker: Bool = false
    @State private var petFriendly: Bool = false

    // MARK: - Finite Options (Pickers)
    enum GradeLevel: String, CaseIterable, Identifiable {
        case freshman = "Freshman"
        case sophomore = "Sophomore"
        case junior = "Junior"
        case senior = "Senior"
        case graduate = "Graduate"
        case phd = "PhD"
        case other = "Other"
        var id: String { self.rawValue }
    }
    @State private var selectedGradeLevel: GradeLevel = .freshman
    
    enum HousingStatus: String, CaseIterable, Identifiable {
        case dorm = "Dorm Resident"
        case apartment = "Apartment Resident"
        case house = "House Owner/Renter"
        case subleasing = "Subleasing"
        case lookingForRoommate = "Looking for Roommate"
        case lookingForLease = "Looking for Lease"
        case other = "Other"
        var id: String { self.rawValue }
    }
    @State private var selectedHousingStatus: HousingStatus = .dorm
    
    enum LeaseDuration: String, CaseIterable, Identifiable {
        case current = "Current Lease"
        case shortTerm = "Short Term (<6 months)"
        case mediumTerm = "Medium Term (6-12 months)"
        case longTerm = "Long Term (1 year+)"
        case futureNextYear = "Future: Next Year"
        case futureTwoPlus = "Future: 2+ Years"
        case notApplicable = "Not Applicable"
        var id: String { self.rawValue }
    }
    @State private var selectedLeaseDuration: LeaseDuration = .notApplicable

    // MARK: - Profile Image
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    
    // MARK: - Alert for Validation Errors
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    // MARK: - Freeform Options for Sleep Schedule
    let sleepScheduleOptions = ["Early Bird", "Night Owl", "Flexible"]

    var body: some View {
        NavigationView {
            Form {
                // Profile Completion Meter Section
                if let profile = viewModel.userProfile {
                    let completion = ProfileCompletionCalculator.calculateCompletion(for: profile)
                    VStack(alignment: .leading) {
                        Text("Profile Completion: \(Int(completion))%")
                            .font(.caption)
                        ProgressView(value: completion, total: 100)
                            .accentColor(.green)
                    }
                    .padding(.vertical, 8)
                }
                
                // Profile Picture Section
                Section(header: Text("Profile Picture")) {
                    HStack {
                        Spacer()
                        if let image = selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .onTapGesture { showingImagePicker = true }
                        } else if let urlStr = viewModel.userProfile?.profileImageUrl, let url = URL(string: urlStr) {
                            AsyncImage(url: url) { phase in
                                if let image = phase.image {
                                    image.resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 120, height: 120)
                                        .clipShape(Circle())
                                        .onTapGesture { showingImagePicker = true }
                                } else {
                                    Image(systemName: "person.crop.circle")
                                        .resizable()
                                        .frame(width: 120, height: 120)
                                        .onTapGesture { showingImagePicker = true }
                                }
                            }
                        } else {
                            Image(systemName: "person.crop.circle")
                                .resizable()
                                .frame(width: 120, height: 120)
                                .onTapGesture { showingImagePicker = true }
                        }
                        Spacer()
                    }
                }
                
                // Basic Info Section
                Section(header: Text("Basic Info")) {
                    Picker("Grade Level", selection: $selectedGradeLevel) {
                        ForEach(GradeLevel.allCases) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                    TextField("Major (e.g., Computer Science)", text: $major)
                    TextField("College Name (e.g., Engineering)", text: $collegeName)
                    TextField("Email", text: .constant(viewModel.userProfile?.email ?? ""))
                        .disabled(true)
                }
                
                // Housing Preferences Section
                Section(header: Text("Housing Preferences")) {
                    Picker("Housing Status", selection: $selectedHousingStatus) {
                        ForEach(HousingStatus.allCases) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }
                    
                    if selectedHousingStatus == .apartment || selectedHousingStatus == .house || selectedHousingStatus == .subleasing || selectedHousingStatus == .lookingForLease {
                        Picker("Lease Duration", selection: $selectedLeaseDuration) {
                            ForEach(LeaseDuration.allCases) { duration in
                                Text(duration.rawValue).tag(duration)
                            }
                        }
                    }
                    
                    TextField("Budget Range (e.g., $500 - $1000)", text: $budgetRange)
                    Picker("Cleanliness (1-5)", selection: $cleanliness) {
                        ForEach(1..<6) { number in
                            Text("\(number)").tag(number)
                        }
                    }
                    Picker("Sleep Schedule", selection: $sleepSchedule) {
                        ForEach(sleepScheduleOptions, id: \.self) { option in
                            Text(option)
                        }
                    }
                    Toggle("Smoker", isOn: $smoker)
                    Toggle("Pet Friendly", isOn: $petFriendly)
                }
                
                // Interests Section
                Section(header: Text("Interests")) {
                    TextField("Enter interests separated by commas", text: $interestsText)
                        .autocapitalization(.none)
                }
                
                // Save Button Section
                Section {
                    Button(action: saveProfile) {
                        Text("Save Profile")
                    }
                    .buttonStyle(PrimaryButtonStyle(backgroundColor: Color.brandPrimary))
                }
            }
            .navigationTitle("Profile Setup")
            .onAppear {
                viewModel.loadUserProfile()
            }
            .onReceive(viewModel.$userProfile) { profile in
                guard let profile = profile else { return }
                selectedGradeLevel = GradeLevel(rawValue: profile.gradeLevel ?? "") ?? .freshman
                major = profile.major ?? ""
                collegeName = profile.collegeName ?? ""
                selectedHousingStatus = HousingStatus(rawValue: profile.housingStatus ?? "") ?? .other
                selectedLeaseDuration = LeaseDuration(rawValue: profile.leaseDuration ?? "") ?? .notApplicable
                budgetRange = profile.budgetRange ?? ""
                cleanliness = profile.cleanliness ?? 3
                sleepSchedule = profile.sleepSchedule ?? "Flexible"
                smoker = profile.smoker ?? false
                petFriendly = profile.petFriendly ?? false
                interestsText = profile.interests?.joined(separator: ", ") ?? ""
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedImage)
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Validation Error"),
                      message: Text(alertMessage),
                      dismissButton: .default(Text("OK")))
            }
        }
    }
    
    /// Validates and saves the updated profile to Firestore.
    private func saveProfile() {
        // Validate required fields
        guard !major.trimmingCharacters(in: .whitespaces).isEmpty,
              !collegeName.trimmingCharacters(in: .whitespaces).isEmpty else {
            alertMessage = "Major and College Name are required fields."
            showAlert = true
            return
        }
        
        let interestsArray = interestsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        
        var updatedProfile = viewModel.userProfile ?? UserModel(email: Auth.auth().currentUser?.email ?? "", isEmailVerified: false)
        updatedProfile.gradeLevel = selectedGradeLevel.rawValue
        updatedProfile.major = major
        updatedProfile.collegeName = collegeName
        updatedProfile.budgetRange = budgetRange
        updatedProfile.cleanliness = cleanliness
        updatedProfile.sleepSchedule = sleepSchedule
        updatedProfile.smoker = smoker
        updatedProfile.petFriendly = petFriendly
        updatedProfile.interests = interestsArray
        
        // Update housing status and lease duration.
        updatedProfile.housingStatus = selectedHousingStatus.rawValue
        updatedProfile.leaseDuration = selectedLeaseDuration.rawValue
        
        viewModel.updateUserProfile(updatedProfile: updatedProfile) { result in
            switch result {
            case .success:
                print("Profile successfully updated.")
            case .failure(let error):
                alertMessage = "Error updating profile: \(error.localizedDescription)"
                showAlert = true
            }
        }
    }
}

struct ProfileSetupView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileSetupView()
    }
}
