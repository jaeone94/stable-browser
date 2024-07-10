import SwiftUI
import WebKit

struct BrowserTabView: View {
    var parent: BrowserView
    @EnvironmentObject var browserViewModel: BrowserViewModel
    @EnvironmentObject var webViewModel: WebViewModel
    var isTabVisibleForAnimation : Bool

    let tabCellHeight: CGFloat = 230
    
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
    
    func getTabCellWidth() -> CGFloat {
        let itemCount: CGFloat = isPortraitMode ? 2 : 4
        return (UIScreen.main.bounds.width - (isPortraitMode ? 0 : 40)) / itemCount - 40
    }
    
    func switchTab(tab: Tab) {
        parent.hideTabView()
        browserViewModel.switchTab(to: tab.id)
    }
    
    func switchTab(index: Int) {
        DispatchQueue.main.async {
            parent.hideTabView()
            browserViewModel.switchTab(to: browserViewModel.tabs[index].id)
        }
    }
    
    func deleteTab(at offsets: IndexSet) {
        for index in offsets {
            browserViewModel.deleteTab(at: index)
        }
    }
    
    private var TabToolBar: some View {
        VStack(spacing: 0){
            Rectangle()
                .foregroundColor(Color.clear)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
//                .background(VisualEffectBlur(blurStyle: .systemThinMaterial))
                .overlay(
                    Text("\(parent.browserViewModel.tabs.count == 0 ? 1 : parent.browserViewModel.tabs.count) Tabs")
                        .foregroundColor(.primary)
                        .font(.system(size: 18, weight: .regular))
                )
                .cornerRadius(14)
                .frame(height: 44)
                .padding(.horizontal, 35)
                .padding(.top, 9)
                .padding(.bottom, 4)
            
            GeometryReader { geometry in
                HStack {
                    Button(action: {
                        parent.hideTabView()
                        DispatchQueue.main.async {
                            withAnimation(.easeInOut(duration: 0.4)) {
                                parent.browserViewModel.addNewTab()
                            }
                        }
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 22))
                            .frame(width: geometry.size.width / 5, height: 40)
                    }
                    .foregroundColor(Color.blue)
                    
                    Spacer()
                    Button(action: parent.hideTabView) {
                        Image(systemName: "square.on.square")
                            .font(.system(size: 22))
                            .frame(width: geometry.size.width / 5, height: 40)
                            .foregroundColor(Color.blue)
                        
                    }
                }
            }.frame(height: 53)
                
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                GeometryReader { geometry in
                    let itemCount = isPortraitMode ? 2 : 4 // If in portrait mode, set itemCount to 2, otherwise set it to 4
                    let tabCellWidth = getTabCellWidth()
                    ScrollView {
                        if isTabVisibleForAnimation {
                            LazyVGrid(columns: Array(repeating: GridItem(), count: itemCount), spacing: 40) {
                                ForEach(browserViewModel.tabs, id: \.id) { tab in
                                    TabCellView(
                                        parent: self,
                                        tab: tab,
                                        onClose: {
                                            withAnimation {
                                                browserViewModel.deleteTab(tab: tab)
                                            }
                                        }
                                    ).id(tab.id)
                                    .onTapGesture {
                                        switchTab(tab: tab)
                                    }
                                    .frame(width: tabCellWidth, height: tabCellHeight)
                                    .padding(.horizontal)
                                    .transition(.move(edge: .leading).combined(with: .opacity))
                                }
                                .onDelete(perform: deleteTab)
                            }
                            .padding(.vertical)
                            .padding(.horizontal)
                            .animation(.bouncy, value: browserViewModel.tabs.count)
                        }
                    }
                }
                if isPortraitMode {
                    TabToolBar
                        .frame(height: 108)
                }
            }
            .onTapGesture {
                parent.hideTabView()
            }
            .background(TransparentBackground())
            .background(parent.browserViewModel.currentUrl.isEmpty ? Color(UIColor.systemBackground) : .clear)
            .navigationBarTitle("TABS")
        }
        .background(VisualEffectBlur(blurStyle: .systemUltraThinMaterial))
        .navigationViewStyle(.stack)
        .accentColor(.clear)
    }
}



private struct TabCellView: View {
    let parent: BrowserTabView
    let tab: Tab
    let onClose: () -> Void
    @State private var offset = CGSize.zero
    
    var body: some View {
        let tabCellWidth = parent.getTabCellWidth()
        let tabCellHeight = parent.tabCellHeight
        VStack(spacing:0) {
            ZStack(alignment: .bottomLeading) {
                if tab.url.isEmpty {
                    Rectangle()
                        .fill(Color(UIColor.secondarySystemBackground))
                        .frame(width: tabCellWidth, height: tabCellHeight)
                } else {
                    if let snapshot = tab.snapshot {
                        tabImage(from: snapshot)
                            .resizable()
                            .scaledToFill()
                            .frame(width: tabCellWidth, height: tabCellHeight)
                            .clipped()
                            
                    } else {
                        Rectangle()
                            .fill(Color(UIColor.secondarySystemBackground))
                            .frame(width: tabCellWidth, height: tabCellHeight)
                    }
                    titleBackground
                }
                
                if !(parent.browserViewModel.tabs.count == 1 && tab.url.isEmpty) {                    
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: onClose) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.black.opacity(0.8))
                                    .font(.system(size: 20))
                                    .padding(5)
                            }
                        }
                        Spacer()
                    }
                }
            }
            .frame(width: tabCellWidth, height: tabCellHeight)
            .cornerRadius(14)
            .padding(.bottom, 8)

            VStack(alignment: .leading, spacing: 4) {
                Text(tab.title.isEmpty ? "Empty Tab" : tab.title)
                    .font(.system(size: 15).bold())
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
        }
        .contentShape(Rectangle())
        .frame(width: tabCellWidth, height: tabCellHeight)
        .padding(.horizontal, 3)
        .padding(.vertical, 20)
        .offset(x: offset.width)
        .simultaneousGesture(
            DragGesture()
                .onChanged { gesture in
                    offset = gesture.translation
                    if offset.width > 0 {
                        offset.width = 0
                    }
                    
                    if parent.browserViewModel.tabs.count == 1 && tab.url.isEmpty && offset.width < -20 {
                        offset.width = -20
                    }
                    
                    if offset.width < -75 {
                        offset.width = -75
                    }
                }
                .onEnded { _ in
                    if offset.width < -60 {
                        onClose()
                    } else {
                        // with Animation and duration
                        withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.6, blendDuration: 0.25)) {
                            offset = .zero
                        }
                    }
                }
        )
        .opacity(Double(1 - abs(offset.width / 100)))
    }
    
    private var titleBackground: some View {
        Rectangle().fill(.black).opacity(0.1)
        .frame(height: parent.tabCellHeight)
    }
    
    private func tabImage(from snapshotBase64: String) -> Image {
        guard let data = Data(base64Encoded: snapshotBase64),
              let uiImage = UIImage(data: data) else {
            return Image(systemName: "photo")
        }
        return Image(uiImage: uiImage)
    }
}
