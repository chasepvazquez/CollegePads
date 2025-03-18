//
//  ProfileViewModel.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//
//  This ViewModel manages the current user's profile data. It loads and updates the user profile from Firestore,
//  including all extended fields such as gradeLevel, housingStatus, leaseDuration, and blockedUserIDs.
//  It also provides a helper method to remove a blocked user from the local profile.

import Foundation
import FirebaseFirestore
import FirebaseAuth
import FirebaseFirestoreCombineSwift
import Combine

class ProfileViewModel: ObservableObject {
    @Published var userProfile: UserModel?
    @Published var errorMessage: String?
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    
    /// Shared instance for global access.
    static let shared = ProfileViewModel()
    
    /// Returns the current user's UID.
    var userID: String? {
        Auth.auth().currentUser?.uid
    }
    
    /// Loads the current user's profile from Firestore.
    func loadUserProfile() {
        guard let uid = userID else {
            self.errorMessage = "User not authenticated"
            return
        }
        db.collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                self.errorMessage = error.localizedDescription
                return
            }
            guard let snapshot = snapshot, snapshot.exists else {
                self.errorMessage = "User profile does not exist"
                return
            }
            do {
                let profile = try snapshot.data(as: UserModel.self)
                DispatchQueue.main.async {
                    self.userProfile = profile
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    /// Updates the current user's profile in Firestore.
    /// - Parameters:
    ///   - updatedProfile: The updated UserModel (including all extended fields such as housingStatus and leaseDuration).
    ///   - completion: A completion handler with a Result indicating success or failure.
    func updateUserProfile(updatedProfile: UserModel, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let uid = userID else {
            completion(.failure(NSError(domain: "ProfileUpdate", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }
        do {
            try db.collection("users").document(uid).setData(from: updatedProfile) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    DispatchQueue.main.async {
                        self.userProfile = updatedProfile
                    }
                    completion(.success(()))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    /// Removes a blocked user from the current user's local profile.
    /// - Parameter uid: The UID of the user to remove from the blocked list.
    func removeBlockedUser(with uid: String) {
        if var blocked = userProfile?.blockedUserIDs {
            blocked.removeAll { $0 == uid }
            userProfile?.blockedUserIDs = blocked
        }
    }
}
