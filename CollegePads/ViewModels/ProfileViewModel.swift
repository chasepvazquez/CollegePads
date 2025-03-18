//
//  ProfileViewModel.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//
//  This ViewModel manages the current user's profile data, including extended fields
//  such as housingStatus and leaseDuration. It also provides a helper to remove blocked users.
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
    
    static let shared = ProfileViewModel()
    
    var userID: String? {
        Auth.auth().currentUser?.uid
    }
    
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
    
    func removeBlockedUser(with uid: String) {
        if var blocked = userProfile?.blockedUserIDs {
            blocked.removeAll { $0 == uid }
            userProfile?.blockedUserIDs = blocked
        }
    }
}
