//
//  DeleteAccountView.swift
//  CollegePads
//
//  New Feature: Account Deletion
//  This view allows the user to delete their account after confirmation.
//  It calls AuthViewModel.deleteAccount() and provides success/error feedback.
//

import SwiftUI

struct DeleteAccountView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showConfirmation: Bool = false
    @State private var isDeleting: Bool = false
    @State private var deletionError: String?
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Warning")) {
                    Text("Deleting your account is irreversible. All your data will be permanently removed. This action cannot be undone.")
                        .foregroundColor(.red)
                }
                
                Section {
                    if isDeleting {
                        ProgressView("Deleting account...")
                    } else {
                        Button("Delete Account") {
                            showConfirmation = true
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Delete Account")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
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
    
    /// Calls the deleteAccount method from AuthViewModel and handles the result.
    private func deleteAccount() {
        isDeleting = true
        authViewModel.deleteAccount { result in
            DispatchQueue.main.async {
                isDeleting = false
                switch result {
                case .success:
                    // Optionally, perform additional cleanup or navigate to login.
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
