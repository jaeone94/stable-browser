import Foundation

struct StringUtils {
    public static func abbreviateUrl(urlString: String) -> String {
        guard let url = URL(string: urlString), let host = url.host else { return urlString }
        return host
    }        
}


