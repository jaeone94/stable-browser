import SwiftUI
import WebKit


struct WebView: UIViewRepresentable {
    @Binding var webView: WKWebView
    var onScrollUp : (() -> Void)?
    var onScrollDown : (() -> Void)?
            
    func makeUIView(context: Context) -> WKWebView {
        let webView = webView
        
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
//        webView.interactionState = uiView.interactionState
    }
}
