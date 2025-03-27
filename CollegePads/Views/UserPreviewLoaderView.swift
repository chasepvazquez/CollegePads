import SwiftUI

struct UserPreviewLoaderView: View {
    let candidateID: String
    @StateObject private var viewModel = ProfileViewModel()
    
    var body: some View {
        Group {
            if let user = viewModel.userProfile {
                ProfilePreviewView(user: user)
            } else if let error = viewModel.errorMessage {
                Text("Error: \(error)")
                    .font(AppTheme.bodyFont)
            } else {
                ProgressView("Loading profile...")
                    .font(AppTheme.bodyFont)
            }
        }
        .onAppear {
            viewModel.loadUserProfile(with: candidateID)
        }
    }
}

struct UserPreviewLoaderView_Previews: PreviewProvider {
    static var previews: some View {
        UserPreviewLoaderView(candidateID: "dummyID")
    }
}
