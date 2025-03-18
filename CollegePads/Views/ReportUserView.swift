//
//  ReportUserView.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//

import SwiftUI

struct ReportUserView: View {
    @StateObject private var viewModel = SafetyViewModel()
    let reportedUserID: String  // Pass the UID of the user being reported
    
    @State private var reason: String = ""
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Report User")) {
                    Text("Please provide a brief explanation of why you are reporting this user.")
                        .font(.subheadline)
                    TextEditor(text: $reason)
                        .frame(height: 120)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3), lineWidth: 1))
                }
                
                Section {
                    Button(action: submitReport) {
                        Text("Submit Report")
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red)
                            .cornerRadius(8)
                    }
                    .disabled(reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle("Report User")
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
                Alert(title: Text("Error"), message: Text(alertError.message), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    private func submitReport() {
        viewModel.reportUser(reportedUserID: reportedUserID, reason: reason) { result in
            switch result {
            case .success:
                presentationMode.wrappedValue.dismiss()
            case .failure(let error):
                print("Report submission failed: \(error.localizedDescription)")
            }
        }
    }
}

struct ReportUserView_Previews: PreviewProvider {
    static var previews: some View {
        // Replace "dummyUserID" with a valid UID for preview purposes.
        ReportUserView(reportedUserID: "dummyUserID")
    }
}
