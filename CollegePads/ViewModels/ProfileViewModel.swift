import Foundation
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestoreCombineSwift
import Combine

/// ViewModel that manages the user profile data stored in Firestore.
/// It supports new fields: firstName, lastName, dateOfBirth, and gender.
class ProfileViewModel: ObservableObject {
    @Published var userProfile: UserModel?
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    
    static let shared = ProfileViewModel()
    
    var userID: String? {
        Auth.auth().currentUser?.uid
    }
    
    /// Loads the user profile from Firestore and updates userProfile in state.
    /// If a completion is provided, it is called with the loaded profile (or nil on error).
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
                    self.userProfile = profile
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
    
    /// Updates the user profile in Firestore. Writes all fields, including new ones:
    /// firstName, lastName, dateOfBirth, gender, etc.
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
    
    /// Uploads a profile image to Firebase Storage, returning a download URL on success.
    func uploadProfileImage(image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        guard let uid = userID,
              let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(NSError(domain: "UploadError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid user or image data."])))
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
    
    /// Removes a blocked user ID from the user profile in memory (does not persist automatically).
    func removeBlockedUser(with uid: String) {
        if var blocked = userProfile?.blockedUserIDs {
            blocked.removeAll { $0 == uid }
            userProfile?.blockedUserIDs = blocked
        }
    }
}
