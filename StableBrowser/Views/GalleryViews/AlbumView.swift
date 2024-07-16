import SwiftUI
import RealmSwift

struct AlbumView: View {
    var parent: GalleryView
    let album: Album
    @StateObject var imageViewModel = ImageViewModel.shared
    @State var selectedPhoto: OpenPhoto?
    @State var showPhotoMoveDialog: Bool = false
    
    @State private var showDeleteAlert = false
    @State private var photoToDelete: OpenPhoto?
    
    @State internal var isSelectionMode: Bool = false
    @State internal var selectedPhotos: Set<ObjectId> = []
    
    @State private var showExportSheet = false
    @State private var item: ActivityItem?
    
    @State var photosToMove: [OpenPhoto] = []
    
    var isSelectPhoto: Bool {
        get {
            return !getSelectedImages().isEmpty
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let isLandscape = width > geometry.size.height
            let itemCount = isLandscape ? 5 : 3
            let spacing: CGFloat = 1
            let totalSpacing = spacing * CGFloat(itemCount - 1)
            let itemWidth = (width - totalSpacing) / CGFloat(itemCount)
            let photos = imageViewModel.selectedPhotos
            
            ZStack {
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: spacing), count: itemCount), spacing: spacing) {
                        ForEach(photos) { photo in
                            GeometryReader { geometry in
                                ZStack(alignment: .topTrailing) {
                                    Button(action: {
                                        if isSelectionMode {
                                            withAnimation {
                                                togglePhotoSelection(photo)
                                            }
                                        } else {
                                            parent.currentIndex = photos.firstIndex(of: photo) ?? 0
                                            withAnimation {
                                                parent.showImageViewer = true
                                            }
                                        }
                                    }) {
                                        Image(uiImage: photo.thumbNail)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: geometry.size.width, height: geometry.size.height)
                                            .clipped()
                                            .overlay(
                                                isSelectionMode ?
                                                    ZStack {
                                                        Color.black.opacity(0.3)
                                                        Image(systemName: selectedPhotos.contains(photo.id) ? "checkmark.circle.fill" : "circle")
                                                            .foregroundColor(.white)
                                                            .font(.title)
                                                    }
                                                    : nil
                                            )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .if(!isSelectionMode) { view in
                                        view.contextMenu {
                                            Button(action: {
                                                item = ActivityItem(images: [photo])
                                            }) {
                                                Label("Share", systemImage: "square.and.arrow.up")
                                            }
                                            
                                            // 앨범 개수가 두개이상인 경우
                                            if PhotoManagementService.shared.albums.count > 1 {
                                                Button(action: {
                                                    withAnimation {
                                                        photosToMove = [photo]
                                                        showPhotoMoveDialog = true
                                                    }
                                                }) {
                                                    Label("Move", systemImage: "arrowshape.turn.up.right")
                                                }
                                            }

                                            Button(action: {
                                                photoToDelete = photo
                                                showDeleteAlert = true
                                            }) {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                    }
                                }
                            }
                            .frame(width: itemWidth, height: itemWidth)
                            .contentShape(Rectangle())
                        }
                    }
                }
                
                if showPhotoMoveDialog {
                    Rectangle().fill(.black.opacity(0.5))
                        .frame(maxWidth:.infinity, maxHeight: .infinity)
                        .edgesIgnoringSafeArea(.all)
                    
                    PhotosMoveDialog(parent: self, photos: photosToMove, currentAlbum: album)
                }
            }
            .onDisappear {
                self.selectedPhoto = nil
                imageViewModel.selectedPhotos = []
                parent.showImageViewer = false
            }
        }
        .background(Color(UIColor.secondarySystemBackground))
        .navigationBarTitle(album.name)
        .navigationBarItems(
            trailing: HStack {
                Button(action: {
                    withAnimation {
                        isSelectionMode.toggle()
                        if !isSelectionMode {
                            selectedPhotos.removeAll()
                        }
                    }
                }) {
                    Image(systemName: isSelectionMode ? "xmark" : "checkmark.circle")
                }
                
                if !isSelectionMode {
                    Button(action: {
                        imageViewModel.sortDescending.toggle()
                        withAnimation {
                            imageViewModel.sortPhotos()
                        }
                    }) {
                        Image(systemName: "arrow.up.arrow.down")
                    }
                }
            }
        )
        .alert(isPresented: $showDeleteAlert) {
            Alert(
                title: Text("Delete Photo"),
                message: Text("Once deleted, this photo cannot be recovered. Are you sure you want to delete it?"),
                primaryButton: .destructive(Text("Yes")) {
                    if isSelectionMode {
                        deleteSelectedPhotos()
                    } else if let photoToDelete = photoToDelete {
                        withAnimation {
                            DeletePhoto(photo: photoToDelete)
                        }
                    }
                },
                secondaryButton: .cancel()
            )
        }
        .overlay {
            if isSelectionMode && !showPhotoMoveDialog {
                VStack {
                    Spacer()
                    HStack {
                        Button(action: {
                            let images = getSelectedImages()
                            if !images.isEmpty {
                                item = ActivityItem(images: images)
                            }
                        }) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.title2)
                                .disabled(!isSelectPhoto)
                        }
                        .disabled(!isSelectPhoto)
                        
                        if PhotoManagementService.shared.albums.count > 1 {
                            Spacer()
                            
                            Button(action: {
                                withAnimation {
                                    photosToMove = getSelectedImages()
                                    showPhotoMoveDialog = true
                                }
                            }) {
                                Image(systemName: "arrowshape.turn.up.right")
                                    .font(.title2)
                                    .disabled(!isSelectPhoto)
                            }
                            .disabled(!isSelectPhoto)
                        }
                        
                        Spacer()

                        Button(action: {
                            withAnimation {
                                selectedPhotos = Set(imageViewModel.selectedPhotos.map { $0.id })
                            }
                        }) {
                            Image(systemName: "checkmark.circle")
                                .font(.title2)
                        }
                        
                        Spacer()

                        Button(action: {
                            withAnimation {
                                selectedPhotos.removeAll()
                            }
                        }) {
                            Image(systemName: "circle")
                                .font(.title2)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            showDeleteAlert = true
                        }) {
                            Image(systemName: "trash")
                                .font(.title2)
                                .disabled(!isSelectPhoto)
                        }
                        .disabled(!isSelectPhoto)
                    }
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity)
                    .frame(height:60)
                    .background(Color(UIColor.systemBackground).opacity(0.7))
                    .shadow(color: Color(.black).opacity(0.2), radius: 8, x: 0, y: 2)
                }.transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .activitySheet($item)
    }
        
    
    private func togglePhotoSelection(_ photo: OpenPhoto) {
        if selectedPhotos.contains(photo.id) {
            selectedPhotos.remove(photo.id)
        } else {
            selectedPhotos.insert(photo.id)
        }
    }
    
    private func exportSelectedPhotos() {
        showExportSheet = true
    }

    private func getSelectedImages() -> [OpenPhoto] {
        return imageViewModel.selectedPhotos
            .filter { selectedPhotos.contains($0.id) }
    }
    
    private func deleteSelectedPhotos() {
        for photoId in selectedPhotos {
            if let photo = imageViewModel.selectedPhotos.first(where: { $0.id == photoId }) {
                DeletePhoto(photo: photo)
            }
        }
        selectedPhotos.removeAll()
        isSelectionMode = false
    }
    
    func DeletePhoto(photo: OpenPhoto) {
        imageViewModel.selectedPhotos.removeAll { $0.id == photo.id }
        PhotoManagementService.shared.deletePhotoFromAlbum(Album: album, id: photo.id)
    }
}
