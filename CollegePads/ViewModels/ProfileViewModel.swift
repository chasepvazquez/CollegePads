import Foundation
import FirebaseFirestore
import FirebaseAuth
import FirebaseFirestoreCombineSwift
import FirebaseStorage
import Combine

class ProfileViewModel: ObservableObject {
    @Published var userProfile: UserModel?
    @Published var errorMessage: String?

    private let db = Firestore.firestore()
    private var authListener: AuthStateDidChangeListenerHandle?
    private var profileListenerCancellables = Set<AnyCancellable>()

    static let shared = ProfileViewModel()

    var userID: String? {
        Auth.auth().currentUser?.uid
    }

    private init() {
        authListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            
            guard let uid = user?.uid else {
                DispatchQueue.main.async {
                    self.userProfile = nil
                    self.errorMessage = nil
                }
                return
            }
            
            // live-update our profile as it changes in Firestore
            // cancel *only* the profile snapshot listener:
            self.profileListenerCancellables
                .forEach { $0.cancel() }
            self.profileListenerCancellables.removeAll()
            // live-update profile
            self.db
                .collection("users")
                .document(uid)
                .snapshotPublisher()
                .tryMap { snapshot in
                    try snapshot.data(as: UserModel.self)
                }
                .receive(on: DispatchQueue.main)
                .sink { [weak self] completion in
                    if case let .failure(err) = completion {
                        self?.errorMessage = err.localizedDescription
                    }
                } receiveValue: { [weak self] profile in
                    self?.userProfile = profile
                }
                .store(in: &self.profileListenerCancellables)
        }
    }
        deinit {
            if let handle = authListener {
                Auth.auth().removeStateDidChangeListener(handle)
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

    /// Uploads a property media file (image, floorplan, or document) to Firebase Storage.
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
            // 2. Personal Info
            aboutMe: nil,
            firstName: nil,
            lastName: nil,
            dateOfBirth: nil,
            gender: nil,
            height: nil,
            // 3. Academic Info
            gradeLevel: nil,
            major: nil,
            collegeName: nil,
            // 4. Housing & Lease Info
            housingStatus: nil,
            desiredLeaseHousingType: nil,
            roommateCountNeeded: 0,
            roommateCountExisting: 0,
            // 5. Property Details
            propertyDetails: nil,
            propertyAddress: nil, // NEW
            propertyImageUrls: nil,
            floorplanUrls: nil,
            documentUrls: nil,
            // 6. Room Type Selector
            roomType: nil,
            // 7. Lease & Pricing Details
            leaseStartDate: nil,
            leaseDuration: nil,
            monthlyRentMin: nil,
            monthlyRentMax: nil,
            specialLeaseConditions: nil,
            // 8. Amenities Multi-Select Field
            amenities: nil,
            // 9. Additional Housing Fields
            budgetMin: nil,
            budgetMax: nil,
            cleanliness: nil,
            sleepSchedule: nil,
            smoker: nil,
            petFriendly: nil,
            livingStyle: nil,
            // 10. Interests
            socialLevel: nil,
            studyHabits: nil,
            interests: nil,
            // 11. Media & Location
            profileImageUrl: nil,
            profileImageUrls: nil,
            location: nil,
            // 12. Verification
            isVerified: false,
            // 13. Blocked Users
            blockedUserIDs: nil,
            // 14. Advanced Filter Settings
            filterSettings: nil,
            // 15. Lifestyle Fields
            pets: nil,
            drinking: nil,
            smoking: nil,
            cannabis: nil,
            workout: nil,
            dietaryPreferences: nil,
            socialMedia: nil,
            sleepingHabits: nil,
            // 16. Quiz Answers
            goingOutQuizAnswers: nil,
            weekendQuizAnswers: nil,
            phoneQuizAnswers: nil
        )
        var mutableUser = user
        mutableUser.id = Auth.auth().currentUser?.uid
        return mutableUser
    }
}
