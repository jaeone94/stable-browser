import Foundation

struct StringUtils {
    public static func abbreviateUrl(urlString: String) -> String {
        guard let url = URL(string: urlString), let host = url.host else { return urlString }
        return host
    }
    
    public static func processAddress(_ address: String, port: String) -> (String, Bool, Int) {
        var cleanAddress = address.lowercased()
        var useHttps = false
        var cleanPort = Int(port) ?? 7860
        
        // Check for http:// or https:// prefix
        if cleanAddress.hasPrefix("http://") {
            cleanAddress = String(cleanAddress.dropFirst(7))
        } else if cleanAddress.hasPrefix("https://") {
            cleanAddress = String(cleanAddress.dropFirst(8))
            useHttps = true
        }
        
        // Remove any trailing slash
        if cleanAddress.hasSuffix("/") {
            cleanAddress = String(cleanAddress.dropLast())
        }
        
        // Check if the address includes a port
        if let colonIndex = cleanAddress.lastIndex(of: ":") {
            let possiblePort = cleanAddress.suffix(from: cleanAddress.index(after: colonIndex))
            if let customPort = Int(possiblePort) {
                cleanPort = customPort
                cleanAddress = String(cleanAddress.prefix(upTo: colonIndex))
            }
        }
        
        return (cleanAddress, useHttps, cleanPort)
    }
}
