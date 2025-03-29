import SwiftUI
import PhotosUI
import os.log

struct CustomImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    /// Optional callback to signal completion of image picking.
    var onComplete: (() -> Void)? = nil

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        os_log("CustomImagePicker: Created PHPickerViewController.")
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
        // No updates needed.
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: CustomImagePicker

        init(_ parent: CustomImagePicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            os_log("CustomImagePicker: didFinishPicking with %d result(s).", results.count)
            // Dismiss the picker
            picker.dismiss(animated: true) {
                os_log("CustomImagePicker: Picker dismissed.")
            }

            guard let result = results.first else {
                os_log("CustomImagePicker: No image selected.")
                DispatchQueue.main.async {
                    self.parent.image = nil
                    self.parent.onComplete?()
                }
                return
            }

            let provider = result.itemProvider
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { object, error in
                    DispatchQueue.main.async {
                        if let uiImage = object as? UIImage {
                            os_log("CustomImagePicker: Image loaded successfully.")
                            self.parent.image = uiImage
                        } else {
                            os_log("CustomImagePicker: Failed to load image: %@", error?.localizedDescription ?? "Unknown error")
                            self.parent.image = nil
                        }
                        self.parent.onComplete?()
                    }
                }
            } else {
                os_log("CustomImagePicker: Provider cannot load UIImage.")
                DispatchQueue.main.async {
                    self.parent.image = nil
                    self.parent.onComplete?()
                }
            }
        }
    }
}
