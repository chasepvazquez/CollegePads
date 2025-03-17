//
//  FavoriteService.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//

import FirebaseFirestore
import FirebaseAuth

class FavoriteService {
    private let db = Firestore.firestore()
    
    func addFavorite(candidate: UserModel, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid, let candidateID = candidate.id else {
            completion(.failure(NSError(domain: "FavoriteService", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not authenticated or candidate ID missing."])))
            return
        }
        let data: [String: Any] = [
            "userID": uid,
            "candidateID": candidateID,
            "timestamp": FieldValue.serverTimestamp()
        ]
        // Document ID is formatted as "userID_candidateID"
        db.collection("favorites").document("\(uid)_\(candidateID)").setData(data) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func removeFavorite(candidate: UserModel, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid, let candidateID = candidate.id else {
            completion(.failure(NSError(domain: "FavoriteService", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not authenticated or candidate ID missing."])))
            return
        }
        db.collection("favorites").document("\(uid)_\(candidateID)").delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func isFavorite(candidate: UserModel, completion: @escaping (Bool) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid, let candidateID = candidate.id else {
            completion(false)
            return
        }
        db.collection("favorites").document("\(uid)_\(candidateID)").getDocument { snapshot, error in
            if let snapshot = snapshot, snapshot.exists {
                completion(true)
            } else {
                completion(false)
            }
        }
    }
    
    func loadFavorites(completion: @escaping (Result<[UserModel], Error>) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "FavoriteService", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not authenticated."])))
            return
        }
        db.collection("favorites").whereField("userID", isEqualTo: uid).getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
            } else {
                var favoriteIDs: [String] = []
                snapshot?.documents.forEach { doc in
                    if let candidateID = doc.data()["candidateID"] as? String {
                        favoriteIDs.append(candidateID)
                    }
                }
                if favoriteIDs.isEmpty {
                    completion(.success([]))
                } else {
                    self.db.collection("users").whereField(FieldPath.documentID(), in: favoriteIDs).getDocuments { snapshot, error in
                        if let error = error {
                            completion(.failure(error))
                        } else {
                            let candidates = snapshot?.documents.compactMap { doc -> UserModel? in
                                try? doc.data(as: UserModel.self)
                            } ?? []
                            completion(.success(candidates))
                        }
                    }
                }
            }
        }
    }
}
