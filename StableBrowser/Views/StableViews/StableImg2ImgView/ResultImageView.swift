import SwiftUI

struct ResultImageView: View {
    var resultImages: [ResultImage]
    var sourceImage: UIImage?
    
    @State var selectedImageIndex: Int = 0
    @State var scale: CGFloat = 1.0
    @State var lastScale: CGFloat = 1.0
    @State var offset: CGSize = .zero
    @State var lastOffset: CGSize = .zero
    @State var showSourceImage: Bool = false
    @State private var minimumScale: CGFloat = 1
    @State private var minimumScale2: CGFloat = 0.9
    
    @State var imageViewerOffset: CGSize = .zero
    
    @State private var isAlertShown = false

    @State private var showInfoView = false
    
    @State private var doubleTapCount: Int = 0
    
    @State private var isSavePhotoViewVisible: Bool = false
    
    @Environment(\.presentationMode) var presentationMode
    
    var strAdditionalInfo: String {
        let additionalInfo = resultImages[selectedImageIndex].info
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
        ZStack {
            Rectangle()
                .fill(Color.black.opacity(1))
                .frame(maxWidth: .infinity, maxHeight: .infinity).edgesIgnoringSafeArea(.all)
            
            VStack {
                TabView(selection: $selectedImageIndex) {
                    ForEach(0..<resultImages.count, id: \.self) { index in
                        ZStack {
                            Image(uiImage: resultImages[index].image)
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
                            if let sourceImage = self.sourceImage {
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
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                
                HStack(spacing: 30) {
                    Button(action: {
                        withAnimation {
                            showInfoView.toggle()
                        }
                    }) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.white)
                            .font(.title2)
                    }
                                        
                    
                    if let sourceImage = self.sourceImage {
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
                        isAlertShown = true
                    }) {
                        Image(systemName: "paintbrush.pointed")
                            .foregroundColor(.white)
                            .font(.title2)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        savePhoto()
                    }) {
                        Image(systemName: "square.and.arrow.down")
                            .foregroundColor(.white)
                            .font(.title2)
                    }
                }
                .transition(.opacity)
                .contentShape(Rectangle())
                .frame(height: 35)
                .padding()
                .background(Color.black.opacity(0.6))
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
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                    }
            )
        }
        .overlay {
            VStack(spacing: 0) {
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
                    .onTapGesture {
                        withAnimation{showInfoView = false}
                    }
                } else {
                    Spacer()
                }
            }
        }
        .alert(isPresented: $isAlertShown) {
            return Alert(
                title: Text("Image to Image"),
                message: Text("Are you sure you want to use this image for Image to Image?"),
                primaryButton: .default(Text("Use")) {
                    importBaseImage(resultImages[selectedImageIndex].image)
                    MenuService.shared.switchMenu(to: MenuService.shared.menus[1])
                },
                secondaryButton: .cancel()
            )
        }
        .sheet(isPresented: $isSavePhotoViewVisible) {
            SavePhotoView(image: self.resultImages[selectedImageIndex].image, sourceImage: sourceImage ?? UIImage(), additionalInfo: resultImages[selectedImageIndex].info)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.hidden)
                .ignoresSafeArea(.all)
        }
    }
    
    func importBaseImage(_ img: UIImage) {
        StableSettingViewModel.shared.baseImageFromResult = img
    }
    
    private func savePhoto() {
        withAnimation {
            isSavePhotoViewVisible = true
        }
    }
}
