import SwiftUI

struct GalleryView: View {
    @StateObject private var photoManagementService = PhotoManagementService.shared
    @State internal var isNavigating = false  // State to track navigation status
    @State internal var selectedImageInedex: Int = 0
    @State internal var showImageViewer: Bool = false

    @State private var isEditAlbum = false
    @State internal var selectedAlbum: Album?

    @State internal var isShowingPasswordAlert = false
    
    @State internal var currentIndex = 0
    @State private var redrawId: Bool = false
    
    var isPortraitMode: Bool {
        get {
            if UIDevice.current.userInterfaceIdiom == .pad {
                return false
            } else {
                return verticalSizeClass == .regular
            }
        }
    }
    
    // MARK: - Environment
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    var body: some View {
        ZStack {
            NavigationView {
                GeometryReader { geometry in
                    let columns = [
                        GridItem(.adaptive(minimum: 150, maximum: 150), spacing: 16)
                    ]
                    ScrollView(.vertical) {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(photoManagementService.albums) { album in
                                let isLocked = album.isSecret && photoManagementService.unlockedAlbums[album.id] == false
                                if isLocked {
                                    albumContent(album, locked: true)
                                        .onTapGesture {
                                            selectedAlbum = album
                                            withAnimation {
                                                isShowingPasswordAlert = true
                                            }
                                        }
                                }
                                else {
                                    NavigationLink(destination: AlbumView(parent: self, album: album)) {
                                        albumContent(album, locked: false)
                                    }
                                    .simultaneousGesture(TapGesture().onEnded {
                                        ImageViewModel.shared.selectedPhotos = ImageViewModel.shared.getPhotos(album: album)
                                        ImageViewModel.shared.sortPhotos()
                                        ImageViewModel.shared.selectedAlbum = album
                                    })
                                }
                            }
                        }
                        .padding(16)
                    }
                    .scrollIndicators(.hidden)
                    .scrollClipDisabled()
                    .navigationTitle("GALLERY")
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationBarItems(trailing: Button(action: {
                        withAnimation(.bouncy) {
                            PhotoManagementService.shared.showNewAlbumDialog()
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.primary)
                            .font(.title2)
                    })
                }
                .background(Color(.systemBackground))
            }
            .navigationViewStyle(.stack)
            
            ZStack {
                if isEditAlbum {
                    Rectangle().fill(.black.opacity(0.5))
                        .frame(maxWidth:.infinity, maxHeight: .infinity)
                        .edgesIgnoringSafeArea(.all)
                    AlbumEditView(parent: self, isShowing: $isEditAlbum, album: $selectedAlbum)
                        .id(selectedAlbum)
                }
                if isShowingPasswordAlert {
                    Rectangle().fill(.black.opacity(0.5))
                        .frame(maxWidth:.infinity, maxHeight: .infinity)
                        .edgesIgnoringSafeArea(.all)
                    PasswordAlertView(isShowing: $isShowingPasswordAlert, album: selectedAlbum!)
                        .id(selectedAlbum)
                }
            }.transition(.move(edge: .bottom).combined(with: .opacity))
            
        }
        .id(photoManagementService.toggleRedrawAlbumList)
        .overlay{
            ZStack {
                if showImageViewer {
                    PhotoView(parent: self, currentIndex: $currentIndex, isPresented: $showImageViewer)
                }
            }
        }
        .onAppear{
            photoManagementService.updateAlbumThumbnails()
        }
    }

    private func albumContent(_ album: Album, locked: Bool) -> some View {
        VStack(spacing: 0) {
            ZStack {
                if locked {
                    Rectangle()
                        .fill(Color.gray)
                        .overlay(
                            Image(systemName: "lock.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.secondary)
                        )
                } else {
                    if let thumbnailPhoto = album.thumbnail, let thumbnailData = thumbnailPhoto.getThumbnailData() {
                        Image(uiImage: UIImage(data: thumbnailData)!)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 150, height: 150)
                            .clipped()
                    }
                    else if let firstPhoto = album.photos.first, let thumbnailData = firstPhoto.getThumbnailData() {
                        Image(uiImage: UIImage(data: thumbnailData)!)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 150, height: 150)
                            .clipped()
                    } else {
                        Rectangle()
                            .fill(Color.gray)
                            .overlay(
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 50))
                                    .foregroundColor(.secondary)
                            )
                    }
                }
            }
            .frame(width: 150, height: 150)
            .clipShape(Rectangle())
            .overlay {
                if !locked && album.isSecret {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Image(systemName: "lock.open.fill")
                                .font(.system(size: 25))
                                .foregroundColor(.black)
                                .opacity(0.5)
                        }
                    }
                    .padding(5)
                }
            }
            
            HStack {
                Text(album.name)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "ellipsis.circle.fill")
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 8)
            .frame(height: 50)
            .background(Color(.secondarySystemBackground))
            .contentShape(Rectangle())
            .onTapGesture {
                selectedAlbum = album
                withAnimation {
                    isEditAlbum = true
                }
            }
        }
        .frame(width: 150, height: 200)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
    }

    private var floatingButton: some View {
        VStack {
            Spacer()
            Button(action: MenuService.shared.showMenuSwitcher) {
                Image(systemName: "line.3.horizontal.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(Color.primary).opacity(0.8)
                    .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
            }
            .padding(.bottom, 25)
        }
        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.easeInOut, value: MenuService.shared.selectedMenu)
    }
}

struct GalleryView_Previews: PreviewProvider {
    static var previews: some View {
        GalleryView()
    }
}
