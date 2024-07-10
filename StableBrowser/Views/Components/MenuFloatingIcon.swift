import SwiftUI

struct MenuFloatingIcon: View {
    @StateObject var menuService = MenuService.shared
    @State var minHeight: CGFloat
    @State var maxHeight: CGFloat
    @State var minWidth: CGFloat
    @State var maxWidth: CGFloat
    
    @State var offset: CGSize = .zero
    @State var isExpanded: Bool = false
    @State var movePoint: CGFloat = 0
    @State var buttonSize: CGFloat = 65
    
    @State var distance: CGFloat = 0
    @State var maxDistance: CGFloat = 0
    @State var labelVisibility: Bool = false

    var isPortraitMode: Bool {
        get {
            return UIScreen.main.bounds.width < UIScreen.main.bounds.height
        }
    }
    
    init() {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        self.minHeight = -(screenHeight * 0.4)
        self.maxHeight = (screenHeight * 0.4)
        if UIScreen.main.bounds.width < UIScreen.main.bounds.height {
            self.minWidth = screenWidth / 2 - 60
            self.maxWidth = screenWidth / 2
        }else {
            self.minWidth = screenWidth / 2 - 100
            self.maxWidth = screenWidth / 2 - 100
        }
        updateLabelVisibility()
    }
    
    private func updateLabelVisibility() {
        let maximumDistance = isPortraitMode ? 0.5 : 0.3
        if distanceHeight > maximumDistance {
            withAnimation {
                labelVisibility = false
            }
        }else {
            withAnimation {
                labelVisibility = true
            }
        }
    }
    
    private func updateDimensions() {
        HideButton()
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        self.minHeight = -(screenHeight * 0.4)
        self.maxHeight = (screenHeight * 0.4)
        if isPortraitMode {
            self.minWidth = screenWidth / 2 - 60
            self.maxWidth = screenWidth / 2
            offset = CGSize(width: maxWidth, height: maxHeight - (maxHeight - minHeight) / 2)
        }else {
            self.minWidth = screenWidth / 2 - 100
            self.maxWidth = screenWidth / 2 - 100
            offset = CGSize(width: maxWidth, height: maxHeight - (maxHeight - minHeight) / 4)
        }
        updateLabelVisibility()
    }
        
    var adjustButtonSize: CGFloat {
        get {
            let middle = maxHeight - (maxHeight - minHeight) / 2
            let current = offset.height
            let distance = abs(middle - current)
            let maxDistance = (maxHeight - minHeight) / 2
            return 20 - (distance / maxDistance * 20)
        }
    }
    
    var distanceHeight: CGFloat {
        get {
            let middle = maxHeight - (maxHeight - minHeight) / 2
            let current = offset.height
            let distance = abs(middle - current)
            let maxDistance = (maxHeight - minHeight) / 2
            return distance / maxDistance
        }
    }
    
    var distanceWidth: CGFloat {
        get {
            let current = offset.width

            // Calculate the distance from the center
            let distance = abs(maxWidth - current)

            // Calculate the maximum distance that can be moved
            let maxDistance = (maxWidth - minWidth)
            return (distance / maxDistance)
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ZStack {
                    RadialGradient(gradient: Gradient(colors: [Color.white, Color.clear]), center: .trailing, startRadius: 5, endRadius: 500)
                        .edgesIgnoringSafeArea(.all).opacity(0.9)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .edgesIgnoringSafeArea(.all)
                .background(VisualEffectBlur(blurStyle: .systemUltraThinMaterial))
                .onTapGesture {
                    HideButton()
                }
                .opacity(isExpanded ? 1 : 0)
                
                floatingButton
                    .opacity(menuService.isFloaingMenuButtonVisible ? 1 : 0)
                    .offset(offset)
                    .onAppear{
                        if isPortraitMode {
                            offset = CGSize(width: maxWidth, height: maxHeight - (maxHeight - minHeight) / 2)
                        }else {
                            offset = CGSize(width: maxWidth, height: maxHeight - (maxHeight - minHeight) / 4)
                        }
                    }
            }
            .edgesIgnoringSafeArea(.all)
            .onChange(of: geometry.size) { oldValue, newValue in
                updateDimensions()
            }
            .opacity(menuService.isFloaingMenuButtonVisible ? 1 : 0)
        }
    }
    
    private var floatingButton: some View {
        ZStack {
            if isPortraitMode {
                PortraitfloatingButton
            }else {
                HorizontalfloatingButton
            }
        }
        .background {
            ZStack {
                ForEach(MenuService.shared.menus) { menu in
                    ActionView(menu)
                        .opacity(isPortraitMode ? distanceWidth : (isExpanded ? 1 : 0))
                        .frame(width: buttonSize, height: buttonSize)
                }
            }
        }
    }
    
    private var PortraitfloatingButton: some View {
        HStack(spacing:0) {
            Image(systemName: isExpanded ? "xmark" : "arrowshape.left.fill")
                .font(.system(size: 15 + (10 - (distanceHeight * 10)) + (distanceWidth / 1 * 15)))
                .foregroundColor(Color.white).opacity(1)
            Spacer().frame(width: 30 - (movePoint > 30 ? 30 : movePoint) + (isExpanded ? 0 : (10 - (distanceHeight * 10))))
        }
        .frame(width: buttonSize + adjustButtonSize, height: buttonSize + adjustButtonSize)
        .background(Color.black).opacity(0.5)
        .clipShape(Circle())
        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.easeInOut, value: MenuService.shared.selectedMenu)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    // Change the offset (from the initial position to -100)
                    let minWidth_minus_10 = minWidth - 10
                    var newoffset = CGSize(width: offset.width + value.translation.width, height: offset.height + value.translation.height)
                    if newoffset.width < minWidth_minus_10 {
                        newoffset.width = minWidth_minus_10
                    }else if newoffset.width > maxWidth {
                        newoffset.width = maxWidth
                    }
                    if newoffset.height < minHeight {
                        newoffset.height = minHeight
                    }else if newoffset.height > maxHeight {
                        newoffset.height = maxHeight
                    }
                    offset = newoffset
                    movePoint = (maxWidth - offset.width) / 2
                    updateLabelVisibility()
                }
                .onEnded { value in
                    if movePoint > 15 {
                        withAnimation{
                            offset.width = minWidth
                            movePoint = 30
                            isExpanded = true
                        }
                    } else {
                        withAnimation{
                            offset.width = maxWidth
                            movePoint = 0
                            isExpanded = false
                        }
                    }
                }
        )
        .simultaneousGesture(TapGesture().onEnded {
            if isExpanded {
                HideButton()
            }else {
                ExpandButton()
            }
        })
    }
    
    private var HorizontalfloatingButton: some View {
        HStack(spacing:0) {
            Image(systemName: isExpanded ? "xmark" : "line.3.horizontal")
                .font(.system(size: 25))
                .foregroundColor(Color.white).opacity(1)
        }
        .frame(width: buttonSize, height: buttonSize)
        .background(Color.black).opacity(0.5)
        .clipShape(Circle())
        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.easeInOut, value: MenuService.shared.selectedMenu)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    // Change the offset (from the initial position to -100)
                    var newoffset = CGSize(width: offset.width , height: offset.height + value.translation.height)
                    
                    if newoffset.height < minHeight {
                        newoffset.height = minHeight
                    }else if newoffset.height > maxHeight {
                        newoffset.height = maxHeight
                    }
                    offset = newoffset
                    updateLabelVisibility()
                }
            )
        .simultaneousGesture(TapGesture().onEnded {
            if isExpanded {
                HideButton()
            }else {
                ExpandButton()
            }
        })
    }

    /// Action View
    @ViewBuilder
    private func ActionView(_ menu: Menu) -> some View {
        Button {
            HideButton()
            SwitchMenu(to: menu)
            if menu.name == "browser" {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    MenuService.shared.triggerReimportTab.toggle()
                }
            }
        } label: {
            Image(menu.imageName)
                .resizable()
                .frame(width: buttonSize + adjustButtonSize, height: buttonSize + adjustButtonSize)
                .contentShape(.circle)
                .clipShape(.circle)
                .rotationEffect(.init(degrees: -1.0 * progressAngle(menu)))
                .overlay {
                    Text(menu.name.capitalized)
                        .opacity(isExpanded && labelVisibility ? 1 : 0)
                        .font(.footnote)
                        .foregroundColor(.black)
                        .fontWeight(.semibold)
                        .padding(.top, 85 + adjustButtonSize)
                        .rotationEffect(.init(degrees: -1.0 * progressAngle(menu)))
                }
            
        }
        .offset(x: -menuOffset / 2.2)
        .rotationEffect(.init(degrees: progressAngle(menu)))
    }
    
    private func progressAngle(_ menu: Menu) -> Double {

        let middle = maxHeight - (maxHeight - minHeight) / 2
        let current = offset.height

        // Calculate the distance from the center
        let distance = abs(middle - current)

        // Calculate the maximum distance that can be moved
        let maxDistance = (maxHeight - minHeight) / 2
        
        // Check if the current position is below the center
        let isBottom = current > middle
        
        // Calculate A by subtracting the distance from 180 to make it a maximum of 90
        let A = 180 - distance / maxDistance * 90
        let B: CGFloat = isBottom ?  90 - distance / maxDistance * 90 : 90
        
        var rst = progress(menu) * A
        rst -= B
        
        return rst
    }
    
    func ExpandButton() {
        if isPortraitMode {
            withAnimation {
                isExpanded = true
                movePoint = 30
                offset.width = offset.width - 60
            }
        }else {
            withAnimation {
                isExpanded = true
            }
        }
    }
    
    func HideButton() {
        if isPortraitMode {
            withAnimation {
                isExpanded = false
                movePoint = 0
                offset.width = maxWidth
            }
        }
        else {
            withAnimation {
                isExpanded = false
            }
        }
    }
    
    func SwitchMenu(to menu: Menu) {
        MenuService.shared.switchMenu(to: menu)
    }

    private var menuOffset: CGFloat {
        if isPortraitMode {
            let buttonSize = buttonSize + 10 + adjustButtonSize
            return Double(MenuService.shared.menus.count) * (MenuService.shared.menus.count == 1 ? buttonSize * 2 : (MenuService.shared.menus.count == 2 ? buttonSize * 1.25 : buttonSize)) * distanceWidth
        }
        else {
            let buttonSize = buttonSize + 5
            return Double(MenuService.shared.menus.count) * (MenuService.shared.menus.count == 1 ? buttonSize * 2 : (MenuService.shared.menus.count == 2 ? buttonSize * 1.25 : buttonSize)) * (isExpanded ? 1 : 0)
        }
    }

    private func progress(_ menu: Menu) -> CGFloat {
        let index = CGFloat(MenuService.shared.menus.firstIndex(where: { $0.id == menu.id }) ?? 0)
        return MenuService.shared.menus.count == 1 ? 1 : (index / CGFloat(MenuService.shared.menus.count - 1))
    }
}

