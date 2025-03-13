//
//  FirebaseAuthService.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreCombineSwift // Enables setData(from:) and @DocumentID

class FirebaseAuthService {
    
    private let db = Firestore.firestore()
    
    /// Signs up a user with an .edu email address, sends a verification email,
    /// and creates a user document in Firestore if successful.
    /// - Parameters:
    ///   - email: The email entered by the user
    ///   - password: The password
    ///   - completion: Escaping closure that returns a result: success or error
    func signUpWithEmail(
        email: String,
        password: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        // 1. Check domain is .edu (basic client-side check)
        guard isEduEmail(email) else {
            let domainError = NSError(
                domain: "EmailDomainCheck",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "Please use a valid .edu email address."]
            )
            completion(.failure(domainError))
            return
        }
        
        // 2. Create user in FirebaseAuth
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] authResult, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let user = authResult?.user else {
                let nilUserError = NSError(
                    domain: "AuthResult",
                    code: 0,
                    userInfo: [NSLocalizedDescriptionKey: "User not found after sign-up."]
                )
                completion(.failure(nilUserError))
                return
            }
            
            // 3. Send verification email
            user.sendEmailVerification { verificationError in
                if let verificationError = verificationError {
                    completion(.failure(verificationError))
                    return
                }
                
                // 4. Create user doc in Firestore
                self?.createUserDocument(for: user) { firestoreResult in
                    switch firestoreResult {
                    case .success:
                        completion(.success(()))
                    case .failure(let err):
                        completion(.failure(err))
                    }
                }
            }
        }
    }
    
    /// Checks if a given email ends with ".edu".
    private func isEduEmail(_ email: String) -> Bool {
        // Basic check: ensure the domain ends with ".edu"
        guard let domain = email.split(separator: "@").last else { return false }
        return domain.hasSuffix(".edu")
    }
    
    /// Creates a corresponding user document in Firestore using Firestore's Swift/Combine features.
    /// - Parameter user: The `Auth.auth().currentUser`
    private func createUserDocument(for user: User, completion: @escaping (Result<Void, Error>) -> Void) {
        // Construct a new UserModel
        let userModel = UserModel(
            email: user.email ?? "",
            isEmailVerified: user.isEmailVerified
        )
        
        // Use Firestore's setData(from:) to automatically encode userModel
        do {
            try db.collection("users")
                .document(user.uid) // doc name = auth user's UID
                .setData(from: userModel) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(()))
                    }
                }
        } catch {
            // setData(from:) can throw if encoding fails
            completion(.failure(error))
        }
    }
}
