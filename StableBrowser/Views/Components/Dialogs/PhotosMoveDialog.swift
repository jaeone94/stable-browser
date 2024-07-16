import SwiftUI

struct PhotosMoveDialog: View {
    var parent: AlbumView
    var photos: [OpenPhoto]
    var currentAlbum: Album
    
    @State private var selectedAlbum: String
    @State private var photoManagementService = PhotoManagementService.shared
    
    init(parent: AlbumView, photos: [OpenPhoto], currentAlbum: Album) {
        self.parent = parent
        self.photos = photos
        self.currentAlbum = currentAlbum
        // Initialize selectedAlbum with a default valid value
        _selectedAlbum = State(initialValue: PhotoManagementService.shared.albums.filter { $0.name != currentAlbum.name }.first?.name ?? "")
    }
    
    var body: some View {
        VStack {
            let albums = photoManagementService.albums.filter { $0.name != currentAlbum.name }
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(color: Color(.black).opacity(0.2), radius: 8, x: 0, y: 2)
                
                VStack {
                    Text("Move Images")
                        .font(.title)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 10) {
                        ForEach(photos.prefix(4), id: \.id) { photo in
                            Image(uiImage: photo.thumbNail)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 50, height: 50)
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                        }
                        if photos.count > 4 {
                            Text("+\(photos.count - 4)")
                                .frame(width: 50, height: 50)
                                .background(Color.gray.opacity(0.3))
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                        }
                    }
                    .frame(height: 60)
                    
                    
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
                            movePhotos()
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
            }
            .frame(width: 350, height: 300)
            Spacer()
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
    
    @MainActor private func movePhotos() {
        let selectedAlbum = self.selectedAlbum.isEmpty ? photoManagementService.albums.filter { $0.name != currentAlbum.name }.first?.name : self.selectedAlbum
        if let destinationAlbum = photoManagementService.albums.first(where: { $0.name == selectedAlbum }) {
            for photo in photos {
                if let securePhoto = currentAlbum.photos.first(where: { $0.id == photo.id }) {
                    photoManagementService.movePhotoToAlbum(photo: securePhoto, fromAlbum: currentAlbum, toAlbum: destinationAlbum)
                    withAnimation {
                        parent.imageViewModel.selectedPhotos.removeAll { $0.id == photo.id }
                    }
                }
            }
            withAnimation {
                parent.showPhotoMoveDialog = false
                parent.isSelectionMode = false
                parent.selectedPhotos.removeAll()
            }
        }
    }
}
