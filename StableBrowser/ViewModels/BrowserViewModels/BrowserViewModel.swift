import Foundation
import WebKit
import UIKit
import Combine

class BrowserViewModel: ObservableObject {
    static let shared = BrowserViewModel()
    
    // MARK: - Properties
    @Published var bookmarks: [Bookmark] = []
    @Published var tabs: [Tab] = []
    @Published var selectedTab: Tab = Tab()
    @Published var selectedTabIndex: Int = 0
    @Published var selectedWebView: WebView = WebView(webView: .constant(WKWebView()))
    @Published var selectedWKWebView: WKWebView = WKWebView()
    @Published var tabSnapshotChanged = false
    
    @Published var imageFromBrowser: UIImage?
    @Published var imageId: String?
    @Published var imageSrc: String?
    @Published var imageForInject: UIImage?
    
    var currentUrl: String {
        return selectedTab.url
    }
    
    var currentTitle: String {
        return selectedTab.title
    }
    
    var currentFavicon: String?
    
    // MARK: - Bridge
    var bridge: BridgeViewModel?
            
    // MARK: - Initializers
    private init() {
        loadTabs()
        loadBookmarks()
        if bookmarks.isEmpty {
            // Add default bookmarks (google.com, apple.com, etc.)
            addBookmark(title: "Google", url: "https://www.google.com", favicon: StringConstants.GOOGLE_FAVICON_B64)
        }
        setObservers()
        configureTabs()
    }
    
    // MARK: - Tab Functions
    
    func selectTab(tab: Tab) {
        selectedWebView = WebViewManager.shared.getWebView(for: tab)
        selectedWKWebView = WebViewManager.shared.getWKWebView(for: tab)
        selectedTab = tab
        if let index = tabs.firstIndex(where: { $0.id == tab.id }) {
            selectedTabIndex = index
        }
    }
    
    func addNewTab() {
        let newTab = Tab()
        tabs.insert(newTab, at: 0)
        selectTab(tab: newTab)
        saveTabs()
    }
    
    func addNewTab(url: String) -> Tab {
        let newTab = Tab()
        newTab.url = url
        tabs.insert(newTab, at: 0)
        selectTab(tab: newTab)
        saveTabs()
        return newTab
    }

    func switchTab(to id: UUID) {
        if let index = tabs.firstIndex(where: { $0.id == id }) {
            selectTab(tab: tabs[index])
            saveSelectedtabIndex()
        }
    }

    func deleteTab(at index: Int) {
        tabs.remove(at: index)
        if tabs.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.addNewTab()
                if index == self.selectedTabIndex {
                    self.selectTab(tab: self.tabs[0])
                }
                self.saveTabs()
            }
        } else {
            if index == selectedTabIndex {
                selectTab(tab: tabs[0])
            }
            saveTabs()
        }
    }

    func deleteTab(tab: Tab) {
        if let index = tabs.firstIndex(where: { $0.id == tab.id }) {
            tabs.remove(at: index)
            if tabs.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.addNewTab()
                    if index == self.selectedTabIndex {
                        self.selectTab(tab: self.tabs[0])
                    }
                    self.saveTabs()
                }
            } else {
                if index == selectedTabIndex {
                    selectTab(tab: tabs[0])
                }
                saveTabs()
            }
        }
    }
    
    // MARK: - Bookmark Functions
    func addBookmark(title: String, url: String, favicon: String) {
        let newBookmark = Bookmark(title: title, url: url, favicon: favicon)
        bookmarks.append(newBookmark)
    }

    func deleteBookmark(at indexSet: IndexSet) {
        bookmarks.remove(atOffsets: indexSet)
    }

    func deleteBookmark(url: String) {
        if let index = bookmarks.firstIndex(where: { $0.url == url }) {
            bookmarks.remove(at: index)
        }
    }

    func isBookmarked(url: String) -> Bool {
        return bookmarks.contains(where: { $0.url == url })
    }

    func moveBookmark(from sourceIndex: Int, to destinationIndex: Int) {
        let bookmark = bookmarks.remove(at: sourceIndex)
        bookmarks.insert(bookmark, at: destinationIndex)
        saveBookmarks()
    }

    // MARK: - Private Functions
    private func setObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(saveTabs), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(saveBookmarks), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    private func configureTabs() {
        if tabs.isEmpty {
            addNewTab()
        } else {
            if selectedTabIndex >= 0 && selectedTabIndex < tabs.count {
                selectTab(tab: tabs[selectedTabIndex])
            } else {
                addNewTab()
            }
        }
    }
    
    private func saveSelectedtabIndex() {
        UserDefaults.standard.set(selectedTabIndex, forKey: "selectedTabIndex")
    }

    @objc internal func saveTabs() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(tabs) {
            UserDefaults.standard.set(encoded, forKey: "tabs")
        }
        UserDefaults.standard.set(selectedTabIndex, forKey: "selectedTabIndex")
    }

    public func loadTabs() {
        if let savedTabs = UserDefaults.standard.object(forKey: "tabs") as? Data {
            let decoder = JSONDecoder()
            if let loadedTabs = try? decoder.decode([Tab].self, from: savedTabs) {
                tabs = loadedTabs
            }
        }
        
        if let selectedTabIndex = UserDefaults.standard.object(forKey: "selectedTabIndex") as? Int {
            self.selectedTabIndex = selectedTabIndex
        }
    }    

    @objc internal func saveBookmarks() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(bookmarks) {
            UserDefaults.standard.set(encoded, forKey: "bookmarks")
        }
    }

    private func loadBookmarks() {
        if let savedBookmarks = UserDefaults.standard.object(forKey: "bookmarks") as? Data {
            let decoder = JSONDecoder()
            if let loadedBookmarks = try? decoder.decode([Bookmark].self, from: savedBookmarks) {
                bookmarks = loadedBookmarks
            }
        }
    }
    
    func InjectImage(img_id: String, baseImage: UIImage) {
        let webView = self.selectedWKWebView
        
        // encode image to base64
        let base64String = ImageUtils.b64img(baseImage)
        
        let script = """
        hideOverlay();
        hideFloatingButton();
        var img = document.getElementById('\(img_id)');
        if (img) {
            img.src = '\(base64String)';
            img.srcset = '';
        }
        """
        // execute script
        webView.evaluateJavaScript(script) { (result, error) in
            if let error = error {
                print("Error injecting image: \(error.localizedDescription)")
            } else {                
                Toast.shared.present(
                    title: "Image injected",
                    symbol: "photo.badge.arrow.down.fill",
                    isUserInteractionEnabled: true,
                    timing: .medium,
                    padding: 110
                )
                print("Image injected successfully")
                
                if let imageSrc = self.imageSrc {
                    
                    let baseUrl = StringUtils.abbreviateUrl(urlString: self.currentUrl)
                    if imageSrc == self.currentUrl {
                        
                    }
                    if InjectHistoryService.shared.loadInjectHistory(baseUrl: baseUrl, src: imageSrc) != nil {
                        InjectHistoryService.shared.updateInjectHistory(baseUrl: baseUrl, src: imageSrc, dest: base64String)
                    }
                    else {
                        InjectHistoryService.shared.addInjectHistory(baseUrl: baseUrl, src: imageSrc, dest: base64String)
                    }
                    
                    if InjectHistoryService.shared.isAutoInjectMode {
                        if let bridge = self.bridge {
                            bridge.webViewModel.updateAuthInjectInfo()
                        }
                    }
                }
            }
        }
    }

    func clearCache() {
        let websiteDataTypes = NSSet(array: [WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache])
        let date = Date(timeIntervalSince1970: 0)
        WKWebsiteDataStore.default().removeData(ofTypes: websiteDataTypes as! Set<String>, modifiedSince: date) {
            print("Cache cleared")
        }
        URLCache.shared.removeAllCachedResponses()        
    }

    func clearCookies() {
        let dataStore = WKWebsiteDataStore.default()
        dataStore.fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
            dataStore.removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), for: records) {
                print("Cookies cleared")
            }
        }
    }

    // MARK: - Deinit
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
