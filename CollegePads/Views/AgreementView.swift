//
//  AgreementView.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//

import SwiftUI

struct AgreementView: View {
    @StateObject private var viewModel = AgreementViewModel()
    // Assume these values are passed from the match/chat context
    let matchID: String
    let userA: String
    let userB: String
    
    @State private var moveInDate: Date = Date()
    @State private var sharedResponsibilities: String = ""
    @State private var houseRules: String = ""
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Move-In Date")) {
                    DatePicker("Select Date", selection: $moveInDate, displayedComponents: .date)
                }
                
                Section(header: Text("Shared Responsibilities")) {
                    TextEditor(text: $sharedResponsibilities)
                        .frame(height: 100)
                }
                
                Section(header: Text("House Rules")) {
                    TextEditor(text: $houseRules)
                        .frame(height: 100)
                }
                
                Section {
                    Button(action: saveAgreement) {
                        Text("Save Agreement")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationTitle("Roommate Agreement")
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
    
    private func saveAgreement() {
        let agreement = RoommateAgreement(matchID: matchID, userA: userA, userB: userB, moveInDate: moveInDate, sharedResponsibilities: sharedResponsibilities, houseRules: houseRules)
        viewModel.saveAgreement(agreement) { result in
            switch result {
            case .success:
                presentationMode.wrappedValue.dismiss()
            case .failure(let error):
                print("Error saving agreement: \(error.localizedDescription)")
            }
        }
    }
}

struct AgreementView_Previews: PreviewProvider {
    static var previews: some View {
        // Dummy data for preview – replace with actual match/user IDs
        AgreementView(matchID: "dummyMatchID", userA: "userA_ID", userB: "userB_ID")
    }
}
