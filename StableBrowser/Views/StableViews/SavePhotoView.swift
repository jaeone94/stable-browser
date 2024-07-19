import SwiftUI
import RealmSwift

struct SavePhotoView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var title: String = "GeneratedPicture_\(formattedCurrentDateTime())"
    @State private var selectedAlbumIndex: Int = 0
    @State private var albums: [Album] = []
    @State private var toggleReDraw: Bool = false
    @State private var showingAlert = false
    @State private var alertType: AlertType = .saved
    @State private var isSaveWithSourceImage = false
    
    @StateObject private var imageViewModel = ImageViewModel.shared
    @StateObject private var photoManagementService = PhotoManagementService.shared
    
    enum AlertType {
        case saved, failed
    }
    
    var image: UIImage
    var sourceImage: UIImage
    var additionalInfo: [String: Any]
    
    var strAdditionalInfo: String {
        if additionalInfo.isEmpty {
            return ""
        }
        var str = ""
        let keys = ["prompt", "negative_prompt", "sd_model_name", "sampler_name", "clip_skip", "steps", "cfg_scale", "denoising_strength", "seed", "subseed", "subseed_strength", "width", "height", "sd_vae_name", "restore_faces"]
        for key in keys {
            // Check if the key exists in the dictionary
            if let value = additionalInfo[key] {
                // Add the key-value pair to the string
                str += "\"\(key)\": \"\(value)\""
                if key != keys.last {
                    str += ", "
                }
            }
        }
        return str
    }
    
    
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack {
                    HStack(spacing:0) {
                        VStack(spacing:0) {
                            Spacer()
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .padding(5)
                            Spacer()
                            Text("Preview").font(.caption).padding(.bottom, 10)
                                .foregroundColor(.secondary)
                        }
                        .frame(width: geometry.size.width / 4, height: 140)
                        .background(Color.black.opacity(0.1))
                        .cornerRadius(3)
                        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                        
                        
                        .padding(.trailing)
                        VStack(spacing:0) {
                            HStack{
                                Text("Picture name").font(.callout).padding(.leading, 3)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding(.vertical, 7)
                            TextField("Picture name", text: $title)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .multilineTextAlignment(.leading)
                                .lineLimit(1)
                                .frame(maxWidth: .infinity)
                            HStack{
                                Text("Save path").font(.callout)
                                    .padding(.leading, 3)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }.padding(.vertical, 7)
                            Picker("Select an Album", selection: $selectedAlbumIndex) {
                                ForEach(0..<albums.count, id: \.self) { index in
                                    Text(self.albums[index].name).tag(index)
                                }                                
                                Text("Create new Album").tag(albums.count)
                            
                            }
                            .frame(maxWidth: .infinity)
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(3)
                            .pickerStyle(MenuPickerStyle())
                        }
                    }.frame(height: 150)
                    
                    VStack(spacing:10) {
                        HStack{
                            Text("Generation info")
                                .font(.callout)
                                .padding(.leading, 5)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        VStack {
                            HStack {
                                Text(strAdditionalInfo)
                                    .font(.subheadline)
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(100)
                                
                                Spacer()
                            }.padding(10)
                            Spacer()
                        }.frame(maxWidth: .infinity)
                            .frame(maxHeight: .infinity)
                            .contentShape(Rectangle())
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(7)
                            .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                    .padding(.bottom, 10)
                    
                    if sourceImage.size.width != 0 {
                        Button(action: {
                            isSaveWithSourceImage.toggle()
                        }) {
                            HStack {
                                Image(systemName: isSaveWithSourceImage ? "checkmark.square.fill" : "square")
                                    .font(.title2)
                                    .foregroundColor(.primary)
                                Text("Save with source image")
                                    .font(.title2)
                                    .foregroundColor(.primary)
                            }
                        }
                        .padding(.bottom, 10)
                    }

                    
                    Button(action: {
                        if selectedAlbumIndex == albums.count {
                            savePhotoWithCreatingAlbum()
                        }else {
                            savePhoto { success in
                                if success {
                                    Toast.shared.present(
                                        title: "Image successfully saved",
                                        symbol: "photo.badge.checkmark.fill",
                                        isUserInteractionEnabled: true,
                                        timing: .medium,
                                        padding: 140
                                    )
                                    presentationMode.wrappedValue.dismiss()
                                } else {
                                    alertType = .failed
                                    showingAlert = true
                                }
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                                .font(.title2)
                            Text("Add to gallery")
                                .font(.title2)
                        }
                    }
                    .padding(.vertical, 15)
                    .padding(.horizontal, 15)
                    .frame(maxWidth:.infinity)
                    .background(Color.primary)
                    .foregroundColor(Color(UIColor.systemBackground))
                    .cornerRadius(7)
                    .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                }
                .padding(.vertical, 15)
                .padding(.bottom, 15)
                .padding(.horizontal, 15)
            }.id(toggleReDraw)
        }
        .background(Color(UIColor.secondarySystemBackground))
        .alert(isPresented: $showingAlert) {
            return Alert(title: Text("Failed"), message: Text("Failed to save your photo"), dismissButton: .default(Text("OK")))
        }
        .onAppear {
            loadAlbums()
        }
    }
    
    private func loadAlbums() {
        albums = photoManagementService.albums
        
        if albums.isEmpty {
            selectedAlbumIndex = 0
            return
        }
        
        if let lastSavedAlbumId = imageViewModel.lastSavedAlbumId,
           let index = albums.firstIndex(where: { $0.id == lastSavedAlbumId }) {
            selectedAlbumIndex = index
        } else {
            selectedAlbumIndex = 0
        }
    }
    
    @MainActor private func savePhotoWithCreatingAlbum() {
        if let originalPhotoData = image.pngData(),
           let thumbnailPhotoData = image.resized(withPercentage: 0.8)?.jpegData(compressionQuality: 0.5) {
            
            var sourcePhotoData: Data? = nil
            if isSaveWithSourceImage {
                sourcePhotoData = sourceImage.pngData()
            }
            
            let securePhoto = SecurePhoto(name: title, photoData: originalPhotoData, thumbnailData: thumbnailPhotoData, metadata: additionalInfo, sourcePhotoData: sourcePhotoData)
            photoManagementService.addPhotoToNewAlbum(photo: securePhoto)
                                
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    
    @MainActor private func savePhoto(completion: @escaping (Bool) -> Void) {
        guard let originalPhotoData = image.pngData() else {
            completion(false)
            return
        }
        
        let maxBytes = 16 * 1024 * 1024
        let currentBytes = originalPhotoData.count
        var finalPhotoData = originalPhotoData
        if currentBytes > maxBytes {
            let percentage = calculateResizePercentage(currentPixels: currentBytes/4, maxBytes: maxBytes)
            guard let resizedImage = image.resized(withPercentage: percentage),
                  let resizedPhotoData = resizedImage.pngData() else {
                completion(false)
                return
            }
            finalPhotoData = resizedPhotoData
        }
        
        guard let thumbnailPhotoData = image.resized(withPercentage: 0.8)?.jpegData(compressionQuality: 0.5) else {
            completion(false)
            return
        }

        var sourcePhotoData: Data? = nil
        if isSaveWithSourceImage {
            let resizedSourceImage = sourceImage.resizeTargetImageToMatchSource(src: image)
            if let originalSourcePhotoData = resizedSourceImage.pngData() {
                let currentBytes = originalSourcePhotoData.count
                if currentBytes > maxBytes {
                    let percentage = calculateResizePercentage(currentPixels: currentBytes/4, maxBytes: maxBytes)
                    guard let doubleResizedImage = resizedSourceImage.resized(withPercentage: percentage),
                          let doubleResizedPhotoData = doubleResizedImage.pngData() else {
                        completion(false)
                        return
                    }
                    sourcePhotoData = doubleResizedPhotoData
                }else {
                    sourcePhotoData = originalSourcePhotoData
                }
            }
        }
        
        let securePhoto = SecurePhoto(name: title, photoData: finalPhotoData, thumbnailData: thumbnailPhotoData, metadata: additionalInfo, sourcePhotoData: sourcePhotoData)
                let album = albums[selectedAlbumIndex]
                
        photoManagementService.addPhotoToAlbum(album: album, photo: securePhoto) { success in
            if success {
                imageViewModel.updateLastSavedAlbum(album)
            }
            completion(success)
        }
    }
    
    // Helper function to calculate the resize percentage
    private func calculateResizePercentage(currentPixels: Int, maxBytes: Int) -> CGFloat {
        let bytesPerPixel = 4
        let currentBytes = currentPixels * bytesPerPixel
        let percentage = CGFloat(sqrt(Double(maxBytes) / Double(currentBytes)))
        return percentage < 1 ? percentage : 1
    }
}

func formattedCurrentDateTime() -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMddyyyy_HHmmss"
    return formatter.string(from: Date())
}



