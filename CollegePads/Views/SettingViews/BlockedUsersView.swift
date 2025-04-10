import SwiftUI

struct BlockedUsersView: View {
    // Access current user's blockedUserIDs via ProfileViewModel.shared
    @ObservedObject var profileVM = ProfileViewModel.shared
    @StateObject private var blockUserVM = BlockUserViewModel()
    
    var body: some View {
        ZStack {
            // Global background from your theme.
            AppTheme.backgroundGradient.ignoresSafeArea()
            
            // Removed inner NavigationView so the background shows correctly.
            List {
                if let blocked = profileVM.userProfile?.blockedUserIDs, !blocked.isEmpty {
                    ForEach(blocked, id: \.self) { uid in
                        HStack {
                            Text(uid) // Replace with user lookup for name/photo in production.
                                .font(AppTheme.bodyFont)
                            Spacer()
                            Button(action: {
                                blockUserVM.unblockUser(candidateID: uid) { result in
                                    switch result {
                                    case .success:
                                        profileVM.removeBlockedUser(with: uid)
                                    case .failure(let error):
                                        print("Unblock error: \(error.localizedDescription)")
                                    }
                                }
                            }) {
                                Text("Unblock")
                                    .font(AppTheme.bodyFont)
                                    .foregroundColor(AppTheme.accentColor)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } else {
                    Text("No blocked users.")
                        .font(AppTheme.bodyFont)
                        .foregroundColor(AppTheme.secondaryColor)
                }
            }
            .scrollContentBackground(.hidden)
            .listStyle(PlainListStyle())
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Blocked Users")
                        .font(AppTheme.titleFont)
                        .foregroundColor(.primary)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        // Dismiss view if presented modally.
                    }
                }
            }
        }
    }
}

struct BlockedUsersView_Previews: PreviewProvider {
    static var previews: some View {
        BlockedUsersView()
    }
}
