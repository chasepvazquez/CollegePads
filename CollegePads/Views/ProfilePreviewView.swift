import SwiftUI

/// Displays the user's images in a swipeable, Tinder-like layout for preview.
struct ProfilePreviewView: View {
    let user: UserModel
    
    // Tracks the current image index for a page-based swipe.
    @State private var currentIndex: Int = 0
    
    // Approximate Tinder ratio (3:4 or 4:5). Adjust as needed.
    private let cardAspectRatio: CGFloat = 0.75
    
    var body: some View {
        ZStack {
            if let images = user.profileImageUrls, !images.isEmpty {
                // Use a TabView for horizontal swipe
                TabView(selection: $currentIndex) {
                    ForEach(Array(images.enumerated()), id: \.offset) { (idx, urlString) in
                        ZStack(alignment: .bottomLeading) {
                            if let url = URL(string: urlString) {
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
                            
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    if let fn = user.firstName, let ln = user.lastName {
                                        Text("\(fn) \(ln)")
                                            .font(.largeTitle).bold()
                                    }
                                    if let age = calculateAge(from: user.dateOfBirth) {
                                        Text("\(age)")
                                            .font(.largeTitle).bold()
                                    }
                                }
                                if let major = user.major, !major.isEmpty {
                                    Text(major)
                                        .font(AppTheme.bodyFont)
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
                // Constrain the entire preview to a Tinder-like aspect ratio
                .aspectRatio(cardAspectRatio, contentMode: .fit)
                .cornerRadius(15)
                .shadow(radius: 5)
                .padding()
            } else {
                Text("No images to preview")
                    .font(AppTheme.bodyFont)
                    .foregroundColor(.gray)
            }
        }
    }
    
    /// Helper to calculate age from "YYYY-MM-DD"
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
