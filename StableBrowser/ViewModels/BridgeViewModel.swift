import Foundation
import WebKit

class BridgeViewModel: ObservableObject {
    internal let browserViewModel: BrowserViewModel
    internal let webViewModel: WebViewModel
    
    init(browserViewModel: BrowserViewModel, webViewModel: WebViewModel) {
        self.browserViewModel = browserViewModel
        self.webViewModel = webViewModel
    }
    
    func updateTab(tab_id: UUID, title: String, url: String) {
        if let tab = getTab(with: tab_id) {
            tab.title = title
            tab.url = url
        }
    }
    
    func updateTab(webView: WKWebView, title: String, url: String) {
        if let tab = getTab(with: webView) {
            tab.title = title
            tab.url = url
        }
    }

    func isSameWebView(tab_id: UUID, webView: WKWebView) -> Bool {
        if let tab = getTab(with: tab_id) {
            let tabWebView = WebViewManager.shared.getWKWebView(for: tab)
            return tabWebView == webView
        }
        return false
    }

    func getTab(for webView: WKWebView) -> Tab? {
        if let tab = browserViewModel.tabs.first(where: { WebViewManager.shared.getWKWebView(for: $0) == webView }) {
            return tab
        }
        return nil
    }
    
    func setCurrentFavicon(favicon: String) {
        browserViewModel.currentFavicon = favicon
    }
    
    func refreshWebView() {
        webViewModel.refresh()
    }
    
    private func getTab(with tab_id: UUID) -> Tab? {
        return browserViewModel.tabs.first(where: { $0.id == tab_id })
    }
    
    private func getTab(with webView: WKWebView) -> Tab? {
        return browserViewModel.tabs.first(where: { WebViewManager.shared.getWKWebView(for: $0) == webView })
    }
}
