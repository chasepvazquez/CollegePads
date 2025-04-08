import SwiftUI

/// Preview mode selection for ProfilePreviewView.
enum PreviewMode: String, CaseIterable, Identifiable {
    case personal = "Personal"
    case lease = "Lease"
    var id: String { self.rawValue }
}

/// A unified preview that merges CandidateProfileView features into the original swipeable layout.
/// In addition to the current personal preview (for roommate profiles) the Lease mode is available – showing key property and lease information in multiple slides.
struct ProfilePreviewView: View {
    let user: UserModel

    // Tracks the current image index for the page-based swipe.
    @State private var currentIndex: Int = 0

    // Preview mode toggle between Personal and Lease modes.
    // For users looking for a roommate, both personal and lease previews are available.
    // For users looking for a lease, only the lease preview is used.
    @State private var previewMode: PreviewMode = .personal

    // For reporting/blocking.
    @State private var showReportSheet = false
    @State private var showBlockAlert = false
    @State private var errorMessage: String?

    // Approximate Tinder ratio (3:4 or 4:5).
    private let cardAspectRatio: CGFloat = 0.75

    // Helper computed property to check if the user is in roommate mode.
    private var isRoommateMode: Bool {
        // Assuming PrimaryHousingPreference.lookingForRoommate.rawValue exists.
        return user.housingStatus == PrimaryHousingPreference.lookingForRoommate.rawValue
    }
    
    // MARK: - Personal Info Snippets (for Roommate Preview)
    private var infoSnippets: [[String]] {
        var snippets: [[String]] = []
        // For roommate mode, replace the first slide with a relevant field (e.g. "Bio").
        if isRoommateMode {
            if let bio = user.aboutMe, !bio.isEmpty {
                snippets.append(["Bio: \(bio)"])
            } else if let college = user.collegeName, !college.isEmpty {
                let ageString = (calculateAge(from: user.dateOfBirth).map { "Age: \($0)" }) ?? "Age: ?"
                snippets.append(["College: \(college)", ageString])
            } else {
                let ageString = (calculateAge(from: user.dateOfBirth).map { "Age: \($0)" }) ?? "Age: ?"
                snippets.append([ageString])
            }
        } else {
            // In lease mode personal preview (if ever used) or fallback.
            let ageString = (calculateAge(from: user.dateOfBirth).map { "Age: \($0)" }) ?? "Age: ?"
            if let college = user.collegeName, !college.isEmpty {
                snippets.append(["College: \(college)", ageString])
            } else {
                snippets.append([ageString])
            }
        }
        
        // Slide: Major.
        if let major = user.major, !major.isEmpty {
            snippets.append(["Major: \(major)"])
        }
        
        // Slide: Dorm Type – note: for roommate preview we are NOT showing budget.
        if let dorm = user.dormType, !dorm.isEmpty {
            snippets.append(["Dorm Type: \(dorm)"])
        }
        
        // Slide: Cleanliness and Sleep info.
        if let cleanliness = user.cleanliness, let schedule = user.sleepSchedule, !schedule.isEmpty {
            snippets.append(["Cleanliness: \(cleanliness)/5", "Sleep: \(schedule)"])
        } else if let cleanliness = user.cleanliness {
            snippets.append(["Cleanliness: \(cleanliness)/5"])
        } else if let schedule = user.sleepSchedule, !schedule.isEmpty {
            snippets.append(["Sleep: \(schedule)"])
        }
        
        // Slide: Smoker and Pets info.
        if let smoker = user.smoker, let pet = user.petFriendly {
            snippets.append(["Smoker: \(smoker ? "Yes" : "No")", "Pets: \(pet ? "Yes" : "No")"])
        } else if let smoker = user.smoker {
            snippets.append(["Smoker: \(smoker ? "Yes" : "No")"])
        } else if let pet = user.petFriendly {
            snippets.append(["Pets: \(pet ? "Yes" : "No")"])
        }
        
        // For non-roommate mode, include About Me if available.
        if !isRoommateMode {
            if let about = user.aboutMe, !about.isEmpty {
                snippets.append(["About Me:", about])
            }
        }
        
        // Slide: Interests.
        if let interests = user.interests, !interests.isEmpty {
            snippets.append(["Interests:", interests.joined(separator: ", ")])
        }
        
        return snippets
    }
    
    /// Computed array of personal preview snippets matching the number of uploaded personal images.
    private var finalSnippets: [[String]] {
        let count = user.profileImageUrls?.count ?? 0
        var snippets = infoSnippets
        let fullName = [user.firstName, user.lastName].compactMap { $0 }.joined(separator: " ")
        while snippets.count < count {
            snippets.append([fullName])
        }
        return snippets
    }
    
    // MARK: - Lease Info Snippets (for Lease Preview Mode)
    private var leaseInfoSnippets: [[String]] {
        var snippets: [[String]] = []
        if user.housingStatus == PrimaryHousingPreference.lookingForLease.rawValue {
            // In Lease mode show budget as the first slide.
            if let budget = user.budgetRange, !budget.isEmpty {
                snippets.append(["Budget: \(budget)"])
            } else {
                snippets.append(["Budget: N/A"])
            }
        } else {
            // For Roommate mode, do not display budget.
            // Start with monthly rent.
            if let rent = user.monthlyRent {
                snippets.append(["Rent: $\(rent)"])
            } else {
                snippets.append(["Rent: N/A"])
            }
        }
        
        // Next slides (identical in both modes except the first slide):
        // Slide: Lease Start Date & Duration.
        let leaseStart = user.leaseStartDate != nil ? DateFormatter.localizedString(from: user.leaseStartDate!, dateStyle: .medium, timeStyle: .none) : "N/A"
        let leaseDur = user.leaseDuration ?? "N/A"
        snippets.append(["Start: \(leaseStart)", "Duration: \(leaseDur)"])
        
        // Slide: Special Lease Conditions (up to 2).
        if let conditions = user.specialLeaseConditions, !conditions.isEmpty {
            let cond = conditions.prefix(2).joined(separator: ", ")
            snippets.append(["Special: \(cond)"])
        } else {
            snippets.append(["Special: N/A"])
        }
        
        // Slide: Property Details summary.
        if let details = user.propertyDetails, !details.isEmpty {
            snippets.append(["Property: \(details)"])
        } else {
            snippets.append(["Property: N/A"])
        }
        
        // Slide: Amenities summary.
        if let amens = user.amenities, !amens.isEmpty {
            snippets.append(["Amenities: \(amens.joined(separator: ", "))"])
        } else {
            snippets.append(["Amenities: N/A"])
        }
        
        // Slide: Room Type.
        if let room = user.roomType, !room.isEmpty {
            snippets.append(["Room: \(room)"])
        } else {
            snippets.append(["Room: N/A"])
        }
        
        // Slide: Cleanliness and Sleep.
        if let cleanliness = user.cleanliness, let sleep = user.sleepSchedule, !sleep.isEmpty {
            snippets.append(["Cleanliness: \(cleanliness)/5", "Sleep: \(sleep)"])
        } else {
            snippets.append(["Cleanliness/Sleep: N/A"])
        }
        
        // Slide: Interests summary.
        if let interests = user.interests, !interests.isEmpty {
            snippets.append(["Interests: \(interests.joined(separator: ", "))"])
        } else {
            snippets.append(["Interests: N/A"])
        }
        
        return snippets
    }
    
    /// Slide count for lease preview mode is now dynamically determined.
    private var leaseSlideCount: Int {
        return leaseInfoSnippets.count
    }
    
    // MARK: - Body
    var body: some View {
        VStack {
            // For "Looking for Roommate" mode, show the segmented picker to toggle between Personal and Lease previews.
            // For "Looking for Lease" mode, do not show the picker.
            if isRoommateMode {
                Picker("Preview Mode", selection: $previewMode) {
                    ForEach(PreviewMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
            }
            
            ZStack {
                if user.housingStatus == PrimaryHousingPreference.lookingForLease.rawValue {
                    // In Lease mode, force the lease preview.
                    if let images = user.propertyImageUrls, images.count > 0 {
                        leaseCardView(with: images)
                    } else {
                        Text("No images to preview")
                            .font(AppTheme.bodyFont)
                            .foregroundColor(.gray)
                    }
                } else if isRoommateMode {
                    // In Roommate mode, allow toggling between Personal and Lease previews.
                    if previewMode == .personal, let images = user.profileImageUrls, images.count > 0 {
                        cardView(with: images)
                    } else if previewMode == .lease, let images = user.propertyImageUrls, images.count > 0 {
                        leaseCardView(with: images)
                    } else {
                        Text("No images to preview")
                            .font(AppTheme.bodyFont)
                            .foregroundColor(.gray)
                    }
                } else {
                    Text("No images to preview")
                        .font(AppTheme.bodyFont)
                        .foregroundColor(.gray)
                }
            }
        }
        .alert(item: Binding(
            get: {
                if let err = errorMessage {
                    return GenericAlertError(message: err)
                }
                return nil
            },
            set: { _ in errorMessage = nil }
        )) { alertError in
            Alert(title: Text("Error"),
                  message: Text(alertError.message),
                  dismissButton: .default(Text("OK")))
        }
        .actionSheet(isPresented: $showBlockAlert) { blockActionSheet }
        .sheet(isPresented: $showReportSheet) {
            if let userID = user.id {
                ReportUserView(reportedUserID: userID)
            } else {
                Text("No user ID found.")
            }
        }
    }
    
    // MARK: - Card Views
    
    /// Card view for Personal Preview Mode (used when looking for a roommate).
    private func cardView(with images: [String]) -> some View {
        Group {
            if (user.profileImageUrls?.count ?? 0) > 0 {
                ZStack {
                    TabView(selection: $currentIndex) {
                        ForEach(0..<(user.profileImageUrls?.count ?? 0), id: \.self) { idx in
                            ZStack {
                                backgroundImage(for: images[safe: idx])
                                bottomOverlay(for: finalSnippets[idx])
                            }
                            .tag(idx)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    
                    pageIndicator(for: user.profileImageUrls?.count ?? 0)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 12)
                        .frame(maxHeight: .infinity, alignment: .top)
                    
                    topRightIcons
                }
                .aspectRatio(cardAspectRatio, contentMode: .fit)
                .cornerRadius(15)
                .shadow(radius: 5)
                .padding()
            } else {
                fallbackImageTabView(images: images)
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .aspectRatio(cardAspectRatio, contentMode: .fit)
                    .cornerRadius(15)
                    .shadow(radius: 5)
                    .padding()
            }
        }
    }
    
    /// Card view for Lease Preview Mode – uses property images and lease info snippets.
    private func leaseCardView(with images: [String]) -> some View {
        Group {
            if leaseSlideCount > 0 {
                ZStack {
                    TabView(selection: $currentIndex) {
                        ForEach(0..<leaseSlideCount, id: \.self) { idx in
                            ZStack {
                                backgroundImage(for: images[safe: idx])
                                bottomOverlay(for: leaseInfoSnippets[idx])
                            }
                            .tag(idx)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    
                    pageIndicator(for: leaseSlideCount)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 12)
                        .frame(maxHeight: .infinity, alignment: .top)
                    
                    topRightIcons
                }
                .aspectRatio(cardAspectRatio, contentMode: .fit)
                .cornerRadius(15)
                .shadow(radius: 5)
                .padding()
            } else {
                fallbackImageTabView(images: images)
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .aspectRatio(cardAspectRatio, contentMode: .fit)
                    .cornerRadius(15)
                    .shadow(radius: 5)
                    .padding()
            }
        }
    }
    
    /// Returns a bottom overlay with the provided snippet lines.
    private func bottomOverlay(for snippet: [String]) -> some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.6)]),
                startPoint: .center,
                endPoint: .bottom
            )
            .allowsHitTesting(false)
            
            VStack(alignment: .leading, spacing: 6) {
                let fullName = [user.firstName, user.lastName].compactMap { $0 }.joined(separator: " ")
                if !fullName.isEmpty {
                    Text(fullName)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.8), radius: 1, x: 0, y: 1)
                }
                ForEach(snippet, id: \.self) { line in
                    Text(line)
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.8), radius: 1, x: 0, y: 1)
                        .lineLimit(nil)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 36)
        }
    }
    
    /// Custom dot indicator to display the current slide.
    private func pageIndicator(for count: Int) -> some View {
        HStack(spacing: 8) {
            ForEach(0..<count, id: \.self) { index in
                Circle()
                    .fill(index == currentIndex ? Color.white : Color.white.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
    }
    
    /// Top-right icons for verification and report/block actions.
    private var topRightIcons: some View {
        HStack(spacing: 8) {
            if user.isVerified == true {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(.green)
                    .font(.title3)
            }
            Button(action: { showReportSheet = true }) {
                Image(systemName: "shield")
                    .foregroundColor(.white)
                    .font(.title3)
            }
            .contextMenu {
                Button("Report User") { showReportSheet = true }
                Button("Block User", role: .destructive) { showBlockAlert = true }
            }
        }
        .padding([.top, .trailing], 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
    }
    
    /// Background image for each slide – images are shown in the order of upload.
    private func backgroundImage(for urlString: String?) -> some View {
        if let urlStr = urlString, let url = URL(string: urlStr) {
            return AnyView(
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        return AnyView(ProgressView())
                    case .success(let image):
                        return AnyView(
                            GeometryReader { geo in
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: geo.size.width, height: geo.size.height)
                                    .clipped()
                            }
                        )
                    case .failure:
                        return AnyView(Color.gray)
                    @unknown default:
                        return AnyView(Color.gray)
                    }
                }
            )
        } else {
            return AnyView(Color.gray)
        }
    }
    
    /// Fallback view if there are no images.
    private func fallbackImageTabView(images: [String]) -> some View {
        TabView {
            ForEach(0..<images.count, id: \.self) { index in
                if let url = URL(string: images[index]) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .clipped()
                        case .failure:
                            Color.gray
                        @unknown default:
                            Color.gray
                        }
                    }
                } else {
                    Color.gray
                }
            }
        }
    }
    
    /// The action sheet for blocking a user.
    private var blockActionSheet: ActionSheet {
        ActionSheet(
            title: Text("Block User"),
            message: Text("Are you sure you want to block this user? They will no longer appear in your matches."),
            buttons: [
                .destructive(Text("Block")) { blockUser() },
                .cancel()
            ]
        )
    }
    
    private func blockUser() {
        guard let userID = user.id else {
            errorMessage = "No user ID found to block."
            return
        }
        let blockVM = BlockUserViewModel()
        blockVM.blockUser(candidateID: userID) { result in
            switch result {
            case .success:
                ProfileViewModel.shared.removeBlockedUser(with: userID)
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func calculateAge(from dob: String?) -> Int? {
        guard let dob = dob, !dob.isEmpty else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let birthDate = formatter.date(from: dob) {
            let now = Date()
            let comps = Calendar.current.dateComponents([.year], from: birthDate, to: now)
            return comps.year
        }
        return nil
    }
}

// MARK: - Array Safe Subscript
fileprivate extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

struct ProfilePreviewView_Previews: PreviewProvider {
    static var previews: some View {
        // Example: change housingStatus to test each mode.
        // For Looking for Lease mode, set housingStatus to PrimaryHousingPreference.lookingForLease.rawValue
        // For Looking for Roommate mode, set housingStatus to PrimaryHousingPreference.lookingForRoommate.rawValue
        let sampleUser = UserModel(
            // 1. Basic Info
            email: "test@edu",
            isEmailVerified: true,
            // createdAt is optional and defaults to Date() if omitted
            
            // 2. Personal Info
            aboutMe: "I love coding, coffee, and late-night debugging!",
            firstName: "Chase",
            lastName: "Vazquez",
            dateOfBirth: "2004-09-09",
            gender: nil,
            height: nil,
            
            // 3. Academic Info
            gradeLevel: nil,
            major: "Computer Science",
            collegeName: "CLA",
            
            // 4. Housing & Lease Info
            housingStatus: PrimaryHousingPreference.lookingForRoommate.rawValue,
            dormType: "On-Campus",
            preferredDorm: nil,
            desiredLeaseHousingType: nil,
            roommateCountNeeded: nil,
            roommateCountExisting: nil,
            
            // 5. Property Details
            propertyDetails: "Spacious apartment close to campus",
            propertyImageUrls: [
                "https://picsum.photos/id/200/400/600",
                "https://picsum.photos/id/201/400/600",
                "https://picsum.photos/id/202/400/600",
                "https://picsum.photos/id/203/400/600",
                "https://picsum.photos/id/204/400/600",
                "https://picsum.photos/id/205/400/600",
                "https://picsum.photos/id/206/400/600",
                "https://picsum.photos/id/207/400/600"
            ],
            floorplanUrls: nil,
            documentUrls: nil,
            
            // 6. Room Type Selector
            roomType: "Single",
            
            // 7. Lease & Pricing Details
            leaseStartDate: Date(),
            leaseDuration: "12 months",
            monthlyRent: nil,
            specialLeaseConditions: ["No pets", "No smoking"],
            
            // 8. Amenities Multi-Select Field
            amenities: ["Pool", "Gym"],
            
            // 9. Additional Housing Fields
            budgetRange: "$500-$1000",
            cleanliness: 5,
            sleepSchedule: "Flexible",
            smoker: false,
            petFriendly: true,
            livingStyle: nil,
            
            // 10. Interests
            socialLevel: nil,
            studyHabits: nil,
            interests: ["Photography", "Music", "Sports"],
            
            // 11. Media & Location
            profileImageUrl: nil,
            profileImageUrls: [
                "https://picsum.photos/id/1025/400/600",
                "https://picsum.photos/id/1035/400/600",
                "https://picsum.photos/id/1037/400/600",
                "https://picsum.photos/id/1040/400/600",
                "https://picsum.photos/id/1041/400/600",
                "https://picsum.photos/id/1042/400/600",
                "https://picsum.photos/id/1043/400/600",
                "https://picsum.photos/id/1044/400/600",
                "https://picsum.photos/id/1045/400/600"
            ],
            location: nil,
            
            // 12. Verification
            isVerified: true,
            
            // 13. Blocked Users
            blockedUserIDs: nil,
            
            // 14. Advanced Filter Settings
            filterSettings: nil,
            
            // 15. Lifestyle Fields
            pets: nil,
            drinking: nil,
            smoking: nil,
            cannabis: nil,
            workout: nil,
            dietaryPreferences: nil,
            socialMedia: nil,
            sleepingHabits: nil,
            
            // 16. Quiz Answers
            goingOutQuizAnswers: nil,
            weekendQuizAnswers: nil,
            phoneQuizAnswers: nil
        )
        
        return NavigationView {
            ProfilePreviewView(user: sampleUser)
        }
    }
}
