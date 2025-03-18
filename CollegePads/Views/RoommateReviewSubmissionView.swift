//
//  RoommateReviewSubmissionView.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//

import SwiftUI

struct RoommateReviewSubmissionView: View {
    let matchID: String        // Provided by the match context
    let ratedUserID: String    // UID of the person being reviewed
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
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Rating")) {
                    Picker("Rating", selection: $rating) {
                        ForEach(1...5, id: \.self) { star in
                            Text("\(star) ★").tag(star)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("Review")) {
                    TextEditor(text: $reviewText)
                        .frame(height: 100)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3), lineWidth: 1))
                }
                
                Section(header: Text("Review Mode")) {
                    Picker("Review Mode", selection: $selectedReviewMode) {
                        ForEach(ReviewMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("Verification Method")) {
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
                        }
                    }
                }
                
                Section {
                    Button(action: submitReview) {
                        Text("Submit Review")
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                }
            }
            .navigationTitle("Review Roommate")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $leaseImage)
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
    
    private func submitReview() {
        // In a real app, if the selected verification method is lease,
        // you would first upload the leaseImage using your FirebaseStorageService extension.
        // For simplicity, we'll assume that if a lease is required, you have a leaseDocumentURL.
        // Replace the following line with your upload logic if needed.
        let leaseDocumentURL: String? = (selectedVerificationMethod == .lease) ? "https://example.com/lease.jpg" : nil
        
        viewModel.submitReview(matchID: matchID,
                               ratedID: ratedUserID,
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

struct RoommateReviewSubmissionView_Previews: PreviewProvider {
    static var previews: some View {
        // Replace "dummyMatchID" and "dummyRatedUserID" with sample data.
        RoommateReviewSubmissionView(matchID: "dummyMatchID", ratedUserID: "dummyRatedUserID")
    }
}
