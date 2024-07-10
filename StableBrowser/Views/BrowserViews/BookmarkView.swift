import SwiftUI
import WebKit

struct BookmarkView: View {
    var parent: BrowserView
    var isSwipeActionEnabled: Bool
    @EnvironmentObject var browserViewModel: BrowserViewModel
    @EnvironmentObject var webViewModel: WebViewModel
    
    var body: some View {
            GeometryReader { geometry in
                VStack(spacing: 0){
                    if isSwipeActionEnabled {
                        HStack{
                            Text("BOOKMARKS").font(.title3).fontWeight(.semibold)
                                .foregroundColor(.primary.opacity(0.8))
                        }.padding(.top, 40)
                    }
                    
                    Form {
                        ForEach(browserViewModel.bookmarks) { bookmark in
                            BookmarkItemView(bookmark: bookmark, parent: parent)
                                .modifier(SwipeActionModifier(isEnabled: isSwipeActionEnabled, deleteAction: {
                                    self.deleteBookmark(at: bookmark)
                                }))
                        }
                        .onMove(perform: moveBookmark)
                    }
                }.background(Color(UIColor.systemGroupedBackground))
            }
            .onAppear(perform : UIApplication.shared.hideKeyboard)
    }
    
    func deleteBookmark(at offsets: IndexSet) {
        offsets.forEach { index in
            let bookmark = browserViewModel.bookmarks[index]
            browserViewModel.deleteBookmark(url: bookmark.url)
        }
        browserViewModel.saveBookmarks()
    }
    
    func deleteBookmark(at bookmark: Bookmark) {
        withAnimation(.bouncy) {
            browserViewModel.deleteBookmark(url: bookmark.url)
        }
        browserViewModel.saveBookmarks()
    }
    
    func moveBookmark(from source: IndexSet, to destination: Int) {
        browserViewModel.bookmarks.move(fromOffsets: source, toOffset: destination)
        browserViewModel.saveBookmarks()
    }
}

struct SwipeActionModifier: ViewModifier {
    var isEnabled: Bool
    let deleteAction: () -> Void

    func body(content: Content) -> some View {
        if isEnabled {
            content
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive, action: deleteAction) {
                        Label("Delete", systemImage: "trash")
                    }
                }
        } else {
            content
        }
    }
}


struct BookmarkItemView: View {
    var bookmark: Bookmark
    var parent: BrowserView
    @EnvironmentObject var webViewModel: WebViewModel
    
    var body: some View {
        Button {
            webViewModel.load(bookmark.url)
            parent.hideBookmarkView()
            parent.hideUrlEditView()
        } label: {
            HStack {
                getFaviconImage(favicon: bookmark.favicon)
                    .resizable()
                    .frame(width: 30, height: 30)
                
                VStack {
                    HStack {
                        Text(bookmark.title)
                            .lineLimit(1)
                        Spacer()
                    }
                    HStack {
                        Text(bookmark.url)
                            .lineLimit(1)
                            .font(.caption)
                        Spacer()
                    }
                }
                Spacer()
            }
            .foregroundColor(Color.primary)
            .truncationMode(.tail)
            .contentShape(Rectangle())
            .padding(.vertical, 5)
        }

        
    }
    
    private func getFaviconImage(favicon: String) -> Image {
        if favicon.isEmpty {
            return Image(systemName: "globe")
        }
        
        if let data = Data(base64Encoded: favicon) {
            if let uiImage = UIImage(data: data) {
                return Image(uiImage: uiImage)
            }
        }
        
        return Image(systemName: "globe")
    }
}
