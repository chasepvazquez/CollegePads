import SwiftUI
import FirebaseAuth

struct AgreementView: View {
    @StateObject private var viewModel = AgreementViewModel()
    
    let matchID: String
    let userA: String
    let userB: String
    
    @State private var moveInDate: Date = Date()
    @State private var sharedResponsibilities: String = ""
    @State private var houseRules: String = ""
    
    enum ReviewMode: String, CaseIterable, Identifiable {
        case mutual = "Mutual"
        case anonymous = "Anonymous"
        case oneSided = "One-Sided"
        var id: String { self.rawValue }
    }
    @State private var selectedReviewMode: ReviewMode = .mutual
    
    enum VerificationMethod: String, CaseIterable, Identifiable {
        case none = "None"
        case lease = "Lease Document"
        var id: String { self.rawValue }
    }
    @State private var selectedVerificationMethod: VerificationMethod = .none
    
    @State private var leaseImage: UIImage?
    @State private var showingImagePicker = false
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient.ignoresSafeArea()
            
            NavigationView {
                Form {
                    Section(header: Text("Move-In Date")
                                .font(AppTheme.subtitleFont)) {
                        DatePicker("Select Date", selection: $moveInDate, displayedComponents: .date)
                    }
                    
                    Section(header: Text("Agreement Details")
                                .font(AppTheme.subtitleFont)) {
                        TextField("Rent Split (e.g., 50/50)", text: .constant("Determine later"))
                        TextField("Shared Responsibilities", text: $sharedResponsibilities)
                        TextEditor(text: $houseRules)
                            .frame(height: 100)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(AppTheme.secondaryColor.opacity(0.3), lineWidth: 1)
                            )
                    }
                    
                    Section(header: Text("Review Options")
                                .font(AppTheme.subtitleFont)) {
                        Picker("Review Mode", selection: $selectedReviewMode) {
                            ForEach(ReviewMode.allCases) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    Section(header: Text("Verification Method")
                                .font(AppTheme.subtitleFont)) {
                        Picker("Verification Method", selection: $selectedVerificationMethod) {
                            ForEach(VerificationMethod.allCases) { method in
                                Text(method.rawValue).tag(method)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        
                        if selectedVerificationMethod == .lease {
                            if let leaseImage = leaseImage {
                                Image(uiImage: leaseImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: 150)
                                    .onTapGesture {
                                        showingImagePicker = true
                                    }
                            } else {
                                Button("Upload Lease Document") {
                                    showingImagePicker = true
                                }
                                .buttonStyle(PrimaryButtonStyle(backgroundColor: AppTheme.accentColor))
                            }
                        }
                    }
                    
                    Section {
                        Button(action: submitAgreement) {
                            Text("Submit Agreement")
                        }
                        .buttonStyle(PrimaryButtonStyle(backgroundColor: AppTheme.primaryColor))
                    }
                }
                .scrollContentBackground(.hidden)
                .font(AppTheme.bodyFont)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("Roommate Agreement")
                            .font(AppTheme.titleFont)
                            .foregroundColor(.primary)
                    }
                }
                .navigationBarItems(trailing: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                })
                // Use CustomImagePicker instead of the old picker.
                .sheet(isPresented: $showingImagePicker) {
                    CustomImagePicker(image: $leaseImage)
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
                    Alert(title: Text("Error"),
                          message: Text(alertError.message),
                          dismissButton: .default(Text("OK")))
                }
            }
        }
    }
    
    private func submitAgreement() {
        let leaseURL = (selectedVerificationMethod == .lease) ? "https://example.com/lease.jpg" : nil
        
        let newAgreement = RoommateAgreement(
            matchID: matchID,
            userA: userA,
            userB: userB,
            moveInDate: moveInDate,
            sharedResponsibilities: sharedResponsibilities,
            houseRules: houseRules,
            reviewMode: selectedReviewMode.rawValue.lowercased(),
            verificationMethod: selectedVerificationMethod.rawValue.lowercased(),
            leaseDocumentURL: leaseURL
        )
        viewModel.saveAgreement(newAgreement) { result in
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
        AgreementView(matchID: "dummyMatchID", userA: "userA_ID", userB: "userB_ID")
    }
}
