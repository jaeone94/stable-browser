import SwiftUI

enum PhotoViewMode {
    case none
    case title
    case detail
}

struct PhotoView: View {
    var parent: GalleryView
    @Binding var currentIndex: Int
    @Binding var isPresented: Bool
    
    @StateObject var imageViewModel = ImageViewModel.shared
    
    @State var scale: CGFloat = 1.0
    @State var lastScale: CGFloat = 1.0
    @State var offset: CGSize = .zero
    @State var lastOffset: CGSize = .zero
    @State var doubleTapCount: Int = 0
    @State private var minimumScale: CGFloat = 1
    @State private var minimumScale2: CGFloat = 0.9
    
    @GestureState private var imageCloseDraggingOffset: CGSize = .zero
    @State var imageViewerOffset: CGSize = .zero
    @State var showSourceImage: Bool = false
    @State var viewMode: PhotoViewMode = .none
    
    var body: some View {
        if isPresented {
            ZStack {
                Rectangle()
                    .fill(Color.black.opacity(1))
                    .frame(maxWidth: .infinity, maxHeight: .infinity).edgesIgnoringSafeArea(.all)
                
                
                VStack {
                    VStack {
                        TabView(selection: $currentIndex) {
                            ForEach(0..<imageViewModel.selectedPhotos.count, id: \.self) { index in
                                ZStack {
                                    Image(uiImage: imageViewModel.selectedPhotos[index].image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .scaleEffect(scale)
                                        .offset(offset)
                                        .offset(imageViewerOffset)
                                        .gesture(
                                            MagnificationGesture()
                                                .onChanged { value in
                                                    if self.minimumScale2 > self.lastScale * value.magnitude {
                                                        self.scale = self.minimumScale2
                                                    } else {
                                                        self.scale = self.lastScale * value.magnitude
                                                    }
                                                }
                                                .onEnded { value in
                                                    if minimumScale > self.scale {
                                                        self.scale = minimumScale
                                                        self.offset = .zero
                                                        self.lastOffset = .zero
                                                    }
                                                    self.lastScale = self.scale
                                                }
                                        )
                                        .simultaneousGesture(
                                            scale > 1 || offset != .zero ? DragGesture()
                                                .onChanged { value in
                                                    self.offset = CGSize(width: self.lastOffset.width + value.translation.width, height: self.lastOffset.height + value.translation.height)
                                                }
                                                .onEnded { _ in
                                                    self.lastOffset = self.offset
                                                } : nil
                                        )
                                    
                                    if let sourceImage = imageViewModel.selectedPhotos[index].sourceImage {
                                        Image(uiImage: sourceImage)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .scaleEffect(scale)
                                            .offset(offset)
                                            .offset(imageViewerOffset)
                                            .opacity(showSourceImage ? 1 : 0)
                                    }
                                }
                                .tag(index)
                            }
                        }
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .onTapGesture { location in
                    doubleTapCount += 1
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        if doubleTapCount > 1 {
                            doubleTapCount = 0
                            if scale == 1.0 {
                                let width = UIScreen.main.bounds.width
                                let height = UIScreen.main.bounds.height
                                let x = width / 2
                                let y = height / 2
                                
                                withAnimation {
                                    scale = 2.0
                                    lastScale = scale
                                    let offsetX =  (x - location.x) * 2
                                    let offsetY =  (y - location.y) * 2
                                    offset = CGSize(width: offsetX, height: offsetY)
                                    lastOffset = offset
                                }
                            } else {
                                withAnimation {
                                    scale = 1.0
                                    lastScale = 1.0
                                    offset = .zero
                                    lastOffset = .zero
                                }
                            }
                        }
                        if doubleTapCount == 1 {
                            withAnimation {
                                if viewMode == .none {
                                    viewMode = .title
                                }
                                else if viewMode == .title {
                                    viewMode = .detail
                                }else if viewMode == .detail {
                                    viewMode = .none
                                }
                            }
                            doubleTapCount = 0
                        }
                    }
                }
                .offset(imageViewerOffset)
                .gesture(
                    DragGesture()
                        .onEnded { value in
                            if value.translation.height > 100 {
                                withAnimation {
                                    parent.showImageViewer = false
                                }
                            }
                        }
                )
                .onDisappear {
                    isPresented = false
                }
                OverlayView(parent: self, viewMode: $viewMode, currentIndex: $currentIndex, showSourceImage: $showSourceImage)
            }
            .id(parent.showImageViewer)
        }
    }
}

struct OverlayView: View {
    var parent: PhotoView
    @StateObject var imageViewModel = ImageViewModel.shared
    @Binding var viewMode: PhotoViewMode
    @Binding var currentIndex: Int
    @Binding var showSourceImage: Bool
    
    @State var showAlert: Bool = false
        
    var strAdditionalInfo: String {
        
        let additionalInfo = imageViewModel.selectedPhotos[currentIndex].metaData
        var str = ""
        let keys = ["prompt", "negative_prompt", "sd_model_name", "sampler_name", "clip_skip", "steps", "cfg_scale", "denoising_strength", "seed", "subseed", "subseed_strength", "width", "height", "sd_vae_name", "restore_faces"]
        for key in keys {
            // Check if the key exists in the dictionary
            if let value = additionalInfo[key] {
                // If the key exists, add the key and value to the string
                str += "\"\(key)\": \"\(value)\""
                if key != keys.last {
                    str += ", "
                }
            }
        }
        return str
    }
    
    var body: some View {
        Group {
            if imageViewModel.selectedPhotos.count - 1 >= currentIndex {
                VStack(spacing: 0) {
                    HStack {
                        if viewMode != .none {
                            Text(imageViewModel.selectedPhotos[currentIndex].name)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .lineLimit(1)
                                .foregroundColor(.white)
                        }
                        Spacer()
                        Button(action: {
                            withAnimation {
                                parent.parent.showImageViewer = false
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 20, height: 20)
                                .foregroundColor(.white)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .background(viewMode == .none ? Color.clear : Color.gray.opacity(0.2))
                    
                    if viewMode == .detail {
                        if !strAdditionalInfo.isEmpty {
                            VStack {
                                Text(strAdditionalInfo)
                                    .font(.caption)
                                    .contentShape(Rectangle())
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .foregroundColor(.white)
                                    .padding()
                            }
                            .contentShape(Rectangle())
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.black.opacity(0.7))
                            .onTapGesture {
                                withAnimation {
                                    parent.viewMode = .none
                                }
                            }
                        }
                    } else {
                        Spacer()
                    }
                    
                    if viewMode != .none {
                        ZStack {
                            HStack {
                                Text(imageViewModel.selectedPhotos[currentIndex].createdAt, style: .date)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            }
                            
                            HStack {
                                Button(action: {
                                    showAlert = true
                                }, label: {
                                    Image(systemName: "trash.fill")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding(2)
                                })
                                
                                Spacer()
                                
                                if imageViewModel.selectedPhotos[currentIndex].sourceImage != nil {
                                    Image(systemName: showSourceImage ? "eye.fill" : "eye")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding(2).gesture(
                                        DragGesture(minimumDistance: 0)
                                            .onChanged { _ in
                                                withAnimation {
                                                    showSourceImage = true
                                                }
                                            }
                                            .onEnded { _ in
                                                withAnimation {
                                                    showSourceImage = false
                                                }
                                            }
                                    )
                                }
                            }
                            .alert(isPresented: $showAlert) {
                                Alert(title: Text("Delete this photo?"), message: Text("This action cannot be undone."), primaryButton: .destructive(Text("Delete")) {
                                    DeletePhoto(photo: imageViewModel.selectedPhotos[currentIndex])
                                }, secondaryButton: .cancel())
                            }
                        }
                        .padding()
                        .frame(height: 50)
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                        .background(viewMode == .none ? Color.clear : Color.gray.opacity(0.2))
                    }
                }
            }
            
        }
    }
    
    func DeletePhoto(photo: OpenPhoto) {
        let deleteImage = imageViewModel.selectedPhotos[currentIndex]
        withAnimation {
            parent.parent.showImageViewer = false
            
        }
        imageViewModel.selectedPhotos.remove(at: currentIndex)
        if let album = imageViewModel.selectedAlbum {
            PhotoManagementService.shared.deletePhotoFromAlbum(Album: album, id: deleteImage.id)
        }        
    }
}
