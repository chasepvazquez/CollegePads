import SwiftUI

/// A unified preview that merges CandidateProfileView features into the original swipeable layout.
struct ProfilePreviewView: View {
    let user: UserModel
    
    // Tracks the current image index for the page-based swipe.
    @State private var currentIndex: Int = 0
    
    // For reporting/blocking.
    @State private var showReportSheet = false
    @State private var showBlockAlert = false
    @State private var errorMessage: String?
    
    // Approximate Tinder ratio (3:4 or 4:5).
    private let cardAspectRatio: CGFloat = 0.75
    
    // MARK: - Info Snippets
    //
    // Removed the name from the snippet, so we can always show the name in bold
    // at the bottom overlay. The snippet now holds only the rest of the info.
    private var infoSnippets: [[String]] {
        let ageString = (calculateAge(from: user.dateOfBirth).map { "Age: \($0)" }) ?? "Age: ?"
        var snippets: [[String]] = []
        
        // Slide 1: If a college exists, show it above age.
        if let college = user.collegeName, !college.isEmpty {
            snippets.append(["College: \(college)", ageString])
        } else {
            snippets.append([ageString])
        }
        
        // Slide 2: Major (if available)
        if let major = user.major, !major.isEmpty {
            snippets.append(["Major: \(major)"])
        }
        
        // Slide 3: Dorm Type + Budget
        if let dorm = user.dormType, !dorm.isEmpty,
           let budget = user.budgetRange, !budget.isEmpty {
            snippets.append(["Dorm Type: \(dorm)", "Budget: \(budget)"])
        } else if let dorm = user.dormType, !dorm.isEmpty {
            snippets.append(["Dorm Type: \(dorm)"])
        } else if let budget = user.budgetRange, !budget.isEmpty {
            snippets.append(["Budget: \(budget)"])
        }
        
        // Slide 4: Cleanliness + Sleep
        if let cleanliness = user.cleanliness,
           let schedule = user.sleepSchedule, !schedule.isEmpty {
            snippets.append(["Cleanliness: \(cleanliness)/5", "Sleep: \(schedule)"])
        } else if let cleanliness = user.cleanliness {
            snippets.append(["Cleanliness: \(cleanliness)/5"])
        } else if let schedule = user.sleepSchedule, !schedule.isEmpty {
            snippets.append(["Sleep: \(schedule)"])
        }
        
        // Slide 5: Smoker + Pets
        if let smoker = user.smoker,
           let pet = user.petFriendly {
            snippets.append(["Smoker: \(smoker ? "Yes" : "No")", "Pets: \(pet ? "Yes" : "No")"])
        } else if let smoker = user.smoker {
            snippets.append(["Smoker: \(smoker ? "Yes" : "No")"])
        } else if let pet = user.petFriendly {
            snippets.append(["Pets: \(pet ? "Yes" : "No")"])
        }
        
        // Slide 6: About Me
        if let about = user.aboutMe, !about.isEmpty {
            snippets.append(["About Me:", about])
        }
        
        // Slide 7: Interests
        if let interests = user.interests, !interests.isEmpty {
            snippets.append(["Interests:", interests.joined(separator: ", ")])
        }
        
        return snippets
    }
    
    private var slideCount: Int {
        let imageCount = user.profileImageUrls?.count ?? 0
        return min(imageCount, infoSnippets.count)
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            if let images = user.profileImageUrls, !images.isEmpty {
                cardView(with: images)
            } else {
                Text("No images to preview")
                    .font(AppTheme.bodyFont)
                    .foregroundColor(.gray)
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
        .actionSheet(isPresented: $showBlockAlert) {
            blockActionSheet
        }
        .sheet(isPresented: $showReportSheet) {
            if let userID = user.id {
                ReportUserView(reportedUserID: userID)
            } else {
                Text("No user ID found.")
            }
        }
    }
    
    /// The card view that contains the images (or TabView) and its overlays.
    private func cardView(with images: [String]) -> some View {
        Group {
            if slideCount > 0 {
                ZStack {
                    TabView(selection: $currentIndex) {
                        ForEach(0..<slideCount, id: \.self) { idx in
                            ZStack {
                                backgroundImage(for: images[safe: idx])
                                bottomOverlay(index: idx)
                            }
                            .tag(idx)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    
                    // Page indicator: same top padding as icons, centered horizontally.
                    pageIndicator
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 12)
                        .frame(maxHeight: .infinity, alignment: .top)
                    
                    // Verification/report icons: unchanged, pinned top-right with 12 padding.
                    HStack(spacing: 8) {
                        if user.isVerified == true {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.green)
                                .font(.title3)
                        }
                        Button(action: {
                            showReportSheet = true
                        }) {
                            Image(systemName: "shield")
                                .foregroundColor(.white)
                                .font(.title3)
                        }
                        .contextMenu {
                            Button("Report User") {
                                showReportSheet = true
                            }
                            Button("Block User", role: .destructive) {
                                showBlockAlert = true
                            }
                        }
                    }
                    .padding([.top, .trailing], 12)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                }
                .aspectRatio(cardAspectRatio, contentMode: .fit)
                .cornerRadius(15)
                .shadow(radius: 5)
                .padding()
            } else {
                // Fallback: if snippet count doesn't match image count, use a simple TabView.
                fallbackImageTabView(images: images)
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .aspectRatio(cardAspectRatio, contentMode: .fit)
                    .cornerRadius(15)
                    .shadow(radius: 5)
                    .padding()
            }
        }
    }
}

// MARK: - Subviews & Helpers
extension ProfilePreviewView {
    
    /// Custom dot indicator to display the current slide.
    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<slideCount, id: \.self) { index in
                Circle()
                    .fill(index == currentIndex ? Color.white : Color.white.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
    }
    
    /// Bottom overlay that displays the user's name in bold on every slide,
    /// plus the snippet lines for the current slide in normal (unbolded) text.
    @ViewBuilder
    private func bottomOverlay(index: Int) -> some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.6)]),
                startPoint: .center,
                endPoint: .bottom
            )
            .allowsHitTesting(false)
            
            VStack(alignment: .leading, spacing: 6) {
                // Always show the name in bold.
                let fullName = [user.firstName, user.lastName]
                    .compactMap { $0 }
                    .joined(separator: " ")
                
                if !fullName.isEmpty {
                    Text(fullName)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.8), radius: 1, x: 0, y: 1)
                }
                
                // Show the snippet lines unbolded.
                let snippet = infoSnippets[index]
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
    
    /// Background image for each slide.
    @ViewBuilder
    private func backgroundImage(for urlString: String?) -> some View {
        if let urlStr = urlString, let url = URL(string: urlStr) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                case .success(let image):
                    GeometryReader { geo in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: geo.size.width, height: geo.size.height)
                            .clipped()
                    }
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
    
    /// Fallback for mismatch between snippet count and image count.
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
        let sampleUser = UserModel(
            email: "test@edu",
            isEmailVerified: true,
            aboutMe: "I love coding, coffee, and late-night debugging!",
            firstName: "Chase",
            lastName: "Vazquez",
            dateOfBirth: "2004-09-09",
            major: "Computer Science",
            collegeName: "CLA",
            dormType: "On-Campus",
            budgetRange: "$500-$1000",
            cleanliness: 5,
            sleepSchedule: "Flexible",
            smoker: false,
            petFriendly: true,
            interests: ["Photography", "Music", "Sports"],
            profileImageUrls: [
                "https://picsum.photos/id/1025/400/600",
                "https://picsum.photos/id/1035/400/600",
                "https://picsum.photos/id/1037/400/600"
            ],
            isVerified: true
        )
        
        return NavigationView {
            ProfilePreviewView(user: sampleUser)
        }
    }
}
