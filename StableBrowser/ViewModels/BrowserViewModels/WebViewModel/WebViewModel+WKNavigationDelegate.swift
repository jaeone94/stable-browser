import WebKit
import SwiftUI

extension WebViewModel: WKNavigationDelegate {
    // MARK: - WKNavigationDelegate
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        isValidPage = false
        updateNavigationStatus(webView)
    }

    func urlShouldNotRedirect(urlString: String) -> Bool {
        if urlString.hasPrefix("https://www.google.com/search") {
            return true
        }    
        else if urlString.hasPrefix("https://www.instagram.com") {
            return true
        }
        return false
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == .linkActivated,
           let url = navigationAction.request.url,
           case let urlString = url.absoluteString,
           urlShouldNotRedirect(urlString: urlString) {            
            decisionHandler(.cancel)
            webView.load(navigationAction.request)
            return
        }
                
        guard let urlString = navigationAction.request.url?.absoluteString else {
            decisionHandler(.cancel)
            return
        }
                
        if urlString.hasPrefix("http:") || urlString.hasPrefix("https:") {
            decisionHandler(.allow)
        } else {
            if #available(iOS 10.0, *) {
                if let url = navigationAction.request.url {
                    UIApplication.shared.open(url, options: [:]) { success in
                        if success {
                            print("Opened \(url.absoluteString)")
                        }
                    }
                }
            } else {
                if let url = navigationAction.request.url {
                    UIApplication.shared.openURL(url)
                }
            }
            decisionHandler(.cancel)
        }
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        isValidPage = true
        updateNavigationStatus(webView)
        setBackgroundColor()
        setSnapshot()

        let userScript = WKUserScript(source: "document.documentElement.style.webkitTouchCallout = 'none';", injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        webView.configuration.userContentController.addUserScript(userScript)
        
        let script2 = """
            const observer = new MutationObserver((mutations) => {
                mutations.forEach((mutation) => {
                    if (mutation.type === 'childList') {
                        mutation.addedNodes.forEach((node) => {
                            if (node.tagName === 'IMG') {
                                node.addEventListener('touchstart', startLongPressTimer, false);
                                node.addEventListener('touchend', cancelLongPressTimer, false);
                                node.addEventListener('touchcancel', cancelLongPressTimer, false);
                            }
                        });
                    }
                });
            });

            observer.observe(document.body, {
                childList: true,
                subtree: true
            });
        """
        
        webView.evaluateJavaScript(script2, completionHandler: nil)
        
        if InjectHistoryService.shared.isAutoInjectMode {
            tryAutoInjectImage()
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        updateNavigationStatus(webView)
        setFavicon()
        setBackgroundColor()
        refreshPageTitle(webView: webView)
        
        let userScript = WKUserScript(source: "document.documentElement.style.webkitTouchCallout = 'none';", injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        webView.configuration.userContentController.addUserScript(userScript)

        let longPressScript = """
            var longPressThreshold = 1000; // 1000ms = 1 second
            var longPressTimer;

            function handleLongPress(event) {
                var elementContent = event.target.outerHTML;
                var imageId = event.target.id;
                var message = {
                    elementContent: elementContent,
                    imageId: imageId,
                    imageSrc: event.target.src
                };
                window.webkit.messageHandlers.imageLongPress.postMessage(message);
            }

            function handleImageClick(event) {
                var elementContent = event.target.outerHTML;
                var imageId = event.target.id;
                var message = {
                    elementContent: elementContent,
                    imageId: imageId,
                    imageSrc: event.target.src
                };
                window.webkit.messageHandlers.imageClick.postMessage(message);
            }

            function startLongPressTimer(event) {
                longPressTimer = setTimeout(function() {
                    handleLongPress(event);
                }, longPressThreshold);
            }

            function cancelLongPressTimer() {
                if (longPressTimer) {
                    clearTimeout(longPressTimer);
                    longPressTimer = null;
                }
            }
        
            function hideFloatingButton() {
                var floatingButton = document.getElementById('floatingButton');
                if (floatingButton) {
                    floatingButton.style.display = 'none';
                }
            }
        
            function showFloatingButton() {
                var floatingButton = document.getElementById('floatingButton');
                if (floatingButton) {
                    floatingButton.style.display = 'flex';
                }
            }
        
            function hideOverlay() {
                var overlay = document.getElementById('overlay');
                if (overlay) {
                    overlay.style.display = 'none';
                    floatingButton.innerHTML = '<span style="font-weight: bold; color: #333; width: 100%; text-align: center;">(' + imageUrls.length + ')</span>';
                }
            }

            var images = document.getElementsByTagName('img');
            for (var i = 0; i < images.length; i++) {
                var imageId = "img_" + i;
                images[i].id = imageId;
                images[i].addEventListener('touchstart', startLongPressTimer, false);
                images[i].addEventListener('touchend', cancelLongPressTimer, false);
                images[i].addEventListener('touchcancel', cancelLongPressTimer, false);
            }
        """

        webView.evaluateJavaScript(longPressScript, completionHandler: nil)
        
        if InjectHistoryService.shared.isAutoInjectMode {
            injectAllImages()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.setSnapshot()
        }
        
        isValidPage = false
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.progress = 0.0
            if error._code == NSURLErrorCancelled || error._code == 102 {
                return
            }
            
            switch error._code {
            case NSURLErrorTimedOut:
                self.errorMessage = "The request timed out."
            case NSURLErrorCannotFindHost:
                self.errorMessage = "The server could not be found."
            case NSURLErrorCannotConnectToHost:
                self.errorMessage = "The server could not be connected to."
            case NSURLErrorNetworkConnectionLost:
                self.errorMessage = "The network connection was lost."
            case NSURLErrorDNSLookupFailed:
                self.errorMessage = "The server could not be found."
            case NSURLErrorNotConnectedToInternet:
                self.errorMessage = "The Internet connection appears to be offline."
            case NSURLErrorBadServerResponse:
                self.errorMessage = "The server returned a bad response."
            case NSURLErrorSecureConnectionFailed:
                self.errorMessage = "The secure connection failed."
            case NSURLErrorServerCertificateHasBadDate:
                self.errorMessage = "The server certificate has a bad date."
            case NSURLErrorServerCertificateUntrusted:
                self.errorMessage = "The server certificate is untrusted."
            case NSURLErrorServerCertificateHasUnknownRoot:
                self.errorMessage = "The server certificate has an unknown root."
            case NSURLErrorServerCertificateNotYetValid:
                self.errorMessage = "The server certificate is not yet valid."
            case NSURLErrorClientCertificateRejected:
                self.errorMessage = "The client certificate was rejected."
            case NSURLErrorClientCertificateRequired:
                self.errorMessage = "The client certificate is required."
            case NSURLErrorCannotLoadFromNetwork:
                self.errorMessage = "The resource could not be loaded from the network."
            case NSURLErrorCannotCreateFile:
                self.errorMessage = "The file could not be created."
            case NSURLErrorCannotOpenFile:
                self.errorMessage = "The file could not be opened."
            case NSURLErrorCannotCloseFile:
                self.errorMessage = "The file could not be closed."
            case NSURLErrorCannotWriteToFile:
                self.errorMessage = "The file could not be written to."
            case NSURLErrorCannotRemoveFile:
                self.errorMessage = "The file could not be removed."
            case NSURLErrorCannotMoveFile:
                self.errorMessage = "The file could not be moved."
            case NSURLErrorDownloadDecodingFailedMidStream:
                self.errorMessage = "The download decoding failed mid-stream."
            case NSURLErrorDownloadDecodingFailedToComplete:
                self.errorMessage = "The download decoding failed to complete."
            case NSURLErrorInternationalRoamingOff:
                self.errorMessage = "The international roaming is off."
            case NSURLErrorCallIsActive:
                self.errorMessage = "The call is active."
            case NSURLErrorDataNotAllowed:
                self.errorMessage = "The data is not allowed."
            case NSURLErrorRequestBodyStreamExhausted:
                self.errorMessage = "The request body stream was exhausted."
            case NSURLErrorBackgroundSessionRequiresSharedContainer:
                self.errorMessage = "The background session requires a shared container."
            case NSURLErrorBackgroundSessionInUseByAnotherProcess:
                self.errorMessage = "The background session is in use by another process."
            case NSURLErrorBackgroundSessionWasDisconnected:
                self.errorMessage = "The background session was disconnected."
            default:
                self.errorMessage = error.localizedDescription
            }
            
            self.triggerShowErrorView = true
        }
    }

    private func updateNavigationStatus(_ webView: WKWebView) {
        guard let urlString = webView.url?.absoluteString else {
            return
        }
        
        DispatchQueue.main.async {
            let title = StringUtils.abbreviateUrl(urlString: urlString)
            self.canGoBack = webView.canGoBack
            self.canGoForward = webView.canGoForward
            
            if let tab = self.bridge?.getTab(for: webView) {
                if self.isValidPage {
                    tab.updateInteractionState(interactionState: webView.interactionState)
                }
                tab.url = urlString
                tab.title = title
            }
            
            self.onTabStateChanged?()
        }
    }        
    
    private func updateCurrentTabInteractionState(webView: WKWebView, urlString: String) {
        if let tab = self.bridge?.getTab(for: webView) {
            tab.updateInteractionState(interactionState: webView.interactionState)
            tab.url = urlString
        }
    }
}
