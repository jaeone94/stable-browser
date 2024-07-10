import SwiftUI
import WebKit

struct BrowserView: View {
    // MARK: - ViewModel Properties
    @StateObject var browserViewModel = BrowserViewModel.shared
    @StateObject var webViewModel: WebViewModel
    @StateObject var bridgeViewModel: BridgeViewModel
    @StateObject var stableSettingViewModel = StableSettingViewModel.shared
    @StateObject var photoManagementService = PhotoManagementService.shared    
    
    // MARK: - Private State
    @State private var dragOffset = CGSize.zero
    @State private var isTabTransitionActive = false
    @State private var isUrlTextHidden = false
    @State private var isToolbarButtonHidden = false
    @State private var isKeyboardOpen = false
    @State private var isGestureStartedAtEdge = false
    @State private var isBookmarkViewVisible = false
    @State private var isHorizontalBookmarkViewVisible = false
    @State private var horizontalBookmarkViewOffset: CGSize = .zero
        
    // MARK: - Internal State
    @State internal var isSimpleToolbar = false
    @State internal var isTabViewVisible = false
    @State internal var isTabVisibleForAnimation = false
    @State internal var isSDViewVisible = false
    @State internal var isUrlEditViewVisible = false
    @State internal var isMenuSwitcherVisible = false
    @State internal var isFloatingButtonVisible = false
    
    // MARK: - Dialog visible
    @State internal var isErrorViewVisible = false
    
    @State internal var urlText: String = ""
    @State internal var img_tag: String?
    
    
    internal var isDarkMode: Bool {
        return UITraitCollection.current.userInterfaceStyle == .dark
    }
        
    // MARK: - Computed State
    internal var isBookmarked: Bool {
        browserViewModel.bookmarks.contains(where: { $0.url == browserViewModel.currentUrl })
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
    
    @State internal var isImageBasketVisible = false
    
    // MARK: - Environment
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    // MARK: - Initializer
    init() {        
        let browserViewModel = BrowserViewModel.shared
        let webViewModel = WebViewModel(tab: browserViewModel.selectedTab)
        webViewModel.onOpenNewTab = { [weak webViewModel] url in
            let newTab = browserViewModel.addNewTab(url: url)
            webViewModel?.importTab(tab: newTab)
            webViewModel?.load(url)
            browserViewModel.saveTabs()
        }
        
        webViewModel.onTabStateChanged = {
            browserViewModel.saveTabs()
        }
        
        let bridgeViewModel = BridgeViewModel(browserViewModel: browserViewModel, webViewModel: webViewModel)
        
        webViewModel.bridge = bridgeViewModel
        browserViewModel.bridge = bridgeViewModel
                
        _browserViewModel = StateObject(wrappedValue: browserViewModel)
        _webViewModel = StateObject(wrappedValue: webViewModel)
        _bridgeViewModel = StateObject(wrappedValue: bridgeViewModel)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
            // MARK: - MAIN VIEW
                VStack(spacing: 0) {
                    if !isPortraitMode {
                        VStack{}
                        .frame(height: isSimpleToolbar ? 0 : 60 + geometry.safeAreaInsets.top)
                        .offset(y: isSimpleToolbar ? -60 - geometry.safeAreaInsets.top : 0)
                    }
                    ZStack(alignment: .top) {
                        if isPortraitMode {
                            if !browserViewModel.currentUrl.isEmpty {
                                VStack{}
                                    .frame(width: geometry.size.width, height: geometry.safeAreaInsets.top)
                                    .background(webViewModel.backgroundColor == .clear ? Color(UIColor.systemBackground) : webViewModel.backgroundColor)
                                    .edgesIgnoringSafeArea(.top)
                                    .zIndex(2)
                            }
                        }
                                                
                        
                        if browserViewModel.currentUrl.isEmpty {
                            WelcomeView()
                                .environmentObject(webViewModel)
                        } else {
                            browserViewModel.selectedWebView
                                .id(browserViewModel.selectedTab.id)
                                .animation(.easeInOut, value: dragOffset.width)
                                .zIndex(1)
                                .transition(.move(edge: .trailing))
                                .blur(radius: isTabViewVisible || isTabTransitionActive ? 3 : 0)
                        }
                        
                        if isUrlEditViewVisible {
                            urlEditBookmarkView
                                .zIndex(3)
                        }
                                                                                                      
                        VStack {
                            Spacer()
                            if isImageBasketVisible {
                                ImageBasketView(parent: self, img_tag: img_tag)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                                
                            }
                        }
                        .zIndex(9)
                        .padding(.bottom, 20)
                    }                    
                    .background(Color.clear)
                    .edgesIgnoringSafeArea(.bottom)
                                   
                    if isPortraitMode {
                        VStack(spacing: 0) {
                            if isSimpleToolbar {
                                SimpleToolBar(parent: self, isKeyboardOpen: isKeyboardOpen)
                                    .edgesIgnoringSafeArea(.bottom)
                            } else {
                                BrowserToolbar(parent: self, urlText: $urlText)
                                    .edgesIgnoringSafeArea(.bottom)
                                    .transition(.move(edge: .bottom).combined(with: .opacity))
                            }
                        }
                        .background(.clear)
                        .background(VisualEffectBlur(blurStyle: .systemChromeMaterial))
                        .edgesIgnoringSafeArea(.horizontal)
                    }
                    
                }
                .padding(.bottom, -geometry.safeAreaInsets.bottom)
                .background(webViewModel.backgroundColor)
                .sheet(isPresented: $isBookmarkViewVisible) {
                    bookmarkView
                        .presentationDetents([.medium, .large])
                        .presentationDragIndicator(.visible)
                        .ignoresSafeArea(.all)
                }
                .onAppear {
                    NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notification in
                        if !isSDViewVisible {
                            simplifyToolbar()
                            withAnimation{
                                isKeyboardOpen = true
                            }
                        }
                    }
                    NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
                        if !isSDViewVisible {
                            withAnimation(.bouncy){
                                isKeyboardOpen = false
                            }
                            materializeToolbar()
                        }
                    }
                    NotificationCenter.default.addObserver(forName: .imageLongPress, object: nil, queue: .main) { notification in
                        self.handleImageLongPress(notification: notification)
                    }
                    NotificationCenter.default.addObserver(forName: .imageClick, object: nil, queue: .main) { notification in
                        self.handleImageClick(notification: notification)
                    }
                    
                    if browserViewModel.selectedTab.title.isEmpty {
                        webViewModel.load(browserViewModel.selectedTab.url)
                    }
                }
                .onDisappear {
                    NotificationCenter.default.removeObserver(self, name: .imageLongPress, object: nil)
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        reImportTab()
                    }
                }.onChange(of: geometry.size) {
                    oldValue, newValue in
                    if isBookmarkViewVisible || isHorizontalBookmarkViewVisible {
                        if isPortraitMode {
                            isBookmarkViewVisible = true
                            isHorizontalBookmarkViewVisible = false
                        }else {
                            isBookmarkViewVisible = false
                            isHorizontalBookmarkViewVisible = true
                        }
                    }
                }
            }.blur(radius: isMenuSwitcherVisible ? 8 : 0, opaque: false)
            // MARK: - END MAIN VIEW
               
            if !isPortraitMode {
                VStack(spacing: 0) {
                    BrowserHorizontalToolbar(parent: self, topSafeArea: geometry.safeAreaInsets.top, urlText: $urlText)
                    .frame(maxWidth: .infinity)
                    .frame(height: isSimpleToolbar ? 0 : 60 + geometry.safeAreaInsets.top)
                    .offset(y: isSimpleToolbar ? -60 - geometry.safeAreaInsets.top : 0)
//                    .background(Color(UIColor.secondarySystemBackground))
                    .background(VisualEffectBlur(blurStyle: .systemChromeMaterial))
                    Spacer()
                }.edgesIgnoringSafeArea(.all)
            }
            
            VStack {
                if isTabViewVisible {
                    BrowserTabView(parent: self, isTabVisibleForAnimation: isTabVisibleForAnimation)
                        .environmentObject(browserViewModel)
                        .environmentObject(webViewModel)
                        .padding(.bottom, -8)
                        .background(Color.clear)
                        .edgesIgnoringSafeArea(.all)
                }
            }
            
            VStack {
                if isUrlEditViewVisible {
                    UrlEditView(parent: self)
                        .transition(.opacity)
                        .animation(.easeInOut, value: isUrlEditViewVisible)
                }
            }
            
            // MARK: - Dialogs
            VStack {                
                if isErrorViewVisible {
                    ErrorView(errorMessage: webViewModel.errorMessage, retryAction: {
                        hideErrorView()
                        webViewModel.retryLoading()
                    })
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
                    .background(VisualEffectBlur(blurStyle: .systemUltraThinMaterial))
                    .onTapGesture {
                        hideErrorView()
                    }
                    .zIndex(4)
                    .padding(.bottom, -8)
                    .edgesIgnoringSafeArea(.all)
                }
            }
            
            ZStack {
                if isHorizontalBookmarkViewVisible {
                    Rectangle()
                        .fill(Color.black.opacity(0.2))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .transition(.opacity)
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture{
                            hideBookmarkView()
                        }
                    HStack {
                        bookmarkView
                            .frame(width: 350)
                            .offset(x: horizontalBookmarkViewOffset.width)
                            .simultaneousGesture(
                                DragGesture()
                                    .onChanged { gesture in
                                        horizontalBookmarkViewOffset = gesture.translation
                                        if horizontalBookmarkViewOffset.width > 0 {
                                            horizontalBookmarkViewOffset.width = 0
                                        }
                                    }
                                    .onEnded { _ in
                                        if horizontalBookmarkViewOffset.width < -100 {
                                            hideBookmarkView()
                                        } 
                                        withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.6, blendDuration: 0.25)) {
                                            horizontalBookmarkViewOffset = .zero
                                        }
                                    }
                            )
                        Spacer()
                    }.transition(.move(edge: .leading))
                }
            }
            
            VStack {
                BrowserFloatingButton(parent: self, isVisible: $isFloatingButtonVisible)
            }
        }
        .onChange(of: browserViewModel.selectedTab) { oldTab, tab in webViewModel.importTab(tab: tab) }
        .onChange(of: browserViewModel.currentTitle) { oldTitle, newTitle in urlText = newTitle }
        .onReceive(webViewModel.$onScrollUp, perform: onScrollUp)
        .onReceive(webViewModel.$onScrollDown, perform: onScrollDown)
        .onReceive(webViewModel.$triggerShowErrorView, perform: onReceiveTriggerShowErrorView)
        .onChange(of: browserViewModel.imageForInject) { oldValue, newValue in 
            if browserViewModel.imageForInject != nil {
                injectImage()
            }
        }
        .onChange(of: MenuService.shared.triggerReimportTab) {
            oldValue, value in
            reImportTab()
        }
    }
    
    // MARK: - Views
    internal var urlEditBookmarkView: some View {
        BookmarkView(parent: self, isSwipeActionEnabled: false)
            .environmentObject(browserViewModel)
            .environmentObject(webViewModel)
            .padding(.bottom, -8)
    }
    
    internal var bookmarkView: some View {
        BookmarkView(parent: self, isSwipeActionEnabled: true)
            .environmentObject(browserViewModel)
            .environmentObject(webViewModel)
            .padding(.bottom, -8)
    }
    
    func reImportTab() {
        webViewModel.importTab(tab: browserViewModel.selectedTab)
    }
    
    // MARK: - Methods
    func onScrollUp(newValue: Bool) {
        if newValue {
            materializeToolbar()
        }
        hideImageBasket()
    }
    
    func onScrollDown(newValue: Bool) {
        if newValue {
            simplifyToolbar()
        }
        hideImageBasket()
    }
    
    func simplifyToolbar() {
        withAnimation(.bouncy) {
            isSimpleToolbar = true
        }
    }    
    
    
    func onReceiveTriggerShowErrorView(recieved: Bool) {
        if recieved {
            let url = browserViewModel.selectedWKWebView.url?.absoluteString ?? ""
            browserViewModel.selectedTab.url = url
            browserViewModel.selectedTab.title = StringUtils.abbreviateUrl(urlString: url)
            showErrorView()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                if isErrorViewVisible {
                    print(browserViewModel.selectedTab.url)
                    print(browserViewModel.selectedTab.title)
                    hideErrorView()
                }
            }
        }
    }
    
    func materializeToolbar() {
        withAnimation(.bouncy) {
            isSimpleToolbar = false
        }
    }
        
    
    func showBookmarkView() {
        withAnimation {
            if isPortraitMode {
                isBookmarkViewVisible = true
            }else {
                isHorizontalBookmarkViewVisible = true
            }
        }
    }
    
    func hideBookmarkView() {
        materializeToolbar()
        withAnimation {
            isBookmarkViewVisible = false
            isHorizontalBookmarkViewVisible = false
        }
    }

    func showTabView() {
        withAnimation {
            isTabViewVisible = true
        }
        if !browserViewModel.currentUrl.isEmpty {
            browserViewModel.selectedWKWebView.takeSnapshot(with: nil) { image, error in
                if let image = image {
                    DispatchQueue.global(qos: .userInteractive).asyncAfter(deadline: .now() + 0.2) {
                        let currentSnapshot = image.pngData()?.base64EncodedString()
                        browserViewModel.selectedTab.snapshot = currentSnapshot
                        browserViewModel.selectedTab.snapshot_id = UUID()
                        DispatchQueue.main.async {
                            withAnimation(.bouncy) {
                                isTabVisibleForAnimation = true
                            }
                        }
                    }
                }
            }
        }else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.bouncy) {
                    isTabVisibleForAnimation = true
                }
            }
        }
    }

    func hideTabView() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isTabVisibleForAnimation = false
            isTabViewVisible = false
        }
    }
    
    func showSDView() {
        browserViewModel.imageFromBrowser = nil
        browserViewModel.imageId = nil
        browserViewModel.imageSrc = nil
        img_tag = nil
        if !browserViewModel.currentUrl.isEmpty {
            browserViewModel.selectedWKWebView.takeSnapshot(with: nil) { image, error in
                if let image = image {
                    browserViewModel.imageFromBrowser = image
                    MenuService.shared.switchMenu(to: MenuService.shared.menus[1])
                }
            }
        }else {
            withAnimation {
                isSDViewVisible = true
            }
        }
    }
    
    func showSDView(with image: UIImage?) {
        if let baseImage = image {
            browserViewModel.imageFromBrowser = baseImage
        }
        MenuService.shared.switchMenu(to: MenuService.shared.menus[1])
    }
    
    
    func hideSDView() {
        MenuService.shared.switchMenu(to: MenuService.shared.menus[0])
    }

    func showUrlEditView() {
        withAnimation {
            isUrlEditViewVisible = true
        }
    }

    func hideUrlEditView() {
        withAnimation {
            isUrlEditViewVisible = false
        }
    }
        

    func snapshotView<T: View>(_ view: T, size: CGSize) -> UIImage? {
        let controller = UIHostingController(rootView: view)
        let view = controller.view
        
        let targetSize = CGSize(width: size.width, height: size.height)
        view?.bounds = CGRect(origin: .zero, size: targetSize)
        view?.backgroundColor = .clear

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        
        return renderer.image { _ in
            view?.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }

    
    func showErrorView() {
        withAnimation {
            isErrorViewVisible = true
        }
    }
    
    func hideErrorView() {
        withAnimation {
            isErrorViewVisible = false
        }
    }
    
    func handleImageLongPress(notification: Notification) {
        withAnimation(.bouncy) {
            isImageBasketVisible = true
        }
        if let userInfo = notification.userInfo,
            let imageId = userInfo["imageId"] as? String,
            let elementHTML = userInfo["elementHTML"] as? String,
            let imageSrc = userInfo["imageSrc"] as? String{
                browserViewModel.imageId = imageId
                browserViewModel.imageSrc = imageSrc
                img_tag = elementHTML
        }
    }
    
    func handleImageClick(notification: Notification) {
        if let userInfo = notification.userInfo,
            let imageId = userInfo["imageId"] as? String,
            let elementHTML = userInfo["elementHTML"] as? String,
            let imageSrc = userInfo["imageSrc"] as? String{
            browserViewModel.imageId = imageId
            browserViewModel.imageSrc = imageSrc
            img_tag = elementHTML
            if imageSrc.contains("http://") {
                withAnimation(.bouncy) {
                    isImageBasketVisible = true
                }
            }
            else {
                checkImageUrl(imageSrc) { image in
                    if image != nil {
                        DispatchQueue.main.async{
                            BrowserViewModel.shared.imageFromBrowser = image
                            OverlayService.shared.showOverlaySpinner()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                showSDView(with: nil)
                                OverlayService.shared.hideOverlaySpinner()
                            }
                        }
                    }
                }
            }
        }
    }
    
    func checkImageUrl(_ urlString: String, completion: @escaping (UIImage?) -> Void) {
        print(urlString)
        if urlString.contains("data:image") {
            let base64 = urlString.replacingOccurrences(of: "src=\"", with: "")
            .replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: "data:image/png;base64,", with: "")
            .replacingOccurrences(of: "data:image/jpeg;base64,", with: "")
            .replacingOccurrences(of: "data:image/jpg;base64,", with: "")
            .replacingOccurrences(of: "data:image/gif;base64,", with: "")
            .replacingOccurrences(of: "data:image/webp;base64,", with: "")
            downloadImageBase64(from: base64) {
                result in completion(result)
            }
        }
        else {
            if let imageUrl = URL(string: urlString) {
                downloadImage(from: imageUrl) {
                    completion($0)
                }
            }
        }
    }
        
    func downloadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, let image = UIImage(data: data) {
                completion(image)
            }else {
                completion(nil)
            }
        }.resume()
    }
    
    func downloadImageBase64(from base64: String, completion: @escaping (UIImage?) -> Void) {
        if let data = Data(base64Encoded: base64) {
            if let image = UIImage(data: data) {
                completion(image)
            }else {
                completion(nil)
            }
        }else {
            completion(nil)
        }
    }

    
    func hideImageBasket() {
        withAnimation(.bouncy) {
            isImageBasketVisible = false
        }
    }
    
    func injectImage() {
        if let img_id = browserViewModel.imageId, let screenshot = browserViewModel.imageForInject {
            browserViewModel.InjectImage(img_id: img_id, baseImage: screenshot)
        }
        OverlayService.shared.hideOverlaySpinner()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            reImportTab()
        }
    }
    
}

extension BrowserView {
    private func fetchImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }
            
            let image = UIImage(data: data)
            completion(image)
        }.resume()
    }
}

