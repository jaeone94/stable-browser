import Foundation
import UIKit

protocol NLocalNetworkServiceDelegate: AnyObject {
    func didFindService(_ service: NetService)
    func didRemoveService(_ service: NetService)
}

class LocalNetworkService: NSObject {
    private var serviceBrowser: NetServiceBrowser!
    weak var delegate: NLocalNetworkServiceDelegate?
    
    override init() {
        super.init()
        self.serviceBrowser = NetServiceBrowser()
        self.serviceBrowser.delegate = self
    }
    
    func startBrowsing() {
        serviceBrowser.searchForServices(ofType: "_http._tcp.", inDomain: "local.")
    }
    
    func stopBrowsing() {
        serviceBrowser.stop()
    }
}

extension LocalNetworkService: NetServiceBrowserDelegate {
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        print("Found service: \(service)")
        delegate?.didFindService(service)
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        print("Removed service: \(service)")
        delegate?.didRemoveService(service)
    }

    func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser) {
        print("Search stopped")
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
        print("Search failed: \(errorDict)")
    }
}
