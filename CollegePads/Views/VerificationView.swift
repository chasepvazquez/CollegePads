//
//  VerificationView.swift
//  CollegePads
//
//  Updated to add a loading indicator during verification submission and improved form states
//

import SwiftUI

struct VerificationView: View {
    @StateObject private var viewModel = VerificationViewModel()
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var isSubmitting: Bool = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Upload Verification Document")) {
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 200)
                            .onTapGesture {
                                showingImagePicker = true
                            }
                            .accessibilityLabel("Selected Verification Image")
                    } else {
                        Button("Select Verification Image") {
                            showingImagePicker = true
                        }
                        .accessibilityLabel("Select Verification Image Button")
                    }
                }
                
                Section {
                    Button(action: submitVerification) {
                        if isSubmitting {
                            ProgressView()
                        } else {
                            Text("Submit Verification")
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                    .disabled(selectedImage == nil || isSubmitting)
                }
            }
            .navigationTitle("User Verification")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedImage)
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
    
    private func submitVerification() {
        guard let image = selectedImage else { return }
        isSubmitting = true
        viewModel.submitVerification(image: image) { result in
            DispatchQueue.main.async {
                isSubmitting = false
                switch result {
                case .success:
                    presentationMode.wrappedValue.dismiss()
                case .failure(let error):
                    print("Verification submission failed: \(error.localizedDescription)")
                }
            }
        }
    }
}

struct VerificationView_Previews: PreviewProvider {
    static var previews: some View {
        VerificationView()
    }
}
