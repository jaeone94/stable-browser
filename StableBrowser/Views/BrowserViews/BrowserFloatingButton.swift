import SwiftUI

struct BrowserFloatingButton: View {
    var parent: BrowserView
    @StateObject var injectHistoryService = InjectHistoryService.shared
    @Binding var isVisible: Bool
    
    var offsetDistance: CGFloat {
        get {
            return isPortraitMode ? 60 : -60
        }
    }
    
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
        GeometryReader { geometry in
            ZStack {
                ZStack {
                    RadialGradient(gradient: Gradient(colors: [Color.white, Color.clear]), center: !isPortraitMode ? .topTrailing : .bottom, startRadius: 5, endRadius: 700)
                        .edgesIgnoringSafeArea(.all).opacity(0.9)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .edgesIgnoringSafeArea(.all)
                .background(.clear)
                .opacity(isVisible ? 1 : 0)
                .onTapGesture {
                    hideView()
                }

                HStack {
                    Spacer()
                    VStack {
                        if isPortraitMode {
                            Spacer()
                        }
                        ZStack {
                              // Disable Inject Mode
//                            Button(action: {
//                                withAnimation {
//                                    injectHistoryService.isAutoInjectMode.toggle()
//                                    if injectHistoryService.isAutoInjectMode {
//                                        parent.webViewModel.tryAutoInjectImage()
//                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                                            parent.webViewModel.injectAllImages()
//                                        }
//                                    }
//                                }
//                            }) {
//                                HStack(spacing:0) {
//                                    Spacer()
//                                    Image(systemName: injectHistoryService.isAutoInjectMode ? "square.on.square.dashed" : "rectangle.on.rectangle.slash")
//                                        .font(.system(size: 25))
//                                        .foregroundColor(Color.white).opacity(1)
//                                    Spacer()
//                                }
//                                .frame(width: 50, height: 50)
//                                .background(Color.black).opacity(0.8)
//                                .clipShape(Circle())
//                                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
//                            }
//                            .overlay {
//                                HStack {
//                                    if !isPortraitMode {
//                                        Spacer()
//                                    }
//                                    Text(injectHistoryService.isAutoInjectMode ? "Auto-inject : On" : "Auto-inject : Off")
//                                        .font(.footnote)
//                                        .fontWeight(.semibold)
//                                        .foregroundColor(.black.opacity(0.8))
//                                    if isPortraitMode {
//                                        Spacer()
//                                    }
//                                }
//                                .frame(width: 140)
//                                .offset(x: isPortraitMode ? 100: -100)
//                                .onTapGesture {
//                                    withAnimation {
//                                        injectHistoryService.isAutoInjectMode.toggle()
//                                        if injectHistoryService.isAutoInjectMode {
//                                            parent.webViewModel.tryAutoInjectImage()
//                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                                                parent.webViewModel.injectAllImages()
//                                            }
//                                        }
//                                    }                                    
//                                }
//                            }
//                            .offset(y: isVisible ? offsetDistance * -4 : 0)
                            
                            
                            Button(action: {
                                withAnimation(.bouncy) {
                                    parent.isImageBasketVisible = true
                                }
                                hideView()
                            }) {
                                HStack(spacing:0) {
                                    Spacer()
                                    Image(systemName: "photo.badge.plus")
                                        .font(.system(size: 25))
                                        .foregroundColor(Color.white).opacity(1)
                                    Spacer()
                                }
                                .frame(width: 50, height: 50)
                                .background(Color.black).opacity(0.8)
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                            }
                            .overlay {
                                HStack {
                                    if !isPortraitMode {
                                        Spacer()
                                    }
                                    Text("Image selector")
                                        .font(.footnote)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.black.opacity(0.8))
                                    if isPortraitMode {
                                        Spacer()
                                    }
                                }
                                .frame(width: 140)
                                .offset(x: isPortraitMode ? 100: -100)
                                .onTapGesture {
                                    withAnimation(.bouncy) {
                                        parent.isImageBasketVisible = true
                                    }
                                    hideView()
                                }
                            }
                            .offset(y: isVisible ? offsetDistance * -3 : 0)
                            
                            Button(action: {
                                hideView()
                                parent.showSDView()
                            }) {
                                HStack(spacing:0) {
                                    Spacer()
                                    Image(systemName: "camera.viewfinder")
                                        .font(.system(size: 30))
                                        .foregroundColor(Color.white).opacity(1)
                                    Spacer()
                                }
                                .frame(width: 50, height: 50)
                                .background(Color.black).opacity(0.8)
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                            }
                            .overlay {
                                HStack {
                                    if !isPortraitMode {
                                        Spacer()
                                    }
                                    Text("Capture screenshot")
                                        .font(.footnote)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.black.opacity(0.8))
                                    if isPortraitMode {
                                        Spacer()
                                    }
                                }
                                .frame(width: 140)
                                .offset(x: isPortraitMode ? 100: -100)
                                .onTapGesture {
                                    hideView()
                                    parent.showSDView()
                                }
                            }
                            .offset(y: isVisible ? offsetDistance * -2 : 0)
                            
                            Button(action: {
                                parent.webViewModel.getAllImageTags()
                                hideView()
                            }) {
                                HStack(spacing:0) {
                                    Spacer()
                                    Image(systemName: "photo.stack")
                                        .font(.system(size: 30))
                                        .foregroundColor(Color.white).opacity(1)
                                    Spacer()
                                }
                                .frame(width: 50, height: 50)
                                .background(Color.black).opacity(0.8)
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                            }
                            .overlay {
                                HStack {
                                    if !isPortraitMode {
                                        Spacer()
                                    }
                                    Text("Scan all images")
                                        .font(.footnote)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.black.opacity(0.8))
                                    if isPortraitMode {
                                        Spacer()
                                    }
                                }
                                .frame(width: 140)
                                .offset(x: isPortraitMode ? 100: -100)
                                .onTapGesture {
                                    parent.webViewModel.getAllImageTags()
                                    hideView()
                                }
                            }
                            .offset(y: isVisible ? offsetDistance * -1 : 0)
                            
                            Button(action: hideView) {
                                HStack(spacing:0) {
                                    Spacer()
                                    Image(systemName: "xmark")
                                        .font(.system(size: 30))
                                        .foregroundColor(Color.white).opacity(1)
                                    Spacer()
                                }
                                .frame(width: 50, height: 50)
                                .background(Color.black).opacity(0.8)
                                .clipShape(Circle())
                                .offset(y: 0)
                                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                            }
                        }
                        .padding(.top, isPortraitMode ? 0 : 5)
                        .padding(.trailing, isPortraitMode ? 0 : 95)
                        if !isPortraitMode {
                            Spacer()
                        }
                    }
                    .padding(.bottom, 35)
                    if isPortraitMode {
                        Spacer()
                    }
                }.edgesIgnoringSafeArea(.horizontal)
                .edgesIgnoringSafeArea(.bottom)
            }
            .opacity(isVisible ? 1 : 0)
        }
    }
    func hideView() {
        withAnimation(.bouncy) {
            isVisible = false
        }
    }
}

