import SwiftUI

struct BaseImageSection: View {
    var parent: StableImg2ImgView
    @Binding var baseImage: UIImage {
        didSet {
            StableSettingViewModel.shared.baseImage = self.baseImage
        }
    }
    @Binding var maskImage: UIImage? {
        didSet {
            StableSettingViewModel.shared.maskImage = self.maskImage
        }
    }
    
    
    @Binding var resizeScale: Double
    @Binding var width: CGFloat
    @Binding var height: CGFloat
    @Binding var isInpaintMode: Bool
    
    
    @State private var alertVisible = false

    @Binding var uploadImageSheetVisible: Bool
    
    
    var body: some View {
        Section(header: Text("Source Image")) {
            ZStack {
                VStack {
                    if width == 0 && height == 0 {
                        Button(action: {
                            withAnimation {
                                uploadImageSheetVisible = true
                            }
                        }, label: {
                            VStack {
                                Image(systemName: "square.and.arrow.up")
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 50, height: 50)
                                    .foregroundColor(.accentColor)
                                Text("Upload Image")
                                    .foregroundColor(.accentColor)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .padding(.top, 10)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 300)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                            .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                        })
                    }
                    else {
                        ZStack {
                            Image(uiImage: baseImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .background(Color.gray)
                                .cornerRadius(10)
                                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                            
                            if let maskImage = maskImage {
                                Image(uiImage: maskImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .background(Color.clear)
                                    .cornerRadius(10)
                                    .opacity(0.5)
                            }
                        }.padding(.top, 10)
                        
                        let sizeInPixels = convertCGSizeToPixel(size: baseImage.size, resizeScale: CGFloat(resizeScale))
                        let printWidth = sizeInPixels.width
                        let printHeight = sizeInPixels.height
                        Text("\(Int(printWidth)) x \(Int(printHeight))")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.top, 5)
                        
                        HStack {
                            Text("Resize scale")
                            Spacer()
                            Text("\(resizeScale, specifier: "%.2f")")
                        }
                        Slider(value: $resizeScale, in: 0.1...2.0, step: 0.05)
                        
                        NavigationLink(destination: StableCanvasView(parent: self, width: width, height: height, baseImage: baseImage, isInpaintMode: $isInpaintMode)) {
                            HStack {
                                Text("Clear Image").font(.headline).foregroundColor(.red)
                                    .onTapGesture {
                                        withAnimation {
                                            alertVisible = true
                                        }
                                    }
                                Spacer()
                                Text("Edit Image").font(.headline).foregroundColor(.accentColor)
                            }
                        }.padding(.vertical, 10)
                        
                    }
                }
                .padding(5)
            }
        }
        .alert(isPresented: $alertVisible) {            
            Alert(title: Text("Clear Source Image"), message: Text("Are you sure you want to clear the source image?"), primaryButton: .destructive(Text("Clear")) {
                BrowserViewModel.shared.imageId = nil
                BrowserViewModel.shared.imageSrc = nil
                parent.baseImage = UIImage()
                parent.maskImage = nil
                withAnimation {
                    baseImage = UIImage()
                    width = 0
                    height = 0
                    parent.canInject = false
                }
            }, secondaryButton: .cancel())
        }
    }
    
    func convertCGSizeToPixel(size: CGSize, resizeScale: CGFloat) -> CGSize {
        return CGSize(width: Int(size.width * resizeScale * baseImage.scale), height: Int(size.height * resizeScale * baseImage.scale)).adjustedToNearest8Multiple()
    }
}

