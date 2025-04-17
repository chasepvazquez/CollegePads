import SwiftUI
import CoreLocation

// MARK: - Preview Mode Definition
enum PreviewMode: String, CaseIterable, Identifiable {
    case personal = "Personal"
    case lease = "Lease"
    var id: String { self.rawValue }
}

// MARK: - ProfilePreviewView
struct ProfilePreviewView: View {
    let user: UserModel

    // Tracks the current image index for the page-based swipe.
    @State private var currentIndex: Int = 0

    // Persist the preview mode in storage so it remains selected across view launches.
    @AppStorage("profilePreviewMode") private var previewModeRaw: String = PreviewMode.personal.rawValue
    private var previewMode: PreviewMode {
        get { PreviewMode(rawValue: previewModeRaw) ?? .personal }
        set { previewModeRaw = newValue.rawValue }
    }

    // Reporting/blocking state.
    @State private var showReportSheet = false
    @State private var showBlockAlert = false
    @State private var errorMessage: String?

    // Tinder card aspect ratio.
    private let cardAspectRatio: CGFloat = 0.75

    // Computed property to check if the user is in roommate mode.
    private var isRoommateMode: Bool {
        return user.housingStatus == PrimaryHousingPreference.lookingForRoommate.rawValue
    }
    
    // Convenience: full name.
    private var fullName: String {
        [user.firstName, user.lastName].compactMap { $0 }.joined(separator: " ")
    }
    
    // MARK: - Initializer
    init(user: UserModel, forcePreviewMode: PreviewMode? = nil) {
        self.user = user
        if let forced = forcePreviewMode {
            _previewModeRaw.wrappedValue = forced.rawValue
        } else {
            // For roommate mode, allow toggling; for lease and for our new 'Looking to Find Together' mode, force lease preview.
            if user.housingStatus == PrimaryHousingPreference.lookingForRoommate.rawValue {
                // leave the segmented picker as is
            } else if user.housingStatus == PrimaryHousingPreference.lookingToFindTogether.rawValue {
                _previewModeRaw.wrappedValue = PreviewMode.lease.rawValue
            } else {
                _previewModeRaw.wrappedValue = PreviewMode.personal.rawValue
            }
        }
    }
    
    // MARK: - Overlay Lists for Personal Previews (unchanged)
    private var personalOverlays: [[String]] {
        return [
            [
                "College: \(user.collegeName ?? "N/A")",
                "Age: \(calculateAge(from: user.dateOfBirth) ?? 0)",
                "Major: \(user.major ?? "N/A")",
                "Grade Level: \(user.gradeLevel ?? "N/A")"
            ],
            [ user.aboutMe?.isEmpty == false ? "Bio: \(user.aboutMe!)" : fullName ],
            [ "Workout: \(user.workout ?? "N/A")" ],
            [
                "Drinking: \(user.drinking ?? "N/A")",
                "Smoking: \((user.smoker ?? false) ? "Yes" : "No")",
                "420 Friendly: \(user.cannabis ?? "N/A")"
            ],
            [ "Going Out Quiz: \(user.goingOutQuizAnswers?.joined(separator: ", ") ?? "N/A")" ],
            [ "Weekends Quiz: \(user.weekendQuizAnswers?.joined(separator: ", ") ?? "N/A")" ],
            [
                "Pets: \((user.petFriendly ?? false) ? "Yes" : "No")",
                "Selected Pets: \(user.pets?.joined(separator: ", ") ?? "N/A")"
            ],
            [ "Interests: \(user.interests?.joined(separator: ", ") ?? "N/A")" ],
            [
                "MyPhone Quiz: \(user.phoneQuizAnswers?.joined(separator: ", ") ?? "N/A")",
                "Social Media: \(user.socialMedia ?? "N/A")"
            ]
        ]
    }
    
    // MARK: - New Lease Overlay Helper
    /// Returns the overlay lines for each lease preview slide.
    private func leaseOverlay(for slideIndex: Int) -> [String] {
        switch slideIndex {
        case 0:
            // Slide 0: Display housing type selected (from secondaryHousingType), room type, and monthly rent.
            let housing = (user.desiredLeaseHousingType ?? "").isEmpty ? "N/A" : (user.desiredLeaseHousingType ?? "N/A")
            let room = (user.roomType ?? "").isEmpty ? "N/A" : (user.roomType ?? "N/A")
            let minR = user.monthlyRentMin.map { Int($0) } ?? 0
            let maxR = user.monthlyRentMax.map { Int($0) } ?? 0
            let rentRange = (user.monthlyRentMin != nil && user.monthlyRentMax != nil)
                ? "\(minR)–\(maxR) USD" : "N/A"
            return ["Housing: \(housing)", "Room Type: \(room)", "Monthly Rent: \(rentRange)"]
        case 1:
            // Slide 1: No overlay.
            return []
        case 2:
            // Slide 2: Lease start date and lease duration.
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            let leaseStart = (user.leaseStartDate != nil) ? formatter.string(from: user.leaseStartDate!) : "N/A"
            let duration = (user.leaseDuration ?? "").isEmpty ? "N/A" : (user.leaseDuration ?? "N/A")
            return ["Lease Start: \(leaseStart)", "Lease Duration: \(duration)"]
        case 3:
            // Slide 3: Roommates already had and roommates needed.
            let already = user.roommateCountExisting != nil ? "\(user.roommateCountExisting!)" : "0"
            let needed = user.roommateCountNeeded != nil ? "\(user.roommateCountNeeded!)" : "0"
            return ["Roommates Already: \(already)", "Roommates Needed: \(needed)"]
        case 4:
            // Slide 4: Property details bio.
            return [ (user.propertyDetails ?? "").isEmpty ? "No Property Details" : (user.propertyDetails ?? "No Property Details") ]
        case 5:
            // Slide 5: First 5 special lease conditions.
            if let conditions = user.specialLeaseConditions, !conditions.isEmpty {
                let slice = conditions.prefix(5)
                return Array(slice)
            } else {
                return ["No special lease conditions"]
            }
        case 6:
            // Slide 6: Next 5 special lease conditions.
            if let conditions = user.specialLeaseConditions, conditions.count > 5 {
                let remainder = conditions.dropFirst(5).prefix(5)
                return Array(remainder)
            } else {
                return ["No special lease conditions"]
            }
        case 7:
            // Slide 7: First 5 amenities.
            if let amens = user.amenities, !amens.isEmpty {
                let slice = amens.prefix(5)
                return Array(slice)
            } else {
                return ["No amenities"]
            }
        case 8:
            // Slide 8: Next 5 amenities.
            if let amens = user.amenities, amens.count > 5 {
                let remainder = amens.dropFirst(5).prefix(5)
                return Array(remainder)
            } else {
                return ["No amenities"]
            }
        case 9:
            // Slide 9: Cleanliness and sleeping habits.
            let cleanText = (user.cleanliness != nil) ? "Cleanliness: \(user.cleanliness!)/5" : "Cleanliness: N/A"
            let sleepText = (user.sleepSchedule ?? "").isEmpty ? "Sleeping Habits: N/A" : "Sleeping Habits: \(user.sleepSchedule!)"
            return [cleanText, sleepText]
        default:
            return []
        }
    }
    
    // MARK: - Body
    var body: some View {
        VStack {
            if user.housingStatus == PrimaryHousingPreference.lookingForRoommate.rawValue {
                // Show the Picker when in roommate mode.
                Picker("Preview Mode", selection: $previewModeRaw) {
                    ForEach(PreviewMode.allCases, id: \.rawValue) { mode in
                        Text(mode.rawValue).tag(mode.rawValue)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
            } else {
                // For non-roommate users, force previewMode to personal.
                EmptyView()
                    .onAppear {
                        previewModeRaw = PreviewMode.personal.rawValue
                    }
            }
            
            ZStack {
                if user.housingStatus == PrimaryHousingPreference.lookingForRoommate.rawValue {
                    // Roommate mode: toggle between Personal and Lease preview.
                    if previewMode == .personal, let images = user.profileImageUrls, !images.isEmpty {
                        cardView(with: images, overlays: personalOverlays)
                    } else if previewMode == .lease, let images = user.propertyImageUrls, !images.isEmpty {
                        leaseCardView(with: images)
                    } else {
                        Text("No images to preview")
                            .font(AppTheme.bodyFont)
                            .foregroundColor(.gray)
                    }
                } else {
                    // Non-roommate: always show the personal preview.
                    if let images = user.profileImageUrls, !images.isEmpty {
                        cardView(with: images, overlays: personalOverlays)
                    } else {
                        Text("No images to preview")
                            .font(AppTheme.bodyFont)
                            .foregroundColor(.gray)
                    }
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
        )) { (alertError: GenericAlertError) in
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
    
    // MARK: - Card View Builders
    private func cardView(with images: [String], overlays: [[String]]) -> some View {
        Group {
            if !images.isEmpty {
                ZStack {
                    TabView(selection: $currentIndex) {
                        ForEach(0..<min(images.count, overlays.count), id: \.self) { idx in
                            ZStack {
                                backgroundImage(for: images[safe: idx])
                                bottomOverlay(for: overlays[idx])
                            }
                            .tag(idx)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .overlay(
                        pageIndicator(for: min(images.count, overlays.count))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 12),
                        alignment: .top
                    )
                    .overlay(topRightIcons, alignment: .topTrailing)
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
    
    private func leaseCardView(with images: [String]) -> some View {
        var slides: [(AnyView, [String])] = []
        // Slide 0: Floorplan background and overlay.
        if let floorplan = images.first, !floorplan.isEmpty {
            slides.append((AnyView(backgroundImage(for: floorplan)), leaseOverlay(for: 0)))
        }
        // Slide 1: Map view if available.
        if user.location != nil {
            slides.append((AnyView(
                UserLocationMapView(
                    coordinate: CLLocationCoordinate2D(latitude: user.location!.latitude, longitude: user.location!.longitude)
                )
            ), leaseOverlay(for: 1)))
        }
        // For slides 2 to 9, use additional images.
        let additional = Array(images.dropFirst())
        for index in 2...9 {
            if let bg = additional[safe: index - 2], !bg.isEmpty {
                slides.append((AnyView(backgroundImage(for: bg)), leaseOverlay(for: index)))
            }
        }
        
        return ZStack {
            if !slides.isEmpty {
                TabView(selection: $currentIndex) {
                    ForEach(0..<slides.count, id: \.self) { idx in
                        ZStack {
                            slides[idx].0
                            let overlay = slides[idx].1
                            if !overlay.isEmpty {
                                bottomOverlay(for: overlay)
                            }
                        }
                        .tag(idx)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .overlay(
                    pageIndicator(for: slides.count)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 12),
                    alignment: .top
                )
                .overlay(topRightIcons, alignment: .topTrailing)
            } else {
                EmptyView()
            }
        }
        .aspectRatio(cardAspectRatio, contentMode: .fit)
        .cornerRadius(15)
        .shadow(radius: 5)
        .padding()
    }
    
    // MARK: - Overlay & Utility Views
    private func bottomOverlay(for snippet: [String]) -> some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.6)]),
                startPoint: .center,
                endPoint: .bottom
            )
            .allowsHitTesting(false)
            VStack(alignment: .leading, spacing: 6) {
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
    
    private func pageIndicator(for count: Int) -> some View {
        HStack(spacing: 8) {
            ForEach(0..<count, id: \.self) { index in
                Circle()
                    .fill(index == currentIndex ? Color.white : Color.white.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
    }
    
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
        let sampleUser = UserModel(
            email: "test@edu",
            isEmailVerified: true,
            aboutMe: "I love coding, coffee, and late-night debugging!",
            firstName: "Chase",
            lastName: "Vazquez",
            dateOfBirth: "2004-09-09",
            gender: nil,
            height: nil,
            gradeLevel: "Freshman",
            major: "Computer Science",
            collegeName: "CLA",
            housingStatus: PrimaryHousingPreference.lookingForLease.rawValue,
            dormType: "On-Campus",
            preferredDorm: nil,
            desiredLeaseHousingType: "Apartment",
            roommateCountNeeded: 2,
            roommateCountExisting: 1,
            propertyDetails: "Spacious apartment close to campus. Recently renovated, modern fixtures.",
            propertyAddress: "123 Main St, Springfield, USA",
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
            roomType: "Single",
            leaseStartDate: Date(),
            leaseDuration: "12 months",
            monthlyRentMin: 950,
            monthlyRentMax: 950,
            specialLeaseConditions: ["No pets", "No smoking"],
            amenities: ["Pool", "Gym", "Parking", "High-Speed Internet", "Furnished"],
            budgetMin: 500,
            budgetMax: 1000,
            cleanliness: 5,
            sleepSchedule: "Flexible",
            smoker: false,
            petFriendly: true,
            livingStyle: nil,
            socialLevel: nil,
            studyHabits: nil,
            interests: ["Photography", "Music", "Sports"],
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
            isVerified: true,
            blockedUserIDs: nil,
            filterSettings: nil,
            pets: ["Dog", "Cat"],
            drinking: "Socially on weekends",
            smoking: "Non-smoker",
            cannabis: "Never",
            workout: "Often",
            dietaryPreferences: ["Vegetarian"],
            socialMedia: "Socially active",
            sleepingHabits: "Night owl",
            goingOutQuizAnswers: ["Dancing 💃"],
            weekendQuizAnswers: ["Cozy nights in 🏡"],
            phoneQuizAnswers: ["Replies quickly ⚡"]
        )
        return NavigationView {
            ProfilePreviewView(user: sampleUser)
        }
    }
}
