//
//  RoommateRatingView.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//

import SwiftUI

struct RoommateRatingView: View {
    let ratedUserID: String  // The user being rated
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = RoommateRatingViewModel()
    
    @State private var rating: Int = 3  // Default rating
    @State private var review: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Rate Your Roommate")) {
                    // Simple star rating using a segmented control.
                    Picker("Rating", selection: $rating) {
                        ForEach(1...5, id: \.self) { star in
                            Text("\(star)★").tag(star)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("Review (Optional)")) {
                    TextEditor(text: $review)
                        .frame(height: 120)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3), lineWidth: 1))
                }
                
                Section {
                    Button(action: submitRating) {
                        Text("Submit Rating")
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                }
            }
            .navigationTitle("Rate Roommate")
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
    
    private func submitRating() {
        viewModel.submitRating(rating: rating, review: review, ratedUserID: ratedUserID) { result in
            switch result {
            case .success:
                presentationMode.wrappedValue.dismiss()
            case .failure(let error):
                print("Rating submission failed: \(error.localizedDescription)")
            }
        }
    }
}

struct RoommateRatingView_Previews: PreviewProvider {
    static var previews: some View {
        // Replace "dummyUserID" with a valid UID for preview purposes.
        RoommateRatingView(ratedUserID: "dummyUserID")
    }
}
