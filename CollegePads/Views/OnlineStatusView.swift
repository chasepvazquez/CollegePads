//
//  OnlineStatusView.swift
//  CollegePads
//
//  New Feature: Online Status Indicator
//  This view listens to a user's online status from Firestore using FirebaseFirestoreCombineSwift.
//  It displays a green circle with "Online" if the user is online, or a gray circle with "Offline" if not.
//  The user document in Firestore must include a Boolean field "isOnline".
//

import SwiftUI
import FirebaseFirestore
import FirebaseFirestoreCombineSwift
import Combine

struct OnlineStatusView: View {
    let userID: String
    
    @State private var isOnline: Bool = false
    @State private var errorMessage: String?
    
    private var db = Firestore.firestore()
    @State private var cancellables = Set<AnyCancellable>()
    
    // Explicit initializer to ensure the default memberwise initializer is accessible.
    init(userID: String) {
        self.userID = userID
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isOnline ? Color.green : Color.gray)
                .frame(width: 10, height: 10)
            Text(isOnline ? "Online" : "Offline")
                .font(.caption)
                .foregroundColor(.primary)
        }
        .onAppear {
            observeOnlineStatus()
        }
    }
    
    private func observeOnlineStatus() {
        db.collection("users").document(userID)
            .snapshotPublisher()
            .sink { completion in
                if case let .failure(error) = completion {
                    errorMessage = error.localizedDescription
                }
            } receiveValue: { snapshot in
                if let data = snapshot.data(), let online = data["isOnline"] as? Bool {
                    isOnline = online
                }
            }
            .store(in: &cancellables)
    }
}

struct OnlineStatusView_Previews: PreviewProvider {
    static var previews: some View {
        OnlineStatusView(userID: "dummyUserID")
    }
}
