import Foundation
import UIKit

struct ImageUtils {
    public static func b64img(_ image: UIImage) -> String {
        return "data:image/png;base64," + rawB64img(image)
    }

    public static func rawB64img(_ image: UIImage) -> String {
        guard let data = image.pngData() else {
            return ""
        }
        return data.base64EncodedString()
    }
        
    public static func base64ToImage(_ base64String: String) -> UIImage? {
        guard let data = Data(base64Encoded: base64String) else {
            return nil
        }
        return UIImage(data: data)
    }
}
