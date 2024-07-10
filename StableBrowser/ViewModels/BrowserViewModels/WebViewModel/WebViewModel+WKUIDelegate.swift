import WebKit


extension WebViewModel: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            if let url = navigationAction.request.url {
                if !url.absoluteString.isEmpty {
                    self.triggerNewTab(with: url.absoluteString)                                   
                }
            }
        }
        return nil
    }           
}
