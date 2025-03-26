import SwiftUI
import FirebaseAuth
import FirebaseFirestore

class AuthViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    @Published var userSession: FirebaseAuth.User? = nil
    
    init() {
        self.userSession = Auth.auth().currentUser
    }
    
    /// Starts listening for auth state changes.
    func listenToAuthState() {
        _ = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.userSession = user
        }
    }
    
    func signUp() {
        errorMessage = nil
        isLoading = true
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] authResult, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }
                guard let uid = Auth.auth().currentUser?.uid else {
                    self?.errorMessage = "User ID not available."
                    return
                }
                // Store additional user data in Firestore.
                let userData: [String: Any] = [
                    "email": self?.email ?? "",
                    "createdAt": FieldValue.serverTimestamp()
                    // You can add other default fields as needed.
                ]
                Firestore.firestore().collection("users").document(uid).setData(userData, merge: true) { error in
                    if let error = error {
                        DispatchQueue.main.async {
                            self?.errorMessage = error.localizedDescription
                        }
                    } else {
                        DispatchQueue.main.async {
                            self?.userSession = Auth.auth().currentUser
                        }
                    }
                }
            }
        }
    }
    
    func signIn() {
        errorMessage = nil
        isLoading = true
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }
                self?.userSession = authResult?.user
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            userSession = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Account Management Extension

extension AuthViewModel {
    func deleteAccount(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(.failure(NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "No authenticated user found."])))
            return
        }
        user.delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}
