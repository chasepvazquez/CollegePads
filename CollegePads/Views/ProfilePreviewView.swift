import SwiftUI

/// A unified preview that merges CandidateProfileView features into the original swipeable layout.
/// - Displays user images in a TabView (horizontal swipe) with minimal preview snippets.
/// - Shows a top-right overlay with a shield icon (Report/Block) and a checkmark if verified.
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
    
    // A minimal set of snippet pairs to display across slides.
    private var infoSnippets: [[String]] {
        let ageString = (calculateAge(from: user.dateOfBirth).map { "\($0)" }) ?? "?"
        let about = (user.aboutMe?.isEmpty == false) ? user.aboutMe! : nil
        let interests = (user.interests?.isEmpty == false) ? user.interests!.joined(separator: ", ") : nil
        
        var snippets: [[String]] = []
        
        // Slide 1: Name + Age.
        if let fn = user.firstName, let ln = user.lastName, !fn.isEmpty, !ln.isEmpty {
            snippets.append(["\(fn) \(ln)", "Age: \(ageString)"])
        } else {
            snippets.append(["Age: \(ageString)"])
        }
        
        // Slide 2: Major + College.
        if let major = user.major, !major.isEmpty,
           let college = user.collegeName, !college.isEmpty {
            snippets.append(["Major: \(major)", "College: \(college)"])
        } else if let major = user.major, !major.isEmpty {
            snippets.append(["Major: \(major)"])
        } else if let college = user.collegeName, !college.isEmpty {
            snippets.append(["College: \(college)"])
        }
        
        // Slide 3: Dorm + Budget.
        if let dorm = user.dormType, !dorm.isEmpty,
           let budget = user.budgetRange, !budget.isEmpty {
            snippets.append(["Dorm Type: \(dorm)", "Budget: \(budget)"])
        } else if let dorm = user.dormType, !dorm.isEmpty {
            snippets.append(["Dorm Type: \(dorm)"])
        } else if let budget = user.budgetRange, !budget.isEmpty {
            snippets.append(["Budget: \(budget)"])
        }
        
        // Slide 4: Cleanliness + Sleep.
        if let cleanliness = user.cleanliness,
           let schedule = user.sleepSchedule, !schedule.isEmpty {
            snippets.append(["Cleanliness: \(cleanliness)/5", "Sleep: \(schedule)"])
        } else if let cleanliness = user.cleanliness {
            snippets.append(["Cleanliness: \(cleanliness)/5"])
        } else if let schedule = user.sleepSchedule, !schedule.isEmpty {
            snippets.append(["Sleep: \(schedule)"])
        }
        
        // Slide 5: Smoker + Pets.
        if let smoker = user.smoker,
           let pet = user.petFriendly {
            snippets.append(["Smoker: \(smoker ? "Yes" : "No")", "Pets: \(pet ? "Yes" : "No")"])
        } else if let smoker = user.smoker {
            snippets.append(["Smoker: \(smoker ? "Yes" : "No")"])
        } else if let pet = user.petFriendly {
            snippets.append(["Pets: \(pet ? "Yes" : "No")"])
        }
        
        // Slide 6: About Me.
        if let about = about, !about.isEmpty {
            snippets.append(["About Me:", about])
        }
        
        // Slide 7: Interests.
        if let interests = interests, !interests.isEmpty {
            snippets.append(["Interests:", interests])
        }
        
        return snippets
    }
    
    // The number of slides is the minimum of the number of images and snippet groups.
    private var slideCount: Int {
        let imageCount = user.profileImageUrls?.count ?? 0
        return min(imageCount, infoSnippets.count)
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            if let images = user.profileImageUrls, !images.isEmpty {
                if slideCount > 0 {
                    TabView(selection: $currentIndex) {
                        ForEach(0..<slideCount) { idx in
                            // Single slide with image + snippet overlay.
                            ZStack(alignment: .bottomLeading) {
                                // Background image.
                                if let urlString = images[safe: idx],
                                   let url = URL(string: urlString) {
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
                                
                                // Text overlay for snippet.
                                VStack(alignment: .leading, spacing: 6) {
                                    ForEach(infoSnippets[idx], id: \.self) { line in
                                        Text(line)
                                            .font(AppTheme.bodyFont)
                                            .lineLimit(2)
                                    }
                                }
                                .padding()
                                .foregroundColor(.white)
                                .shadow(radius: 5)
                            }
                            .tag(idx)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                    .aspectRatio(cardAspectRatio, contentMode: .fit)
                    .cornerRadius(15)
                    .shadow(radius: 5)
                    .padding()
                } else {
                    fallbackImageTabView(images: images)
                }
            } else {
                Text("No images to preview")
                    .font(AppTheme.bodyFont)
                    .foregroundColor(.gray)
            }
            
            // Top-right overlay: Verification check + shield icon.
            topRightOverlay
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
}

extension ProfilePreviewView {
    private func fallbackImageTabView(images: [String]) -> some View {
        TabView {
            ForEach(0..<images.count) { index in
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
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
        .aspectRatio(cardAspectRatio, contentMode: .fit)
        .cornerRadius(15)
        .shadow(radius: 5)
        .padding()
    }
    
    private var topRightOverlay: some View {
        HStack(spacing: 10) {
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
        .padding()
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
            firstName: "Taylor",
            lastName: "Johnson",
            dateOfBirth: "1999-08-12",
            major: "Computer Science",
            collegeName: "Engineering",
            dormType: "On-Campus",
            budgetRange: "$500-$1000",
            cleanliness: 4,
            sleepSchedule: "Flexible",
            smoker: false,
            petFriendly: true,
            interests: ["Gaming", "Movies", "Hiking"],
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
