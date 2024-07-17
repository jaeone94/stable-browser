import SwiftUI

@main
struct StableBrowserApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject var menuService = MenuService.shared
    @StateObject var photoManagementService = PhotoManagementService.shared
    @StateObject var overlayService = OverlayService.shared
    @AppStorage("userAgreedToTerms") private var userAgreedToTerms = false
    
    var body: some Scene {
        WindowGroup {
            if userAgreedToTerms {
                mainContent
            } else {
                UserAgreementView()
            }
        }
    }
    
    @ViewBuilder
    var mainContent: some View {
        RootView {
            ZStack {
                switch menuService.selectedMenu.name {
                case "browser":
                    BrowserView()
                        .transition(.opacity)
                case "Img2Img":
                    StableImg2ImgView()
                case "Txt2Img":
                    StableTxt2ImgView()
                case "gallery":
                    GalleryView()
                        .transition(.opacity)
                case "settings":
                    NavigationView {
                        StableSettingsView()
                    }.navigationViewStyle(StackNavigationViewStyle())
                    .transition(.opacity)
                default:
                    EmptyView().background(Color.red)
//                            .transition(.opacity)
                }
                
                ZStack { // Global Dialogs
                    if photoManagementService.isNewAlbumDialogVisible {
                        Rectangle().fill(.black.opacity(0.5))
                            .frame(maxWidth:.infinity, maxHeight: .infinity)
                            .edgesIgnoringSafeArea(.all)
                        NewAlbumDialog()
                    }
                }
                .transition(.opacity)
                .animation(.easeInOut, value: photoManagementService.isNewAlbumDialogVisible)
                
                VStack {
                    Spacer()
                    if overlayService.isSpinnerVisible {
                        SpinnerView(isVisible: $overlayService.isSpinnerVisible).zIndex(9)
                            .edgesIgnoringSafeArea(.all)
                    }
                    Spacer()
                }
                .edgesIgnoringSafeArea(.all)
                .transition(.opacity)
                .animation(.easeInOut, value: overlayService.isSpinnerVisible)
                
                VStack {
                    if menuService.isMenuSwitcherVisible {
                        MenuSwitcher(currentMenu: menuService.selectedMenu)
                    }
                }
                .transition(.opacity)
                .animation(.easeInOut, value: menuService.isMenuSwitcherVisible)
            }.animation(.easeInOut, value: menuService.selectedMenu)
        }
        .overlay {
            VStack {
                MenuFloatingIcon()
            }
        }
        
    }
}
