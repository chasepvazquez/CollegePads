//
//  BlockedUsersView.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//

import SwiftUI

struct BlockedUsersView: View {
    // Access current user's blockedUserIDs via ProfileViewModel.shared
    @ObservedObject var profileVM = ProfileViewModel.shared
    @StateObject private var blockUserVM = BlockUserViewModel()
    
    var body: some View {
        NavigationView {
            List {
                if let blocked = profileVM.userProfile?.blockedUserIDs, !blocked.isEmpty {
                    ForEach(blocked, id: \.self) { uid in
                        HStack {
                            Text(uid) // In production, replace with a user lookup for name/photo.
                                .font(.body)
                            Spacer()
                            Button(action: {
                                blockUserVM.unblockUser(candidateID: uid) { result in
                                    switch result {
                                    case .success:
                                        // Update the local profile model if needed.
                                        profileVM.removeBlockedUser(with: uid)
                                    case .failure(let error):
                                        print("Unblock error: \(error.localizedDescription)")
                                    }
                                }
                            }) {
                                Text("Unblock")
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } else {
                    Text("No blocked users.")
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("Blocked Users")
            .navigationBarItems(trailing: Button("Done") {
                // Dismiss view if presented modally.
            })
        }
    }
}

struct BlockedUsersView_Previews: PreviewProvider {
    static var previews: some View {
        BlockedUsersView()
    }
}
