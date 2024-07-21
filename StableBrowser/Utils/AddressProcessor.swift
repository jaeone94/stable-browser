public struct ProcessedAddress {
    let cleanAddress: String
    let useUrl: Bool
    let scheme: String
    let port: Int
    let hasPort: Bool
}

public enum AddressScheme: String, CaseIterable {
    case http = "http"
    case https = "https"
}

public struct AddressProcessor {
    private static let defaultPort = 7860
    
    public static func processAddress(_ address: String) -> ProcessedAddress {
        let cleanAddress = address.lowercased().trimmingCharacters(in: .init(charactersIn: "/"))
        let (scheme, addressWithoutScheme) = extractScheme(from: cleanAddress)
        let (finalAddress, finalPort) = extractPort(from: addressWithoutScheme)
        
        return ProcessedAddress(
            cleanAddress: finalAddress,
            useUrl: scheme != nil,
            scheme: scheme?.rawValue ?? AddressScheme.http.rawValue,
            port: finalPort,
            hasPort: addressWithoutScheme != finalAddress
        )
    }
    
    public static func extractScheme(from address: String) -> (AddressScheme?, String) {
        if let scheme = AddressScheme.allCases.first(where: { address.hasPrefix($0.rawValue + "://") }) {
            return (scheme, String(address.dropFirst(scheme.rawValue.count + 3)))
        }
        return (nil, address)
    }
    
    private static func extractPort(from address: String) -> (String, Int) {
        if let colonIndex = address.lastIndex(of: ":"),
           let port = Int(address.suffix(from: address.index(after: colonIndex))) {
            return (String(address.prefix(upTo: colonIndex)), port)
        }
        return (address, Int(defaultPort))
    }
}
