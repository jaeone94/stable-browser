import SwiftUI

struct BrowserToolbar: View {
    // MARK: - Properties
    var parent: BrowserView
    @Binding var urlText: String
    @FocusState var isFocused: Bool
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                UrlTextBox
                if !parent.browserViewModel.currentUrl.isEmpty {
                    toolbarButtons
                }
            }
            .frame(height: 44)
            .padding(.vertical, 8)
            .onTapGesture {
                parent.showUrlEditView()
            }
                                    
            pageNavigationButtons
                .foregroundColor(.accentColor)
                .padding(.bottom, 48)
                .padding(.top, -4)
            
        }
    }
    
    // MARK: - Views
    
    private var UrlTextBox: some View {
        Group {
            GeometryReader { geometry in
                urlBar(geometry: geometry)
                progressBar(geometry: geometry)
            }
            .cornerRadius(14)
            .padding(.horizontal, 35)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            
            HStack {
                Spacer()
                Text(
                     parent.browserViewModel.currentUrl.isEmpty ? "Enter URL or Search..." :
                        parent.urlText.isEmpty ? parent.browserViewModel.currentTitle : parent.urlText)
                .foregroundColor(parent.browserViewModel.currentUrl.isEmpty ? .secondary : .primary)
                    .font(.system(size: 16))
                    .padding(.horizontal, 70)
                    .padding(.top, 10)
                    .padding(.bottom, 10)
                    .onTapGesture {
                        parent.showUrlEditView()
                    }
                Spacer()
            }
        }
    }
    
    private var toolbarButtons: some View {
        HStack {
            Button(action: parent.isBookmarked ? removeBookmark : addBookmark) {
                // If bookmarked, show filled yellow star, otherwise show blue outline star
                Image(systemName: parent.isBookmarked ? "star.fill" : "star")
                    .foregroundColor(.primary)
            }
            .padding(.leading, 50)
            
            Spacer()
            
            Button(action: refreshOrStopPage) {
                Image(systemName: parent.webViewModel.progress == 0.0 || parent.webViewModel.progress == 1.0 ? "arrow.clockwise" : "xmark")
                    .foregroundColor(.primary)
                    .transition(.opacity)
            }
            .padding(.trailing, 50)
        }
    }
    
    private var pageNavigationButtons: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                Button(action: parent.webViewModel.goBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 22))
                        .frame(width: geometry.size.width / 5, height: 40)
                }
                .disabled(!parent.webViewModel.canGoBack)
                .foregroundColor(parent.webViewModel.canGoBack ? .accentColor : .gray)
                
                Button(action: parent.webViewModel.goForward) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 22))
                        .frame(width: geometry.size.width / 5, height: 40)
                }
                .disabled(!parent.webViewModel.canGoForward)
                .foregroundColor(parent.webViewModel.canGoForward ? .accentColor : .gray)
                
                Button(action: {
                    if !parent.browserViewModel.currentUrl.isEmpty {
                        withAnimation(.bouncy) {
                            parent.isFloatingButtonVisible = true
                        }
                    }
                }) {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 27))
                        .frame(width: geometry.size.width / 5, height: 40)
                }                
                .foregroundColor(!parent.browserViewModel.currentUrl.isEmpty ? .accentColor : .gray)
                .disabled(parent.browserViewModel.currentUrl.isEmpty)
                                
                Button(action: parent.showBookmarkView) {
                    Image(systemName: "book")
                        .font(.system(size: 22))
                        .frame(width: geometry.size.width / 5, height: 40)
                }
                .foregroundColor(.accentColor)
                
                Button(action: parent.showTabView) {
                    Image(systemName: "square.on.square")
                        .font(.system(size: 22))
                        .frame(width: geometry.size.width / 5, height: 40)
                        .foregroundColor(.accentColor)                    
                }
            }
        }
        .frame(height: 30)
    }
    
    // MARK: - Methods
    private func commitLoad() {
        parent.webViewModel.load(urlText)
    }
    
    private func refreshOrStopPage() {
        if parent.webViewModel.progress == 0.0 || parent.webViewModel.progress == 1.0 {
            parent.webViewModel.refresh()
        } else {
            parent.webViewModel.stopLoading()
            parent.webViewModel.progress = 0
        }
    }

    private func addBookmark() {
        parent.browserViewModel.addBookmark(title: parent.browserViewModel.currentTitle, url: parent.browserViewModel.currentUrl, favicon: parent.browserViewModel.currentFavicon ?? "")
        parent.browserViewModel.saveBookmarks()
    }

    private func removeBookmark() {
        parent.browserViewModel.deleteBookmark(url: parent.browserViewModel.currentUrl)
        parent.browserViewModel.saveBookmarks()
    }
    
    private func urlBar(geometry: GeometryProxy) -> some View {
        if UITraitCollection.current.userInterfaceStyle == .dark {
            return Rectangle()
                .foregroundColor(Color(UIColor.lightGray).opacity(0.4))
                .frame(width: geometry.size.width, height: geometry.size.height)
            
        } else {
            return Rectangle()
                 .foregroundColor(Color(UIColor.systemBackground).opacity(0.9))
                 .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
    
    private func progressBar(geometry: GeometryProxy) -> some View {
        let progressBarWidth = geometry.size.width * CGFloat(parent.webViewModel.progress)
        
        return Rectangle()
            .foregroundColor(.blue.opacity(0.2))
            .frame(width: progressBarWidth, height: geometry.size.height)
    }
}
