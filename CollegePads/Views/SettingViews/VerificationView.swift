import SwiftUI
import FirebaseAuth

struct VerificationView: View {
    @StateObject private var viewModel = VerificationViewModel()
    @State private var isSubmitting: Bool = false
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            Form {
                // MARK: - Email Verification Section
                Section(header: Text("Email Verification")
                            .font(AppTheme.subtitleFont)) {
                    if let currentUser = Auth.auth().currentUser, currentUser.isEmailVerified {
                        Text("Your email is verified!")
                            .foregroundColor(.green)
                    } else {
                        Button("Send Verification Email") {
                            isSubmitting = true
                            viewModel.sendEmailVerification { result in
                                DispatchQueue.main.async {
                                    isSubmitting = false
                                    switch result {
                                    case .success:
                                        print("Verification email sent.")
                                    case .failure(let error):
                                        print("Failed to send email verification: \(error.localizedDescription)")
                                    }
                                }
                            }
                        }
                        .font(AppTheme.bodyFont)
                        .accessibilityLabel("Send Verification Email Button")
                        
                        Button("Refresh Verification Status") {
                            viewModel.refreshVerificationStatus { result in
                                DispatchQueue.main.async {
                                    switch result {
                                    case .success:
                                        print("Firestore updated to verified.")
                                    case .failure(let error):
                                        print("Failed to update Firestore: \(error.localizedDescription)")
                                    }
                                }
                            }
                        }
                        .font(AppTheme.bodyFont)
                        .padding(.top, 8)
                    }
                }
                
                // MARK: - Submission Section
                Section {
                    Button(action: submitVerification) {
                        if isSubmitting {
                            ProgressView()
                        } else {
                            Text("Done")
                                .font(AppTheme.bodyFont)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                    // Enable button if the current user is verified.
                    .disabled(!(Auth.auth().currentUser?.isEmailVerified ?? false) || isSubmitting)
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.backgroundGradient.ignoresSafeArea())
            .navigationTitle("User Verification")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
            .alert(item: Binding(
                get: {
                    if let errorMessage = viewModel.errorMessage {
                        return GenericAlertError(message: errorMessage)
                    }
                    return nil
                },
                set: { _ in viewModel.errorMessage = nil }
            )) { alertError in
                Alert(title: Text("Error"),
                      message: Text(alertError.message),
                      dismissButton: .default(Text("OK")))
            }
        }
    }
    
    private func submitVerification() {
        // If the user is verified, dismiss the view.
        if let currentUser = Auth.auth().currentUser, currentUser.isEmailVerified {
            presentationMode.wrappedValue.dismiss()
        }
    }
}

struct VerificationView_Previews: PreviewProvider {
    static var previews: some View {
        VerificationView()
    }
}
