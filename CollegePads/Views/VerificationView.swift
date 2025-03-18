//
//  VerificationView.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//

import SwiftUI

struct VerificationView: View {
    @StateObject private var viewModel = VerificationViewModel()
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
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
                    } else {
                        Button("Select Verification Image") {
                            showingImagePicker = true
                        }
                    }
                }
                
                Section {
                    Button(action: submitVerification) {
                        Text("Submit Verification")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
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
        viewModel.submitVerification(image: image) { result in
            switch result {
            case .success:
                presentationMode.wrappedValue.dismiss()
            case .failure(let error):
                print("Verification submission failed: \(error.localizedDescription)")
            }
        }
    }
}

struct VerificationView_Previews: PreviewProvider {
    static var previews: some View {
        VerificationView()
    }
}
