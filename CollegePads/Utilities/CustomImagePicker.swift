import SwiftUI
import PhotosUI

struct CustomImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        print("CustomImagePicker: Created PHPickerViewController.")
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
        // No update needed.
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
            print("CustomImagePicker: didFinishPicking with \(results.count) result(s).")
            picker.dismiss(animated: true) {
                print("CustomImagePicker: Picker dismissed.")
            }
            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else {
                print("CustomImagePicker: No valid image provider.")
                return
            }
            provider.loadObject(ofClass: UIImage.self) { image, error in
                DispatchQueue.main.async {
                    if let uiImage = image as? UIImage {
                        print("CustomImagePicker: Image loaded successfully.")
                        self.parent.image = uiImage
                    } else {
                        print("CustomImagePicker: Failed to load image: \(error?.localizedDescription ?? "Unknown error")")
                    }
                }
            }
        }
    }
}
