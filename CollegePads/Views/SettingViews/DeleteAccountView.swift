import SwiftUI

struct DeleteAccountView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showConfirmation: Bool = false
    @State private var isDeleting: Bool = false
    @State private var deletionError: String?
    
    var body: some View {
        ZStack {
            // Global background gradient.
            AppTheme.backgroundGradient.ignoresSafeArea()
            
            // Remove inner NavigationView; assume this view is embedded in a navigation container.
            Form {
                Section(header: Text("Warning")
                            .font(AppTheme.subtitleFont)) {
                    Text("Deleting your account is irreversible. All your data will be permanently removed. This action cannot be undone.")
                        .font(AppTheme.bodyFont)
                        .foregroundColor(.red)
                }
                
                Section {
                    if isDeleting {
                        ProgressView("Deleting account...")
                            .font(AppTheme.bodyFont)
                    } else {
                        Button("Delete Account") {
                            showConfirmation = true
                        }
                        .font(AppTheme.bodyFont)
                        .foregroundColor(.red)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .font(AppTheme.bodyFont)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Delete Account")
                        .font(AppTheme.titleFont)
                        .foregroundColor(.primary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .font(AppTheme.bodyFont)
                    .foregroundColor(.primary)
                }
            }
            .alert(isPresented: $showConfirmation) {
                Alert(title: Text("Confirm Deletion"),
                      message: Text("Are you sure you want to delete your account? This action cannot be undone."),
                      primaryButton: .destructive(Text("Delete")) {
                        deleteAccount()
                      },
                      secondaryButton: .cancel())
            }
            .alert(item: Binding(get: {
                deletionError.map { GenericAlertError(message: $0) }
            }, set: { _ in deletionError = nil })) { alertError in
                Alert(title: Text("Error"), message: Text(alertError.message), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    private func deleteAccount() {
        isDeleting = true
        authViewModel.deleteAccount { result in
            DispatchQueue.main.async {
                isDeleting = false
                switch result {
                case .success:
                    presentationMode.wrappedValue.dismiss()
                case .failure(let error):
                    deletionError = error.localizedDescription
                }
            }
        }
    }
}

struct DeleteAccountView_Previews: PreviewProvider {
    static var previews: some View {
        DeleteAccountView().environmentObject(AuthViewModel())
    }
}
