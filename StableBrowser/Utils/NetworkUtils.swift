import Foundation
import Network
import SwiftUPnP
import Combine

class NetworkUtils {
    private static let upnpRegistry = UPnPRegistry.shared
    private static var cancellables = Set<AnyCancellable>()

    static func findWebUIAddress(port: Int = 7860, completion: @escaping (String?) -> Void) {
        // Start listening for devices
        upnpRegistry.deviceAdded
            .sink { device in
                if let service = device.deviceDefinition?.device.friendlyName,
                   let url = URL(string: service), url.port == port {
                    completion(url.absoluteString)
                }
            }
            .store(in: &cancellables)

        upnpRegistry.deviceRemoved
            .sink { _ in
                // Handle device removal if necessary
            }
            .store(in: &cancellables)

        // Start discovery
        do {
            try upnpRegistry.startDiscovery()
            
            // Optionally, you can add a timeout mechanism here to stop discovery after some time
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(15)) {
                upnpRegistry.stopDiscovery()
                completion(nil)
            }
        } catch {
            print("Discovery could not be started: \(error.localizedDescription)")
            completion(nil)
        }
    }
    
    // Call this method to stop discovery if needed
    static func stopListening() {
        upnpRegistry.stopDiscovery()
    }

    
    private static func isWebUIReachable(url: URL?, timeout: TimeInterval, completion: @escaping (Bool) -> Void) {
        guard let url = url else {
            completion(false)
            return
        }
    
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = timeout
        
        let task = URLSession.shared.dataTask(with: request) { (_, response, error) in
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                completion(false)
                return
            }
            
            completion(true)
        }
        
        task.resume()
    }
    
    private class SearchDelegate: NSObject, NetServiceBrowserDelegate {
        let onServiceFound: (NetService) -> Void
        let onError: (Error) -> Void
        
        init(onServiceFound: @escaping (NetService) -> Void, onError: @escaping (Error) -> Void) {
            self.onServiceFound = onServiceFound
            self.onError = onError
        }
        
        func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
            onServiceFound(service)
        }
        
        func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
            if let error = errorDict[NetService.errorCode] {
                onError(NSError(domain: "NetServiceBrowserErrorDomain", code: error.intValue, userInfo: nil))
            }
        }
    }
    
    private class ResolveDelegate: NSObject, NetServiceDelegate {
        let onResolve: (NetService) -> Void
        let onError: (Error) -> Void
        
        init(onResolve: @escaping (NetService) -> Void, onError: @escaping (Error) -> Void) {
            self.onResolve = onResolve
            self.onError = onError
        }
        
        func netServiceDidResolveAddress(_ sender: NetService) {
            onResolve(sender)
        }
        
        func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
            if let error = errorDict[NetService.errorCode] {
                onError(NSError(domain: "NetServiceErrorDomain", code: error.intValue, userInfo: nil))
            }
        }
    }
        
    
    private static func getNetworkPrefix(for address: String) -> String {
        let components = address.components(separatedBy: ".")
        return components.dropLast().joined(separator: ".")
    }
    
    private static func getNetworkInterfaces() -> [String]? {
        var interfaces: [String] = []
        
        var interfaceArray: UnsafeMutablePointer<ifaddrs>?
        
        guard getifaddrs(&interfaceArray) == 0 else {
            return nil
        }
        
        var pointer = interfaceArray
        while pointer != nil {
            defer { pointer = pointer?.pointee.ifa_next }
            
            guard let interface = pointer?.pointee else {
                continue
            }
            
            let name = String(cString: interface.ifa_name)
            interfaces.append(name)
        }
        
        freeifaddrs(interfaceArray)
        
        return interfaces.isEmpty ? nil : interfaces
    }

    private static func getIPAddresses(for interfaceName: String) -> [String]? {
        var addresses: [String] = []
        
        var interfaceArray: UnsafeMutablePointer<ifaddrs>?
        
        guard getifaddrs(&interfaceArray) == 0 else {
            return nil
        }
        
        var pointer = interfaceArray
        while pointer != nil {
            defer { pointer = pointer?.pointee.ifa_next }
            
            guard let interface = pointer?.pointee, interface.ifa_addr.pointee.sa_family == UInt8(AF_INET) else {
                continue
            }
            
            let name = String(cString: interface.ifa_name)
            if name == interfaceName {
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len), &hostname, socklen_t(hostname.count), nil, socklen_t(0), NI_NUMERICHOST)
                
                let address = String(cString: hostname)
                addresses.append(address)
            }
        }
        
        freeifaddrs(interfaceArray)
        
        return addresses.isEmpty ? nil : addresses
    }

}
