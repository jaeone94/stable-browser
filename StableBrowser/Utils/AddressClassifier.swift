public enum AddressType {
    case ip
    case url
    case invalid
}

public struct AddressClassifier {
    public static func classifyAddress(_ address: String) -> AddressType {
        let cleanAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove scheme if present
        let addressWithoutScheme = cleanAddress.replacingOccurrences(of: "^(http|https)://", with: "", options: .regularExpression)
        
        // Remove port if present
        let addressWithoutPort = addressWithoutScheme.replacingOccurrences(of: ":[0-9]+$", with: "", options: .regularExpression)
        
        // Check if it's an IP address
        let ipPattern = "^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"
        if let _ = addressWithoutPort.range(of: ipPattern, options: .regularExpression) {
            return .ip
        }
        
        // Check if it's a valid URL
        let urlPattern = "^([a-zA-Z0-9]+(-[a-zA-Z0-9]+)*\\.)+[a-zA-Z]{2,}$"
        if let _ = addressWithoutPort.range(of: urlPattern, options: .regularExpression) {
            return .url
        }
        
        // If it doesn't match IP or URL patterns, it's invalid
        return .invalid
    }
}
