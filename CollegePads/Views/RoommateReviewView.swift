import SwiftUI
import PhotosUI
import FirebaseAuth

struct RoommateReviewView: View {
    let matchID: String      // Provided by match context
    let ratedUserID: String  // UID of the user being reviewed
    
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = RoommateReviewViewModel()
    
    // Review form fields
    @State private var rating: Int = 3
    @State private var reviewText: String = ""
    
    // Review mode selection
    enum ReviewMode: String, CaseIterable, Identifiable {
        case mutual = "Mutual"
        case anonymous = "Anonymous"
        case oneSided = "One-Sided"
        var id: String { self.rawValue }
    }
    @State private var selectedReviewMode: ReviewMode = .mutual
    
    // Verification method selection
    enum VerificationMethod: String, CaseIterable, Identifiable {
        case none = "None"
        case lease = "Lease Upload"
        var id: String { self.rawValue }
    }
    @State private var selectedVerificationMethod: VerificationMethod = .none
    
    // Lease document image (if needed)
    @State private var leaseImage: UIImage?
    @State private var showingImagePicker: Bool = false
    
    // Alert binding
    private var alertBinding: Binding<GenericAlertError?> {
        Binding<GenericAlertError?>(
            get: {
                if let error = viewModel.errorMessage {
                    return GenericAlertError(message: error)
                }
                return nil
            },
            set: { _ in viewModel.errorMessage = nil }
        )
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Rating")
                            .font(AppTheme.subtitleFont)) {
                    Picker("Rating", selection: $rating) {
                        ForEach(1...5, id: \.self) { star in
                            Text("\(star)★").tag(star)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("Review")
                            .font(AppTheme.subtitleFont)) {
                    TextEditor(text: $reviewText)
                        .frame(height: 100)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.defaultCornerRadius)
                                .stroke(AppTheme.secondaryColor.opacity(0.3), lineWidth: 1)
                        )
                }
                
                Section(header: Text("Review Mode")
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
                                .onTapGesture { showingImagePicker = true }
                        } else {
                            Button("Upload Lease Document") {
                                showingImagePicker = true
                            }
                            .buttonStyle(PrimaryButtonStyle(backgroundColor: AppTheme.accentColor))
                        }
                    }
                }
                
                Section {
                    Button(action: submitReview) {
                        Text("Submit Review")
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(AppTheme.primaryColor)
                            .cornerRadius(AppTheme.defaultCornerRadius)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Review Roommate")
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
            // Use CustomImagePicker instead of the old picker.
            .sheet(isPresented: $showingImagePicker) {
                CustomImagePicker(image: $leaseImage)
            }
            .alert(item: alertBinding) { alertError in
                Alert(title: Text("Error"), message: Text(alertError.message), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    private func submitReview() {
        // For demonstration, use a dummy lease URL if lease option is chosen.
        let leaseDocumentURL: String? = (selectedVerificationMethod == .lease) ? "https://example.com/lease.jpg" : nil
        
        viewModel.submitReview(matchID: matchID,
                               ratedUserID: ratedUserID,
                               rating: rating,
                               reviewText: reviewText,
                               reviewMode: selectedReviewMode.rawValue.lowercased(),
                               verificationMethod: selectedVerificationMethod.rawValue.lowercased(),
                               leaseDocumentURL: leaseDocumentURL) { result in
            switch result {
            case .success:
                presentationMode.wrappedValue.dismiss()
            case .failure(let error):
                print("Review submission failed: \(error.localizedDescription)")
            }
        }
    }
}

struct RoommateReviewView_Previews: PreviewProvider {
    static var previews: some View {
        RoommateReviewView(matchID: "dummyMatchID", ratedUserID: "dummyRatedUserID")
    }
}
