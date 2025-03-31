import Foundation
import FirebaseFirestore
import FirebaseFirestoreCombineSwift
import FirebaseAuth
import Combine

struct MatchItem: Identifiable, Codable {
    let id: String
    let participants: [String]
    let createdAt: Date
}

class MatchesDashboardViewModel: ObservableObject {
    @Published var matches: [MatchItem] = []
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    private let db = Firestore.firestore()
    
    var currentUserID: String? {
        Auth.auth().currentUser?.uid
    }
    
    func loadMatches() {
        guard let uid = currentUserID else {
            self.errorMessage = "User not authenticated."
            return
        }
        
        db.collection("matches")
            .whereField("participants", arrayContains: uid)
            .snapshotPublisher()
            .map { snapshot -> [MatchItem] in
                snapshot.documents.compactMap { doc in
                    let data = doc.data()
                    guard let participants = data["participants"] as? [String],
                          let timestamp = (data["createdAt"] as? Timestamp)?.dateValue() else {
                        return nil
                    }
                    return MatchItem(id: doc.documentID, participants: participants, createdAt: timestamp)
                }
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] matches in
                self?.matches = matches
            }
            .store(in: &cancellables)
    }
}
