import Foundation
import SwiftUI
import WebKit

class WebViewModel: NSObject, ObservableObject {
    // MARK: - Web Statement properties
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    @Published var progress: Double = 0.0    
    @Published var errorMessage: String = ""
    @Published var scrollY: CGFloat = 0    
    @Published var backgroundColor: Color = .white
    @Published var currentTab: Tab?
    
    @StateObject var injectHistoryService = InjectHistoryService.shared
    
    // MARK: - for BrowserView
    var onOpenNewTab: ((String) -> Void)?
    var onTabStateChanged: (() -> Void)?
    @Published var onScrollUp: Bool = false
    @Published var onScrollDown: Bool = false
    @Published var triggerDropImage: Bool = false
    @Published var triggerShowErrorView: Bool = false
    
    @Published var isValidPage: Bool = false
    
    // MARK: - WebView
    fileprivate var configuration: WKWebViewConfiguration?
    @Published var webView = WKWebView()
    
    
    // MARK: - Bridge
    var bridge: BridgeViewModel?

    // MARK: - Initializer
    init(tab: Tab) {
        super.init()
        importTab(tab: tab)
    }
        
    // MARK: - Functions
    func importTab(tab : Tab) {
        webView = WebViewManager.shared.getWKWebView(for: tab)
        webView.allowsBackForwardNavigationGestures = true
        webView.allowsLinkPreview = true
        webView.isUserInteractionEnabled = true
        webView.scrollView.layer.masksToBounds = false        
        webView.navigationDelegate = self
        webView.scrollView.delegate = self
        webView.uiDelegate = self
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
        
        self.currentTab = tab
        self.canGoBack = self.webView.canGoBack
        self.canGoForward = self.webView.canGoForward
        
        self.setBackgroundColor()
    }
    
    // MARK: - Key-Value Observing
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(WKWebView.estimatedProgress) {
            DispatchQueue.main.async {
                let newProgress = self.webView.estimatedProgress
                self.progress = newProgress                
                if newProgress >= 1.0 {                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.progress = 0.0
                    }
                }
            }
        }
    }
}



extension WKWebViewConfiguration {
    /// Enables page top color sampling.
    public func enablePageTopColorSampling() {
        let selector = Selector(("_setSampledPageTopColorMaxDifference:"))
        if responds(to: selector) {
            perform(selector, with: 5.0 as Double)
        }
    }
}
