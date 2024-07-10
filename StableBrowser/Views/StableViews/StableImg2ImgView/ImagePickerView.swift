import SwiftUI

struct ImagePickerView: View {
    var parent: StableImg2ImgView
    @State internal var isImagePickerPresented = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary

    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: {
                    sourceType = .photoLibrary
                    isImagePickerPresented = true
                }, label: {
                    VStack(spacing: 5) {
                        Image(systemName: "photo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                            .foregroundColor(.accentColor)
                        Text("Library")
                    }
                })
                .frame(maxWidth: 100, maxHeight: .infinity)
                .background(Color.white.opacity(0.9))
                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                .cornerRadius(10)
                .padding(.vertical, 10)
                .padding(.trailing, 5)
                
                Button(action: {
                    sourceType = .camera
                    isImagePickerPresented = true
                }, label: {
                    VStack(spacing: 5) {
                        Image(systemName: "camera")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                            .foregroundColor(.accentColor)
                        Text("Camera")
                    }
                })
                .frame(maxWidth: 100, maxHeight: .infinity)
                .background(Color.white.opacity(0.9))
                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                .cornerRadius(10)
                .padding(.vertical, 10)
                .padding(.leading, 5)
                Spacer()
            }
            .sheet(isPresented: $isImagePickerPresented) {
                ImagePicker(parent: self, sourceType: $sourceType)
            }
            Spacer()
            Button(action: {
                withAnimation {
                    parent.uploadImagePopupVisible = false
                }
            }, label: {
                Text("Cancel")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding()
                    .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
            })
            .frame(maxWidth: .infinity, maxHeight: 30)
        }
        .background(Color.clear)    
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    var parent: ImagePickerView
    @Binding var sourceType: UIImagePickerController.SourceType
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> UIImagePickerController {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = sourceType
        imagePicker.delegate = context.coordinator
        return imagePicker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<ImagePicker>) {
        
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                withAnimation {
                    self.parent.parent.parent.uploadImagePopupVisible = false
                    self.parent.parent.parent.importBaseImage(baseImage: image)
                }
                
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
