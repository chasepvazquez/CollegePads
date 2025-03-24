import SwiftUI
import FirebaseFirestore
import FirebaseFirestoreCombineSwift
import Combine

struct OnlineStatusView: View {
    let userID: String
    
    @State private var isOnline: Bool = false
    @State private var errorMessage: String?
    
    private var db = Firestore.firestore()
    @State private var cancellables = Set<AnyCancellable>()
    
    // Explicit initializer.
    init(userID: String) {
        self.userID = userID
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isOnline ? Color.green : Color.gray)
                .frame(width: 10, height: 10)
            Text(isOnline ? "Online" : "Offline")
                .font(AppTheme.bodyFont)
                .foregroundColor(.primary)
        }
        .onAppear {
            observeOnlineStatus()
        }
    }
    
    private func observeOnlineStatus() {
        db.collection("users").document(userID)
            .snapshotPublisher()
            .sink { completion in
                if case let .failure(error) = completion {
                    errorMessage = error.localizedDescription
                }
            } receiveValue: { snapshot in
                if let data = snapshot.data(), let online = data["isOnline"] as? Bool {
                    isOnline = online
                }
            }
            .store(in: &cancellables)
    }
}

struct OnlineStatusView_Previews: PreviewProvider {
    static var previews: some View {
        OnlineStatusView(userID: "dummyUserID")
    }
}
