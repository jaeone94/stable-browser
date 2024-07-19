import SwiftUI

struct PhotoView: View {
    var parent: GalleryView
    @Binding var currentIndex: Int
    @Binding var isPresented: Bool
    
    @StateObject var imageViewModel = ImageViewModel.shared
    @StateObject var photoManagementService = PhotoManagementService.shared
    
    @State var scale: CGFloat = 1.0
    @State var lastScale: CGFloat = 1.0
    @State var offset: CGSize = .zero
    @State var lastOffset: CGSize = .zero
    @State var showSourceImage: Bool = false
    @State private var minimumScale: CGFloat = 1
    @State private var minimumScale2: CGFloat = 0.9
    
    @GestureState private var imageCloseDraggingOffset: CGSize = .zero
    @State var imageViewerOffset: CGSize = .zero
    @State var viewMode: Bool = false
    
    
    @State private var isAlertShown = false
    @State private var alertType: AlertType = .delete
    
    enum AlertType {
        case delete
        case img2img
    }
    
    @State private var showInfoView = false
    
    @State private var item: OpenPhotoActivityItem?
    
    @State private var doubleTapCount: Int = 0
    
    var strAdditionalInfo: String {
        let additionalInfo = imageViewModel.selectedPhotos[currentIndex].metaData
        var str = ""
        let keys = ["prompt", "negative_prompt", "sd_model_name", "sampler_name", "clip_skip", "steps", "cfg_scale", "denoising_strength", "seed", "subseed", "subseed_strength", "width", "height", "sd_vae_name", "restore_faces"]
        for key in keys {
            if let value = additionalInfo[key] {
                str += "\"\(key)\": \"\(value)\""
                if key != keys.last {
                    str += ", "
                }
            }
        }
        return str
    }
    
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
                                            .animation(.easeInOut(duration: 0.2), value: showSourceImage)
                                    
                                    }
                                }
                                .tag(index)
                            }
                        }
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    }
//                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .onTapGesture { location in
                    doubleTapCount += 1
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        if doubleTapCount > 1 {
                            withAnimation {
                                if scale == 1.0 {
                                    let width = UIScreen.main.bounds.width
                                    let height = UIScreen.main.bounds.height
                                    let x = width / 2
                                    let y = height / 2
                                    
                                    scale = 2.0
                                    lastScale = scale
                                    let offsetX = (x - location.x) * 2
                                    let offsetY = (y - location.y) * 2
                                    offset = CGSize(width: offsetX, height: offsetY)
                                    lastOffset = offset
                                } else {
                                    scale = 1.0
                                    lastScale = 1.0
                                    offset = .zero
                                    lastOffset = .zero
                                }
                            }
                            doubleTapCount = 0
                        } else if doubleTapCount == 1 {
                            withAnimation {
                                viewMode.toggle()
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
            }
            .overlay {
                VStack(spacing: 0) {
                    if viewMode {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(imageViewModel.selectedPhotos[currentIndex].name)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .lineLimit(1)
                                    .foregroundColor(.white)
                                Text(imageViewModel.selectedPhotos[currentIndex].createdAt, style: .date)
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                            }
                            Spacer()
                            Button(action: {
                                withAnimation {
                                    parent.showImageViewer = false
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
                        .background(Color.black.opacity(0.6))
                        
                        
                        
                        if showInfoView {
                            HStack {
                                Text(strAdditionalInfo)
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .contentShape(Rectangle())
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .padding()
                            }
                            .contentShape(Rectangle())
                            .frame(maxWidth: .infinity)
                            .background(Color.black.opacity(0.6))
                            .allowsHitTesting(false)
                        }else {
                            Spacer()
                        }
                        
                        HStack(spacing: 30) {
                            Button(action: {
                                item = OpenPhotoActivityItem(images: [imageViewModel.selectedPhotos[currentIndex]])
                            }) {
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundColor(.white)
                                    .font(.title2)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                withAnimation {
                                    showInfoView.toggle()
                                }
                            }) {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.white)
                                    .font(.title2)
                            }
                                                        
                            
                            if imageViewModel.selectedPhotos[currentIndex].sourceImage != nil {
                                Spacer()
                                
                                Image(systemName: showSourceImage ? "eye.fill" : "eye")
                                    .font(.title2)
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
                            
                            Spacer()
                            
                            Button(action: {
                                alertType = .img2img
                                isAlertShown = true
                            }) {
                                Image(systemName: "paintbrush.pointed")
                                    .foregroundColor(.white)
                                    .font(.title2)
                            }
                                                        
                            Spacer()
                            
                            Button(action: {
                                alertType = .delete
                                isAlertShown = true
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.white)
                                    .font(.title2)
                            }
                        }
                        .transition(.opacity)
                        .contentShape(Rectangle())
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black.opacity(0.6))
                    }
                }
            }
            .id(parent.showImageViewer)
            .alert(isPresented: $isAlertShown) {
                if alertType == .delete {
                    return Alert(
                        title: Text("Delete Photo"),
                        message: Text("Are you sure you want to delete this photo?"),
                        primaryButton: .destructive(Text("Delete")) {
                            deletePhoto()
                        },
                        secondaryButton: .cancel()
                    )
                } else {
                    return Alert(
                        title: Text("Image to Image"),
                        message: Text("Are you sure you want to use this image for Image to Image?"),
                        primaryButton: .default(Text("Use")) {
                            importBaseImage(imageViewModel.selectedPhotos[currentIndex].image)                            
                            MenuService.shared.switchMenu(to: MenuService.shared.menus[1])
                        },
                        secondaryButton: .cancel()
                    )
                }
            }
            .activitySheet($item)
        }
    }
    
    func importBaseImage(_ img: UIImage) {
        StableSettingViewModel.shared.baseImage = img
        StableSettingViewModel.shared.maskImage = nil
    }
    
    
    private func deletePhoto() {
        withAnimation{
            parent.showImageViewer = false
        }
        let photoToDelete = imageViewModel.selectedPhotos[currentIndex]
        imageViewModel.selectedPhotos.remove(at: currentIndex)
        if let album = imageViewModel.selectedAlbum {
            photoManagementService.deletePhotoFromAlbum(Album: album, id: photoToDelete.id)
        }
    }
}
