import SwiftUI
import RealmSwift
struct AlbumView: View {
    var parent: GalleryView
    let album: Album
    @StateObject var imageViewModel = ImageViewModel.shared
    @State var selectedPhoto: OpenPhoto?
    @State var showPhotoMoveDialog: Bool = false
    @State var showDeleteAlert: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let isLandscape = width > geometry.size.height
            let itemCount = isLandscape ? 5 : 3
            let spacing: CGFloat = 1
            let totalSpacing = spacing * CGFloat(itemCount - 1)
            let itemWidth = (width - totalSpacing) / CGFloat(itemCount)
            let selectedPhotos = imageViewModel.selectedPhotos // : [OpenPhoto]
            ZStack {
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: spacing), count: itemCount), spacing: spacing) {
                        ForEach(selectedPhotos) { photo in
                            GeometryReader { geometry in
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
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .contentShape(Rectangle())
                                .contextMenu {
                                    if PhotoManagementService.shared.albums.count > 1 {
                                        Button(action: {
                                            selectedPhoto = photo
                                            withAnimation(.bouncy) {
                                                showPhotoMoveDialog = true
                                            }
                                        }) {
                                            Label("Move to...", systemImage: "folder")
                                        }
                                    }
                                    Button(action: {
                                        selectedPhoto = photo
                                        showDeleteAlert = true
                                    }) {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .alert(isPresented: $showDeleteAlert) {
                                    Alert(title: Text("Delete this photo?"), message: Text("This action cannot be undone."), primaryButton: .destructive(Text("Delete")) {
                                        DeletePhoto()
                                    }, secondaryButton: .cancel())
                                }
                            }
                            .frame(width: itemWidth, height: itemWidth)
                        }
//                        .animation(.easeInOut, value: imageViewModel.selectedPhotos)
                    }
                }
                ZStack { // Global Dialogs
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
    }
    
    func DeletePhoto() {
        if let photo = self.selectedPhoto {
            // remove at imageViewModel.selectedPhotos
            imageViewModel.selectedPhotos.removeAll { $0.id == photo.id }
            PhotoManagementService.shared.deletePhotoFromAlbum(Album: album, id: photo.id)
        }
    }
}
