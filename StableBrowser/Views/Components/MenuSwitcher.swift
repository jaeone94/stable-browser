import Foundation
import SwiftUI

class Menu: Identifiable, Equatable {
    static func == (lhs: Menu, rhs: Menu) -> Bool {
        return lhs.id == rhs.id
    }
    
    let id = UUID()
    let name: String
    let imageName: String
    
    init(name: String, imageName: String) {
        self.name = name
        self.imageName = imageName
    }
}


struct MenuSwitcher: View {
    var currentMenu: Menu
    @State private var activeID: UUID?

    
    var body: some View {
        ZStack {
            ZStack {
                RadialGradient(gradient: Gradient(colors: [Color.white, Color.clear]), center: .bottom, startRadius: 5, endRadius: 500)
                    .edgesIgnoringSafeArea(.all).opacity(0.9)
            }
            .edgesIgnoringSafeArea(.all)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(VisualEffectBlur(blurStyle: .systemUltraThinMaterial))
            .onTapGesture {
                let selectedMenu =  getActiveMenu()
                MenuService.shared.hideMenuSwitcher()
                switchMenu(to: selectedMenu)
                
                if selectedMenu.name == "browser" {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        MenuService.shared.triggerReimportTab.toggle()
                    }
                }
                
                withAnimation {
                    MenuService.shared.isFloaingMenuButtonVisible = true
                }
            }
            .onAppear {
                withAnimation {
                    MenuService.shared.isFloaingMenuButtonVisible = false
                }
            }

            VStack {
                Spacer()
                GeometryReader { proxy in
                    let size = proxy.size
                    let padding = (size.width - 70) / 2
                    
                    ZStack {
                        /// Circular Slider
                        ScrollView(.horizontal) {
                                HStack(spacing: 35) {
                                    ForEach(reorderedMenus(), id: \.id) { menu in
                                        VStack {
                                            Spacer()
                                            Image(menu.imageName)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 70, height: 70)
                                                .clipShape(.circle)
                                            /// Shadow
                                                .shadow(color: .black.opacity(0.15), radius: 5, x: 5, y: 5)
                                                .visualEffect { view, subProxy in
                                                    view
                                                        .offset(y: offset(subProxy))
                                                    /// Option - 2:2
                                                        .scaleEffect(1 + (scale(subProxy) / 2))
                                                    /// Option - 1:2
                                                        .offset(y: scale(subProxy) * 15)
                                                }
                                                .padding(.bottom, 70)
                                        }
                                        .onTapGesture {
                                            MenuService.shared.hideMenuSwitcher()
                                            switchMenu(to: menu)
                                            if menu.name == "browser" {
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                                    MenuService.shared.triggerReimportTab.toggle()
                                                }
                                            }
                                            withAnimation {
                                                MenuService.shared.isFloaingMenuButtonVisible = true
                                            }
                                        }
                                    }
                                }
                                .onTapGesture {
                                    let selectedMenu =  getActiveMenu()
                                    MenuService.shared.hideMenuSwitcher()
                                    switchMenu(to: selectedMenu)
                                    
                                    if selectedMenu.name == "browser" {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                            MenuService.shared.triggerReimportTab.toggle()
                                        }
                                    }
                                    withAnimation {
                                        MenuService.shared.isFloaingMenuButtonVisible = true
                                    }
                                }
                                .frame(height: size.height)
                                .offset(y: -30)
                                .scrollTargetLayout()
                        }
                        .scrollPosition(id: $activeID)
                        .safeAreaPadding(.horizontal, padding)
                        .scrollIndicators(.hidden)
                        /// Snapping
                        .scrollTargetBehavior(.viewAligned)
                        .frame(height: size.height)
                        .onTapGesture {
                            let selectedMenu =  getActiveMenu()
                            MenuService.shared.hideMenuSwitcher()
                            switchMenu(to: selectedMenu)
                            
                            if selectedMenu.name == "browser" {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    MenuService.shared.triggerReimportTab.toggle()
                                }
                            }
                            withAnimation {
                                MenuService.shared.isFloaingMenuButtonVisible = true
                            }
                        }
                        VStack {
                            Spacer()
                            Text(activeMenuName()).font(.subheadline)
                                .foregroundColor(.black)
                        }.padding(.bottom, 40)
                    }
                }
                .frame(maxHeight: .infinity)
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
    
    func switchMenu(to menu: Menu) {
        MenuService.shared.switchMenu(to: menu)
    }
    
    func reorderedMenus() -> [Menu] {
        var reordered = MenuService.shared.menus.filter { $0.id != currentMenu.id }
        reordered.insert(currentMenu, at: 0)
        return reordered
    }
    
    func activeMenuName() -> String {
        if let activeID = activeID,
           let activeMenu = reorderedMenus().first(where: { $0.id == activeID }) {
            return activeMenu.name.capitalized
        }
        return currentMenu.name.capitalized
    }
    
    func getActiveMenu() -> Menu {
        if let activeID = activeID,
           let activeMenu = reorderedMenus().first(where: { $0.id == activeID }) {
            return activeMenu
        }
        return currentMenu
    }
    
    func offset(_ proxy: GeometryProxy) -> CGFloat {
        let progress = progress(proxy)
        /// Simply Moving View Up/Down Based on Progress
        return progress < 0 ? progress * -30 : progress * 30
    }
    
    func scale(_ proxy: GeometryProxy) -> CGFloat {
        let progress = min(max(progress(proxy), -1), 1)
        
        return progress < 0 ? 1 + progress : 1 - progress
    }
    
    func progress(_ proxy: GeometryProxy) -> CGFloat {
        /// View Width
        let viewWidth = proxy.size.width
        let minX = (proxy.bounds(of: .scrollView)?.minX ?? 0)
        return minX / viewWidth
    }
}
