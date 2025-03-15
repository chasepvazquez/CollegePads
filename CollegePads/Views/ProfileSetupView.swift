//
//  ProfileSetupView.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//

import SwiftUI
import FirebaseAuth

struct ProfileSetupView: View {
    @StateObject private var viewModel = ProfileViewModel.shared

    // Local form fields
    @State private var dormType: String = ""
    @State private var budgetRange: String = ""
    @State private var cleanliness: Int = 3
    @State private var sleepSchedule: String = "Flexible"
    @State private var smoker: Bool = false
    @State private var petFriendly: Bool = false
    @State private var gradeLevel: String = ""
    @State private var major: String = ""
    @State private var collegeName: String = ""

    // For profile image selection
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    
    // Options for the sleep schedule picker
    let sleepScheduleOptions = ["Early Bird", "Night Owl", "Flexible"]

    var body: some View {
        NavigationView {
            Form {
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
                
                Section(header: Text("Basic Info")) {
                    TextField("Grade Level (e.g., Freshman)", text: $gradeLevel)
                    TextField("Major (e.g., Computer Science)", text: $major)
                    TextField("College Name (e.g., Engineering)", text: $collegeName)
                    TextField("Email", text: .constant(viewModel.userProfile?.email ?? ""))
                        .disabled(true)
                }
                
                Section(header: Text("Roommate Preferences")) {
                    TextField("Dorm Type (e.g., On-Campus, Off-Campus)", text: $dormType)
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
                
                Section {
                    Button(action: saveProfile) {
                        Text("Save Profile")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationTitle("Profile Setup")
            .onAppear { viewModel.loadUserProfile() }
            .onReceive(viewModel.$userProfile) { profile in
                guard let profile = profile else { return }
                dormType = profile.dormType ?? ""
                budgetRange = profile.budgetRange ?? ""
                cleanliness = profile.cleanliness ?? 3
                sleepSchedule = profile.sleepSchedule ?? "Flexible"
                smoker = profile.smoker ?? false
                petFriendly = profile.petFriendly ?? false
                gradeLevel = profile.gradeLevel ?? ""
                major = profile.major ?? ""
                collegeName = profile.collegeName ?? ""
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedImage)
            }
            // Updated onChange to new two-parameter closure
            .onChange(of: selectedImage) { newImage, _ in
                guard let image = newImage else { return }
                FirebaseStorageService.shared.uploadProfileImage(image: image) { result in
                    switch result {
                    case .success(let urlString):
                        if var existingProfile = viewModel.userProfile {
                            existingProfile.profileImageUrl = urlString
                            viewModel.updateUserProfile(updatedProfile: existingProfile) { _ in }
                        }
                    case .failure(let error):
                        print("Failed to upload image: \(error.localizedDescription)")
                    }
                }
            }
            .alert(item: Binding(
                get: {
                    if let errorMessage = viewModel.errorMessage {
                        return ProfileAlertError(message: errorMessage)
                    }
                    return nil
                },
                set: { _ in viewModel.errorMessage = nil }
            )) { alertError in
                Alert(title: Text("Error"), message: Text(alertError.message), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    private func saveProfile() {
        if var existingProfile = viewModel.userProfile {
            existingProfile.dormType = dormType
            existingProfile.budgetRange = budgetRange
            existingProfile.cleanliness = cleanliness
            existingProfile.sleepSchedule = sleepSchedule
            existingProfile.smoker = smoker
            existingProfile.petFriendly = petFriendly
            existingProfile.gradeLevel = gradeLevel
            existingProfile.major = major
            existingProfile.collegeName = collegeName
            
            viewModel.updateUserProfile(updatedProfile: existingProfile) { result in
                switch result {
                case .success:
                    break
                case .failure(let error):
                    viewModel.errorMessage = error.localizedDescription
                }
            }
        } else {
            let newProfile = UserModel(
                email: Auth.auth().currentUser?.email ?? "",
                isEmailVerified: Auth.auth().currentUser?.isEmailVerified ?? false,
                gradeLevel: gradeLevel,
                major: major,
                collegeName: collegeName,
                dormType: dormType,
                preferredDorm: nil,
                budgetRange: budgetRange,
                cleanliness: cleanliness,
                sleepSchedule: sleepSchedule,
                smoker: smoker,
                petFriendly: petFriendly,
                livingStyle: nil
            )
            viewModel.updateUserProfile(updatedProfile: newProfile) { result in
                switch result {
                case .success:
                    break
                case .failure(let error):
                    viewModel.errorMessage = error.localizedDescription
                }
            }
        }
    }
}

struct ProfileAlertError: Identifiable {
    let id = UUID()
    let message: String
}
