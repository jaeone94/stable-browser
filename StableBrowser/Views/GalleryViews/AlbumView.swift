import SwiftUI
import RealmSwift

struct AlbumView: View {
    var parent: GalleryView
    let album: Album
    @StateObject var imageViewModel = ImageViewModel.shared
    @State var selectedPhoto: OpenPhoto?
    @State var showPhotoMoveDialog: Bool = false
    @State var showActionSheet: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let isLandscape = width > geometry.size.height
            let itemCount = isLandscape ? 5 : 3
            let spacing: CGFloat = 1
            let totalSpacing = spacing * CGFloat(itemCount - 1)
            let itemWidth = (width - totalSpacing) / CGFloat(itemCount)
            let selectedPhotos = imageViewModel.selectedPhotos
            
            ZStack {
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: spacing), count: itemCount), spacing: spacing) {
                        ForEach(selectedPhotos) { photo in
                            GeometryReader { geometry in
                                ZStack(alignment: .topTrailing) {
                                    Button(action: {
                                        parent.currentIndex = selectedPhotos.firstIndex(of: photo) ?? 0
                                        withAnimation {
                                            parent.showImageViewer = true
                                        }
                                    }) {
                                        Image(uiImage: photo.thumbNail)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: geometry.size.width, height: geometry.size.height)
                                            .clipped()
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    Button(action: {
                                        selectedPhoto = photo
                                        showActionSheet = true
                                    }) {
                                        Image(systemName: "ellipsis")
                                            .foregroundColor(.white)
                                            .padding(8)
                                            .background(Color.black.opacity(0.5))
                                            .clipShape(Circle())
                                    }
                                    .padding(5)
                                }
                            }
                            .frame(width: itemWidth, height: itemWidth)
                            .contentShape(Rectangle())                            
                        }
                    }
                }
                
                ZStack {
                    if showPhotoMoveDialog, let selectedPhoto = self.selectedPhoto {
                        Rectangle().fill(.primary.opacity(0.5))
                            .frame(maxWidth:.infinity, maxHeight: .infinity)
                            .edgesIgnoringSafeArea(.all)
                        
                        SinglePhotoMoveDialog(parent: self, photo: selectedPhoto, currentAlbum: album)
                    }
                }
                .transition(.opacity)
                .animation(.easeInOut, value: true)
            }
            .onDisappear {
                self.selectedPhoto = nil
                imageViewModel.selectedPhotos = []
                parent.showImageViewer = false
            }
        }
        .background(Color(UIColor.secondarySystemBackground))
        .navigationBarTitle(album.name)
        .navigationBarItems(trailing: Button(action: {
            imageViewModel.sortDescending.toggle()
            withAnimation {
                imageViewModel.sortPhotos()
            }
        }, label: {
            Image(systemName: "arrow.up.arrow.down")
        }))
        .actionSheet(isPresented: $showActionSheet) {
            if PhotoManagementService.shared.albums.count > 1 {
                ActionSheet(title: Text("Photo Options"), buttons: [
                    .default(Text("Save to Photos")) {
                        if let photo = selectedPhoto {
                            UIImageWriteToSavedPhotosAlbum(photo.image, nil, nil, nil)
                        }
                    },
                    .default(Text("Move to...")) {
                        withAnimation(.bouncy) {
                            showPhotoMoveDialog = true
                        }
                    },
                    .destructive(Text("Delete")) {
                        if let photo = selectedPhoto {
                            DeletePhoto(photo: photo)
                        }
                    },
                    .cancel()
                ])
            }else {
                ActionSheet(title: Text("Photo Options"), buttons: [
                    .default(Text("Save to Photos")) {
                        if let photo = selectedPhoto {
                            UIImageWriteToSavedPhotosAlbum(photo.image, nil, nil, nil)
                        }
                    },
                    .destructive(Text("Delete")) {
                        if let photo = selectedPhoto {
                            DeletePhoto(photo: photo)
                        }
                    },
                    .cancel()
                ])
            }
        }
    }
    
    func DeletePhoto(photo: OpenPhoto) {
        imageViewModel.selectedPhotos.removeAll { $0.id == photo.id }
        PhotoManagementService.shared.deletePhotoFromAlbum(Album: album, id: photo.id)
    }
}
