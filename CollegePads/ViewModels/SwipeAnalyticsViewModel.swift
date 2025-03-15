//
//  SwipeAnalyticsViewModel.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreCombineSwift
import FirebaseAuth
import Combine

class SwipeAnalyticsViewModel: ObservableObject {
    @Published var totalRightSwipes: Int = 0
    @Published var totalLeftSwipes: Int = 0
    @Published var totalMutualMatches: Int = 0
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    private let db = Firestore.firestore()
    
    var currentUserID: String? {
        Auth.auth().currentUser?.uid
    }
    
    func loadSwipeAnalytics() {
        guard let uid = currentUserID else {
            errorMessage = "User not authenticated"
            return
        }
        
        // Count right swipes
        db.collection("swipes")
            .whereField("from", isEqualTo: uid)
            .whereField("liked", isEqualTo: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                self.totalRightSwipes = snapshot?.documents.count ?? 0
            }
        
        // Count left swipes
        db.collection("swipes")
            .whereField("from", isEqualTo: uid)
            .whereField("liked", isEqualTo: false)
            .getDocuments { snapshot, error in
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                self.totalLeftSwipes = snapshot?.documents.count ?? 0
            }
        
        // Count mutual matches via chats (where current user is a participant)
        db.collection("chats")
            .whereField("participants", arrayContains: uid)
            .getDocuments { snapshot, error in
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                self.totalMutualMatches = snapshot?.documents.count ?? 0
            }
    }
}
