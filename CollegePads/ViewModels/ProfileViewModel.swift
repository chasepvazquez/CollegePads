import Foundation
import FirebaseFirestore
import FirebaseAuth
import FirebaseFirestoreCombineSwift
import FirebaseStorage
import Combine

class ProfileViewModel: ObservableObject {
    @Published var userProfile: UserModel?
    @Published var errorMessage: String?
    
    // Flag to suspend updates while modals (e.g., image picker or report view) are active.
    var suspendUpdates = false

    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    
    static let shared = ProfileViewModel()
    
    var userID: String? {
        Auth.auth().currentUser?.uid
    }
    
    /// Loads the currently authenticated user's profile from Firestore.
    func loadUserProfile(completion: ((UserModel?) -> Void)? = nil) {
        guard let uid = userID else {
            self.errorMessage = "User not authenticated"
            completion?(nil)
            return
        }
        db.collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                }
                completion?(nil)
                return
            }
            guard let snapshot = snapshot, snapshot.exists else {
                DispatchQueue.main.async {
                    self.errorMessage = "User profile does not exist"
                }
                completion?(nil)
                return
            }
            do {
                let profile = try snapshot.data(as: UserModel.self)
                DispatchQueue.main.async {
                    if !self.suspendUpdates {
                        self.userProfile = profile
                    }
                }
                completion?(profile)
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                }
                completion?(nil)
            }
        }
    }
    
    /// Loads any user's profile by candidateID from Firestore.
    func loadUserProfile(with candidateID: String) {
        db.collection("users").document(candidateID).getDocument { snapshot, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                }
                return
            }
            guard let snapshot = snapshot, snapshot.exists else {
                DispatchQueue.main.async {
                    self.errorMessage = "User profile not found"
                }
                return
            }
            do {
                let profile = try snapshot.data(as: UserModel.self)
                DispatchQueue.main.async {
                    if !self.suspendUpdates {
                        self.userProfile = profile
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    /// Updates the current user's profile in Firestore.
    func updateUserProfile(updatedProfile: UserModel, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let uid = userID else {
            completion(.failure(NSError(domain: "ProfileUpdate", code: 0,
                                        userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }
        do {
            try db.collection("users").document(uid).setData(from: updatedProfile) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    DispatchQueue.main.async {
                        var newProfile = updatedProfile
                        // Explicitly assign the uid as the profile's id.
                        newProfile.id = uid
                        if !self.suspendUpdates {
                            self.userProfile = newProfile
                        }
                    }
                    completion(.success(()))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    /// Uploads a profile image to Firebase Storage.
    func uploadProfileImage(image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        guard let uid = userID,
              let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(NSError(domain: "UploadError", code: 0,
                                        userInfo: [NSLocalizedDescriptionKey: "Invalid user or image data."])))
            return
        }
        
        let storageRef = Storage.storage().reference().child("profileImages/\(uid)_\(UUID().uuidString).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        storageRef.putData(imageData, metadata: metadata) { _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            storageRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                } else if let downloadURL = url?.absoluteString {
                    completion(.success(downloadURL))
                }
            }
        }
    }
    
    /// Removes a blocked user ID from the profile (in memory).
    func removeBlockedUser(with uid: String) {
        if var blocked = userProfile?.blockedUserIDs {
            blocked.removeAll { $0 == uid }
            userProfile?.blockedUserIDs = blocked
        }
    }
    
    /// Helper to create a default user profile if none exists.
    private func defaultUserProfile() -> UserModel {
        var user = UserModel(
            email: Auth.auth().currentUser?.email ?? "unknown@unknown.com",
            isEmailVerified: false
        )
        user.id = Auth.auth().currentUser?.uid
        return user
    }
}
