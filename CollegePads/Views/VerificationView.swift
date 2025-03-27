import SwiftUI
import PhotosUI
import FirebaseAuth

struct VerificationView: View {
    @StateObject private var viewModel = VerificationViewModel()
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var isSubmitting: Bool = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Upload Verification Document")
                            .font(AppTheme.subtitleFont)) {
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
                        .font(AppTheme.bodyFont)
                        .accessibilityLabel("Select Verification Image Button")
                    }
                }
                
                Section {
                    Button(action: submitVerification) {
                        if isSubmitting {
                            ProgressView()
                        } else {
                            Text("Submit Verification")
                                .font(AppTheme.bodyFont)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                    .disabled(selectedImage == nil || isSubmitting)
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.backgroundGradient.ignoresSafeArea())
            .navigationTitle("User Verification")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
            // Use CustomImagePicker instead of the old picker.
            .sheet(isPresented: $showingImagePicker) {
                CustomImagePicker(image: $selectedImage)
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
