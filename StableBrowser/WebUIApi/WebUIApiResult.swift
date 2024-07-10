import UIKit
struct WebUIApiResult {
    let images: [UIImage]
    let parameters: [String: Any]
    let info: [String: Any]
    let json: [String: Any]
    
    var image: UIImage? {
        return images.first
    }
}
