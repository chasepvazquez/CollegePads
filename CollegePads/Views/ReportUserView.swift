import SwiftUI

struct ReportUserView: View {
    @StateObject private var viewModel = SafetyViewModel()
    let reportedUserID: String  // UID of the user being reported
    
    @State private var reason: String = ""
    @State private var isSubmitting: Bool = false
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Report User")
                            .font(AppTheme.subtitleFont)) {
                    Text("Please provide a brief explanation of why you are reporting this user.")
                        .font(AppTheme.bodyFont)
                    TextEditor(text: $reason)
                        .frame(height: 120)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.defaultCornerRadius)
                                .stroke(AppTheme.secondaryColor.opacity(0.3), lineWidth: 1)
                        )
                        .accessibilityLabel("Report Reason Editor")
                }
                
                Section {
                    Button(action: submitReport) {
                        if isSubmitting {
                            ProgressView()
                        } else {
                            Text("Submit Report")
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(AppTheme.accentColor)
                                .cornerRadius(AppTheme.defaultCornerRadius)
                        }
                    }
                    .disabled(reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
                    .accessibilityLabel("Submit Report Button")
                }
            }
            .scrollContentBackground(.hidden)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Report User")
                        .font(AppTheme.titleFont)
                        .foregroundColor(.primary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .font(AppTheme.bodyFont)
                }
            }
            .alert(item: Binding(
                get: {
                    if let errorMessage = viewModel.errorMessage {
                        return GenericAlertError(message: errorMessage)
                    }
                    return nil
                },
                set: { _ in viewModel.errorMessage = nil }
            )) { alertError in
                Alert(title: Text("Error"), message: Text(alertError.message), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    private func submitReport() {
        isSubmitting = true
        viewModel.reportUser(reportedUserID: reportedUserID, reason: reason) { result in
            DispatchQueue.main.async {
                isSubmitting = false
                switch result {
                case .success:
                    presentationMode.wrappedValue.dismiss()
                case .failure(let error):
                    print("Report submission failed: \(error.localizedDescription)")
                }
            }
        }
    }
}

struct ReportUserView_Previews: PreviewProvider {
    static var previews: some View {
        ReportUserView(reportedUserID: "dummyUserID")
    }
}
