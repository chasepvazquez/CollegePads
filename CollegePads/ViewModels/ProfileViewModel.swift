import Foundation
import FirebaseFirestore
import FirebaseAuth
import FirebaseFirestoreCombineSwift
import FirebaseStorage
import Combine

class ProfileViewModel: ObservableObject {
    @Published var userProfile: UserModel?
    @Published var errorMessage: String?
    @Published var didLoadProfile: Bool = false  // Flag to track if profile is loaded

    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()

    static let shared = ProfileViewModel()

    var userID: String? {
        Auth.auth().currentUser?.uid
    }

    /// Loads the currently authenticated user's profile from Firestore.
    func loadUserProfile(completion: ((UserModel?) -> Void)? = nil) {
        if didLoadProfile {
            print("[ProfileViewModel] loadUserProfile: Already loaded, skipping fetch.")
            completion?(userProfile)
            return
        }
        
        guard let uid = userID else {
            DispatchQueue.main.async {
                self.errorMessage = "User not authenticated"
                print("[ProfileViewModel] loadUserProfile: User not authenticated")
            }
            completion?(nil)
            return
        }
        print("[ProfileViewModel] loadUserProfile: Fetching profile for uid: \(uid)")
        db.collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    print("[ProfileViewModel] loadUserProfile error: \(error.localizedDescription)")
                }
                completion?(nil)
                return
            }
            guard let snapshot = snapshot, snapshot.exists else {
                DispatchQueue.main.async {
                    self.errorMessage = "User profile does not exist"
                    print("[ProfileViewModel] loadUserProfile: Profile does not exist")
                }
                completion?(nil)
                return
            }
            do {
                let profile = try snapshot.data(as: UserModel.self)
                DispatchQueue.main.async {
                    self.userProfile = profile
                    self.didLoadProfile = true  // Mark as loaded
                    print("[ProfileViewModel] loadUserProfile: Successfully loaded profile: \(profile)")
                }
                completion?(profile)
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    print("[ProfileViewModel] loadUserProfile: Decoding error: \(error.localizedDescription)")
                }
                completion?(nil)
            }
        }
    }

    /// Loads any user's profile by candidateID from Firestore.
    func loadUserProfile(with candidateID: String) {
        print("[ProfileViewModel] loadUserProfile(with:) for candidateID: \(candidateID)")
        db.collection("users").document(candidateID).getDocument { snapshot, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    print("[ProfileViewModel] loadUserProfile(with:) error: \(error.localizedDescription)")
                }
                return
            }
            guard let snapshot = snapshot, snapshot.exists else {
                DispatchQueue.main.async {
                    self.errorMessage = "User profile not found"
                    print("[ProfileViewModel] loadUserProfile(with:): Profile not found")
                }
                return
            }
            do {
                let profile = try snapshot.data(as: UserModel.self)
                DispatchQueue.main.async {
                    self.userProfile = profile
                    print("[ProfileViewModel] loadUserProfile(with:): Successfully loaded profile: \(profile)")
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    print("[ProfileViewModel] loadUserProfile(with:): Decoding error: \(error.localizedDescription)")
                }
            }
        }
    }

    /// Updates the current user's profile in Firestore.
    func updateUserProfile(updatedProfile: UserModel, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let uid = userID else {
            print("[ProfileViewModel] updateUserProfile: User not authenticated")
            completion(.failure(NSError(domain: "ProfileUpdate", code: 0,
                                        userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }
        print("[ProfileViewModel] updateUserProfile: Updating profile for uid: \(uid)")
        do {
            try db.collection("users").document(uid)
                .setData(from: updatedProfile, merge: true) { error in
                    if let error = error {
                        DispatchQueue.main.async {
                            print("[ProfileViewModel] updateUserProfile error: \(error.localizedDescription)")
                            completion(.failure(error))
                        }
                    } else {
                        DispatchQueue.main.async {
                            var newProfile = updatedProfile
                            newProfile.id = uid
                            self.userProfile = newProfile
                            print("[ProfileViewModel] updateUserProfile: Successfully updated profile: \(newProfile)")
                            completion(.success(()))
                        }
                    }
                }
        } catch {
            print("[ProfileViewModel] updateUserProfile: Exception caught: \(error.localizedDescription)")
            completion(.failure(error))
        }
    }

    /// Uploads a profile image to Firebase Storage.
    func uploadProfileImage(image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        guard let uid = userID,
              let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("[ProfileViewModel] uploadProfileImage: Invalid user or image data.")
            completion(.failure(NSError(domain: "UploadError", code: 0,
                                        userInfo: [NSLocalizedDescriptionKey: "Invalid user or image data."])))
            return
        }

        let storageRef = Storage.storage().reference().child("profileImages/\(uid)_\(UUID().uuidString).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        print("[ProfileViewModel] uploadProfileImage: Uploading image for uid: \(uid)")
        storageRef.putData(imageData, metadata: metadata) { _, error in
            if let error = error {
                print("[ProfileViewModel] uploadProfileImage: Error uploading image: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            storageRef.downloadURL { url, error in
                if let error = error {
                    print("[ProfileViewModel] uploadProfileImage: Error getting download URL: \(error.localizedDescription)")
                    completion(.failure(error))
                } else if let downloadURL = url?.absoluteString {
                    print("[ProfileViewModel] uploadProfileImage: Successfully uploaded image. URL: \(downloadURL)")
                    completion(.success(downloadURL))
                }
            }
        }
    }

    /// NEW: Uploads a property media file (image, floorplan, or document) to Firebase Storage.
    func uploadPropertyMedia(image: UIImage, folder: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let uid = userID,
              let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("[ProfileViewModel] uploadPropertyMedia: Invalid user or image data.")
            completion(.failure(NSError(domain: "UploadError", code: 0,
                                        userInfo: [NSLocalizedDescriptionKey: "Invalid user or image data."])))
            return
        }

        let storageRef = Storage.storage().reference().child("\(folder)/\(uid)_\(UUID().uuidString).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        print("[ProfileViewModel] uploadPropertyMedia: Uploading media to folder \(folder) for uid: \(uid)")
        storageRef.putData(imageData, metadata: metadata) { _, error in
            if let error = error {
                print("[ProfileViewModel] uploadPropertyMedia: Error uploading media: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            storageRef.downloadURL { url, error in
                if let error = error {
                    print("[ProfileViewModel] uploadPropertyMedia: Error getting download URL: \(error.localizedDescription)")
                    completion(.failure(error))
                } else if let downloadURL = url?.absoluteString {
                    print("[ProfileViewModel] uploadPropertyMedia: Successfully uploaded media. URL: \(downloadURL)")
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
            print("[ProfileViewModel] removeBlockedUser: Removed blocked user with uid: \(uid)")
        }
    }

    /// Helper to create a default user profile if none exists.
    private func defaultUserProfile() -> UserModel {
        let user = UserModel(
            email: Auth.auth().currentUser?.email ?? "unknown@unknown.com",
            isEmailVerified: false,
            aboutMe: nil,
            firstName: nil,
            lastName: nil,
            dateOfBirth: nil,
            gender: nil,
            height: nil,
            gradeLevel: nil,
            major: nil,
            collegeName: nil,
            dormType: nil,
            preferredDorm: nil,
            budgetRange: nil,
            cleanliness: nil,
            sleepSchedule: nil,
            smoker: nil,
            petFriendly: nil,
            livingStyle: nil,
            socialLevel: nil,
            studyHabits: nil,
            interests: nil,
            profileImageUrl: nil,
            profileImageUrls: nil,
            location: nil,
            isVerified: false,
            blockedUserIDs: nil,
            housingStatus: nil,
            leaseDuration: nil,
            desiredLeaseHousingType: nil,
            roommateCountNeeded: 0,
            roommateCountExisting: 0,
            filterSettings: nil,
            createdAt: nil,
            pets: nil,
            drinking: nil,
            smoking: nil,
            cannabis: nil,
            workout: nil,
            dietaryPreferences: nil,
            socialMedia: nil,
            sleepingHabits: nil,
            goingOutQuizAnswers: nil,
            weekendQuizAnswers: nil,
            phoneQuizAnswers: nil,
            propertyDetails: nil,
            propertyImageUrls: nil,
            floorplanUrls: nil,
            documentUrls: nil
        )
        var mutableUser = user
        mutableUser.id = Auth.auth().currentUser?.uid
        return mutableUser
    }
}
