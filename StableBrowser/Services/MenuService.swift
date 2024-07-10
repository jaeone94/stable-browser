import Foundation
import SwiftUI

class MenuService: ObservableObject {
    static let shared = MenuService()
    
    @Published var isMenuSwitcherVisible = false
    @Published var selectedMenu: Menu
    @Published var triggerReimportTab: Bool = false
    
    @Published var isFloaingMenuButtonVisible: Bool = true
    
    var menus: [Menu] = [
        Menu(name: "browser", imageName: "Menu 1"),
        Menu(name: "Img2Img", imageName: "Menu 2"),
        Menu(name: "Txt2Img", imageName: "Menu 3"),
        Menu(name: "gallery", imageName: "Menu 4"),
        Menu(name: "settings", imageName: "Menu 5")
    ]
    
    init() {
        self.selectedMenu = menus[0]
    }
    
    public func showMenuSwitcher() {
        isMenuSwitcherVisible = true
    }
    
    public func hideMenuSwitcher() {
        withAnimation {
            isMenuSwitcherVisible = false
        }
    }
    
    public func switchMenu(to menu: Menu) {
        withAnimation {
            selectedMenu = menu
        }
    }
    
}
