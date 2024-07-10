import Combine
import WebKit

class WebViewManager {
    static let shared = WebViewManager()
    private var wkWebViews: [UUID: WKWebView] = [:]
    private var webViews: [UUID: WebView] = [:]


    func getWebView(for tab: Tab) -> WebView {
        if let webView = webViews[tab.id] {
            return webView
        } else {
            let wkWebView = initWKWebView()
            
            let refreshControl = UIRefreshControl()
            wkWebView.scrollView.refreshControl = refreshControl
            
            wkWebView.interactionState = tab.restoreInteractionState()
            wkWebViews[tab.id] = wkWebView
            
            let webView = WebView(webView: .constant(wkWebView))
            webViews[tab.id] = webView
            return webView
        }
    }
    
    func getWKWebView(for tab: Tab) -> WKWebView {
        if let webView = wkWebViews[tab.id] {
            return webView
        } else {
            let wkWebView = initWKWebView()
            
            let refreshControl = UIRefreshControl()
            wkWebView.scrollView.refreshControl = refreshControl
            
            wkWebView.interactionState = tab.restoreInteractionState()
            wkWebViews[tab.id] = wkWebView
            
            let webView = WebView(webView: .constant(wkWebView))
            webViews[tab.id] = webView
            return wkWebView
        }
    }
    
    func getWebView(id: UUID) -> WebView? {
        if let webView = webViews[id] {
            return webView
        }
        return nil
    }
    
    func getWKWebView(id: UUID) -> WKWebView? {
        if let webView = wkWebViews[id] {
            return webView
        }
        return nil
    }

    func isWebViewExist(id: UUID) -> Bool {
        return wkWebViews[id] != nil
    }    
    
    private func initWKWebView() -> WKWebView {
        let webConfiguration = WKWebViewConfiguration()
        let webpagePreferences = WKWebpagePreferences()
        webConfiguration.defaultWebpagePreferences = webpagePreferences
        webConfiguration.allowsInlineMediaPlayback = true

        let userContentController = WKUserContentController()
        
        // Add ScriptMessageHandler instance as message handlers.
        userContentController.add(ScriptMessageHandler.shared, name: "imageLongPress")
        userContentController.add(ScriptMessageHandler.shared, name: "imageClick")
        userContentController.add(ScriptMessageHandler.shared, name: "imageUrlMessage")
        userContentController.add(ScriptMessageHandler.shared, name: "jsLog")
        userContentController.add(ScriptMessageHandler.shared, name: "jsError")

        webConfiguration.userContentController = userContentController
        webConfiguration.preferences = WKPreferences()
        webConfiguration.preferences.isFraudulentWebsiteWarningEnabled = true
        webConfiguration.preferences.javaScriptCanOpenWindowsAutomatically = true
        webConfiguration.ignoresViewportScaleLimits = false
        webConfiguration.upgradeKnownHostsToHTTPS = true
        webConfiguration.mediaTypesRequiringUserActionForPlayback = .audio

        webConfiguration.enablePageTopColorSampling()        
        let webView = WKWebView(frame: .zero, configuration: webConfiguration)
        return webView
    }

}
