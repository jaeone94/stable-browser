import Foundation
import SwiftUI
import WebKit
import UIKit

extension WebViewModel {    
    // MARK: - Functions
    
    // MARK: - Load functions
    func load(_ urlString: String) {
        if urlString.isEmpty {
            loadURL("")
            return
        }
        
        if !urlString.contains("://") {
            let formattedUrlString = hasUrlTail(urlString) ? "https://" + urlString : "https://www.google.com/search?q=" + urlString
            loadURL(formattedUrlString)
            return
        }
        
        loadURL(urlString)
    }
    
    private func loadURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
        webView.load(request)
    }

    // MARK: - Navigation functions
    func goBack() {
        if webView.canGoBack {
            webView.goBack()
            refreshPageTitle(webView: webView)
        }
    }
    
    func goForward() {
        if webView.canGoForward {
            webView.goForward()
            refreshPageTitle(webView: webView)
        }
    }

    func triggerNewTab(with url: String?) {
        guard let url = url else { return }
        onOpenNewTab?(url)
    }

    // MARK: - Other functions
    func refresh() {
        webView.reload()
    }
    
    func stopLoading() {
        webView.stopLoading()
    }
    
    func retryLoading() {
        load(currentTab?.url ?? "")
    }
    
    func rebindingUrl() {
        if let tab = bridge?.getTab(for: webView) {
            tab.url = webView.url?.absoluteString ?? ""
            tab.title = StringUtils.abbreviateUrl(urlString: currentTab?.url ?? "")
        }
    }
    
    func getPageUrl(webView: WKWebView) -> String {
        return webView.url?.absoluteString ?? ""
    }
    
    
    func hasUrlTail(_ urlString: String) -> Bool {
        let last4 = urlString.suffix(4)
        return last4.contains(".")
    }
    
    func setBackgroundColor() {
        let js = "window.getComputedStyle(document.body, null).getPropertyValue('background-color');"
        webView.evaluateJavaScript(js) { [weak self] (result, error) in
            if let bgColor = result as? String {
                self?.backgroundColor = Color(cssColor: bgColor) ?? .white
                self?.setRefreshControlColor(bgColor)
            }
        }
    }
    
    func setFavicon() {
        let js = "var link = document.querySelector(\"link[rel*='icon']\") || document.querySelector(\"link[rel*='shortcut icon']\"); if (link !== null) { link.href; } else { ''; }"
        webView.evaluateJavaScript(js) { [weak self] (result, error) in
            if let faviconUrl = result as? String, !faviconUrl.isEmpty {
                if let url = URL(string: faviconUrl) {
                    URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
                        if let data = data {
                            self?.bridge?.setCurrentFavicon(favicon: data.base64EncodedString())
                        }
                    }.resume()
                }
            }
        }
    }
    
    func setSnapshot() {
        webView.takeSnapshot(with: nil) { [weak self] image, error in
            if let image = image {
                let currentSnapshot = image.pngData()?.base64EncodedString()
                self?.currentTab?.snapshot = currentSnapshot
                self?.currentTab?.snapshot_id = UUID()
            }
        }
    }
    
    func refreshPageTitle(webView: WKWebView) {
        if let bridge = self.bridge, bridge.isSameWebView(tab_id: currentTab!.id, webView: webView) {
            let js = "document.title"
            webView.evaluateJavaScript(js) { [weak self] (result, error) in
                if let pageTitle = result as? String {
                    if let tab = self?.bridge?.getTab(for: webView) {
                        tab.title = pageTitle
                    }
                }
            }
        }
    }
    
    func setRefreshControlColor(_ bgColor: String) {
        if let color = UIColor(cssColor: bgColor), let refreshControl = webView.scrollView.refreshControl {
            let luminance = color.luminance
            refreshControl.tintColor = luminance > 0.5 ? .darkGray : .lightGray
        }
    }
    
    func clearCache() {
        URLCache.shared.removeAllCachedResponses()
    }
    
    func getAllImageTags() {
        let imageUrlScript = """
            document.documentElement.style.webkitTouchCallout = 'none';
        
            var imageUrls = [];
            var images = document.getElementsByTagName('img');
            for (var i = 0; i < images.length; i++) {
                var img = images[i];
                var imageId = "img_" + i;
                img.id = imageId;
                if (img.closest('#overlay') === null && img.naturalWidth > 300 && img.naturalHeight > 300) {
                    var src = img.src;
                    var srcset = img.srcset;
                    imageUrls.push({ id: imageId, src: src, srcset: srcset });
                }
            }

            if (imageUrls.length > 0) {
                var floatingButton = document.getElementById('floatingButton');
                if (!floatingButton) {
                    floatingButton = document.createElement('div');
                    floatingButton.setAttribute('id', 'floatingButton');
                    floatingButton.setAttribute('style', 'position: fixed; bottom: 50px; right: 20px; background-color: rgba(255, 255, 255, 0.8); border-radius: 50%; width: 100px; height: 100px; display: flex; justify-content: center; align-items: center; box-shadow: 0 2px 10px rgba(0, 0, 0, 0.3); cursor: pointer; z-index: 9999;');
                    
                    document.body.appendChild(floatingButton);
                }else {
                    showFloatingButton();
                }
                
                floatingButton.innerHTML = '<span style="font-weight: bold; color: #333; width: 100%; text-align: center;">(' + imageUrls.length + ')</span>';
                
                var overlay = document.getElementById('overlay');
                if (!overlay) {
                    overlay = document.createElement('div');
                    overlay.setAttribute('id', 'overlay');
                    overlay.setAttribute('style', 'display: none; position: fixed; top: 0; left: 0; width: 100%; height: 100%; background-color: rgba(0, 0, 0, 0.8); z-index: 9998; overflow-y: auto;');
                    
                    document.body.appendChild(overlay);
                    
                    var imageContainer = document.createElement('div');
                    imageContainer.setAttribute('id', 'imageContainer');
                    imageContainer.setAttribute('style', 'display: flex; flex-wrap: wrap; justify-content: center; align-items: center; padding: 20px;');
                    
                    overlay.appendChild(imageContainer);
                }
                
                var imageContainer = document.getElementById('imageContainer');
                
                floatingButton.onclick = function() {
                    if (overlay.style.display === 'block') {
                        hideOverlay();
                    } else {
                        imageContainer.innerHTML = '';
                                    
                        for (var j = 0; j < imageUrls.length; j++) {
                            var imageInfo = imageUrls[j];
                            var imgElement = document.createElement('img');
                            imgElement.addEventListener('touchstart', startLongPressTimer, false);
                            imgElement.addEventListener('touchend', cancelLongPressTimer, false);
                            imgElement.addEventListener('touchcancel', cancelLongPressTimer, false);
                            imgElement.addEventListener('click', handleImageClick, false);

                            imgElement.setAttribute('id', imageInfo.id);
                            imgElement.setAttribute('src', imageInfo.src);
                            imgElement.setAttribute('srcset', imageInfo.srcset);
                            imgElement.setAttribute('style', 'max-width: 200px; max-height: 200px; margin: 10px;');
                            
                            imageContainer.appendChild(imgElement);
                        }
                        overlay.style.display = 'block';
                        floatingButton.innerHTML = '<span style="font-weight: bold; color: #333; width: 100%; text-align: center;">Close</span>';
                    }
                };
            }
        """
        webView.evaluateJavaScript(imageUrlScript, completionHandler: nil)
        BrowserViewModel.shared.imageId = nil
        BrowserViewModel.shared.imageSrc = nil
    }
    
    func getInjectHistString() -> String? {
        if let currentUrl = currentTab?.url {
            let injectHist = InjectHistoryService.shared.loadInjectHistory(baseUrl: StringUtils.abbreviateUrl(urlString: currentUrl))
            
            if injectHist.isEmpty {
                return nil
            }
            
            let injectHistDTO = injectHist.map { InjectInfoDTO(baseUrl: $0.baseUrl, src: $0.src, dest: $0.dest) }
            
            // Transform to string
            return injectHistDTO.map { "{ src: '\($0.src)', dest: '\($0.dest)' }" }.joined(separator: ", ")
        }
        return nil
    }
    
    func injectAllImages() {
        guard let injectHistString = getInjectHistString() else {
            return
        }
        
        let injectScript = """
        var injectHist = [\(injectHistString)];
        var images = document.getElementsByTagName('img');
        for (var i = 0; i < images.length; i++) {
            var img = images[i];
            if (img.closest('#overlay') === null && img.naturalWidth > 300 && img.naturalHeight > 300) {
                processImage(img)
            }
        }
        """
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.webView.evaluateJavaScript(injectScript, completionHandler: nil)
        }
    }

    func tryAutoInjectImage() {
        guard let injectHistString = getInjectHistString() else {
            return
        }
        
        let injectScript = """
        var injectHist = [\(injectHistString)];

        function getBaseUrl(url) {
            const extensions = ['.jpg', '.png', '.gif', '.jpeg', '.svg'];
            for (const ext of extensions) {
                const index = url.indexOf(ext);
                if (index !== -1) {
                    return url.slice(0, index + ext.length);
                }
            }
            return url;
        }

        function processImage(image) {
            let src = getBaseUrl(image.src);
            injectHist.map(x=> {
                if (getBaseUrl(x.src) == src) {
                    image.src = x.dest;
                    image.srcset = '';
                }
            });
        }

        function processNode(node) {
            if (node.nodeType === Node.ELEMENT_NODE) {
                if (node.tagName === 'IMG') {
                    processImage(node);
                } else {
                    node.childNodes.forEach(processNode);
                }
            }
        }

        // Process existing nodes
        processNode(document.body);

        const injectObserver = new MutationObserver((mutations) => {
            mutations.forEach((mutation) => {
                if (mutation.type === 'childList') {
                    mutation.addedNodes.forEach(processNode);
                }
            });
        });

        injectObserver.observe(document.body, {
            childList: true,
            subtree: true
        });
        """
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.webView.evaluateJavaScript(injectScript, completionHandler: nil)
        }
    }
    
    func updateAuthInjectInfo() {
        guard let injectHistString = getInjectHistString() else {
            return
        }
        
        let injectScript = """
        injectHist = [\(injectHistString)];
        """
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.webView.evaluateJavaScript(injectScript, completionHandler: nil)
        }
    }
}

//


