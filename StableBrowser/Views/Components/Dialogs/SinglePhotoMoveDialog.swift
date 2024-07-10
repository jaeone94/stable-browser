import SwiftUI
struct SinglePhotoMoveDialog: View {
    var parent: AlbumView
    var photo: OpenPhoto
    var currentAlbum: Album
    
    @State private var selectedAlbum = ""
    @State private var photoManagementService = PhotoManagementService.shared
    
    var body: some View {
        VStack {
            let uiImage = photo.image
            // 현재 앨범은 제외            
            let albums = photoManagementService.albums.filter { $0.name != currentAlbum.name }
            Spacer()
            HStack {
                Spacer()
                VStack {
                    Text("Move Image")
                        .font(.title)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 100)
                        .cornerRadius(10)
                    
                    
                    HStack(alignment: .center, spacing: 12) {
                        Text("Move to...")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .padding(.leading, 3)
                        
                        Picker("", selection: $selectedAlbum) {
                            ForEach(albums, id: \.self) { album in
                                Text(album.name).tag(album.name)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    .padding()
                    Divider()
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            withAnimation {
                                parent.showPhotoMoveDialog = false
                            }
                        }) {
                            Text("Cancel")
                                .fontWeight(.medium)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 25)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: {
                            movePhoto()
                        }) {
                            Text("Move")
                                .fontWeight(.semibold)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 25)
                                .background(Color.primary)
                                .foregroundColor(Color(UIColor.systemBackground))
                                .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .frame(width: 350, height: 300)
                .cornerRadius(15)
                .shadow(color: Color(.black).opacity(0.2), radius: 8, x: 0, y: 2)
                Spacer()
            }
            .background(Color.clear)
            .padding()
            Spacer()
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
    
    @MainActor private func movePhoto() {
        let selectedAlbum = self.selectedAlbum.isEmpty ? photoManagementService.albums.filter { $0.name != currentAlbum.name }.first?.name : self.selectedAlbum
        if let destinationAlbum = photoManagementService.albums.first(where: { $0.name == selectedAlbum }) {
            let securePhoto = currentAlbum.photos.first(where: { $0.id == photo.id })!
            photoManagementService.movePhotoToAlbum(photo: securePhoto, fromAlbum: currentAlbum, toAlbum: destinationAlbum)
            parent.imageViewModel.selectedPhotos.removeAll { $0.id == photo.id }
            withAnimation {
                parent.showPhotoMoveDialog = false
            }
        }
    }
}
