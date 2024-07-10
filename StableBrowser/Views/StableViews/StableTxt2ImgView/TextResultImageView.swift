import Swift
import SwiftUI

struct TextResultImageView: View {
    var txt2imgView: StableTxt2ImgView
    var parent: TextResultSection
    var resultImages: [ResultImage]
    
    @Binding var selectedImageIndex: Int
    @State var scale: CGFloat = 1.0
    @State var lastScale: CGFloat = 1.0
    @State var offset: CGSize = .zero
    @State var lastOffset: CGSize = .zero
    @State var showSourceImage: Bool = false
    @State private var minimumScale: CGFloat = 0.3

    @State private var showAlert: Bool = false
    
    @State private var isSavePhotoViewVisible: Bool = false
    
    @State private var doubleTapCount: Int = 0

    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            VStack {
                TabView(selection: $selectedImageIndex) {
                    ForEach(0..<resultImages.count, id: \.self) { index in
                        VStack {
                            ZStack {
                                Image(uiImage: resultImages[index].image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .scaleEffect(scale)
                                    .offset(offset)
                                    .animation(.easeInOut, value: showSourceImage)
                                    .gesture(
                                        MagnificationGesture()
                                            .onChanged { value in
                                                if self.minimumScale > self.lastScale * value.magnitude {
                                                    self.scale = self.minimumScale
                                                } else {
                                                    self.scale = self.lastScale * value.magnitude
                                                }
                                            }
                                            .onEnded { value in
                                                self.lastScale = self.scale
                                            }
                                    )
                                    .gesture(LongPressGesture(minimumDuration: 0.5) 
                                        .onEnded { _ in
                                            showAlert = true
                                    })
                                    .simultaneousGesture(
                                        scale > 1 || offset != .zero ? DragGesture()
                                            .onChanged { value in
                                                self.offset = CGSize(width: self.lastOffset.width + value.translation.width, height: self.lastOffset.height + value.translation.height)
                                            }
                                            .onEnded { _ in
                                                self.lastOffset = self.offset
                                            } : nil
                                    )
                                
                              
                            }
                            .transition(.opacity)
                            .animation(.easeInOut, value: showSourceImage)
                        }
                        .tag(index)
                    }.transition(.opacity)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
        }
        .background(Color.black)
        .onTapGesture { location in
            doubleTapCount += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if doubleTapCount > 1 {
                    if scale == 1.0 {
                        let width = UIScreen.main.bounds.width
                        let height = UIScreen.main.bounds.height
                        let x = width / 2
                        let y = (height + 40) / 2 - 100

                        withAnimation {
                            scale = 2.0
                            // Calculate the difference between location.x and the midpoint of width.
                            let offsetX =  (x - location.x) * 2
                            // Calculate the difference between location.y and the midpoint of height.
                            let offsetY =  (y - location.y) * 2
                            // Set the offset.
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
                    doubleTapCount = 0
                }
                else {
                    doubleTapCount = 0
                }
            }
        }
        .navigationBarItems(trailing: Button(action: {
            withAnimation{
                isSavePhotoViewVisible = true
            }
        }) {
            Image(systemName: "square.and.arrow.down")
        })
        .sheet(isPresented: $isSavePhotoViewVisible) {
            SavePhotoView(image: resultImages[selectedImageIndex].image, sourceImage: UIImage(), additionalInfo: resultImages[selectedImageIndex].info)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.hidden)
                .ignoresSafeArea(.all)
        }
        .alert(isPresented: $showAlert) {
            return Alert(
                title: Text("Set as Base Image"),
                message: Text("Do you want to set this image as the base image?"),
                primaryButton: .default(Text("Set")) {
//                    txt2imgView.baseImage = resultImages[selectedImageIndex].image
//                    txt2imgView.width = resultImages[selectedImageIndex].image.size.width
//                    txt2imgView.height = resultImages[selectedImageIndex].image.size.height
//                    txt2imgView.maskImage = nil
////                    txt2imgView.resizeScale = 1.0
//                    presentationMode.wrappedValue.dismiss()
                },
                secondaryButton: .cancel()
            )
        }.onChange(of: presentationMode.wrappedValue.isPresented) { oldValue, newValue in
            if !newValue {
                parent.resultSectionId = UUID()
            }
        }
    }
    
    
    
    var zoomPanResetButton: some View {
        Button("Reset scale and position") {
            resetZoomPan()
        }
    }
    
    var sourceImageButton: some View {
        HStack {
            VStack {
                Image(systemName: "eye")
                    .font(.title)
                    .foregroundColor(.accentColor)
                    .padding(.horizontal, 2)
                    .padding(.bottom, 2)
                Text("Show Source")
                    .font(.caption)
                    .foregroundColor(.accentColor)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .gesture(
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
    
    func resetZoomPan() {
        withAnimation {
            scale = 1.0
            lastScale = 1.0
            offset = .zero
            lastOffset = .zero
        }
    }
    
    func triggerSetBaseImageAlert() {
        showAlert = true
    }
    
}
