import ObjectiveC
import WebKit
class ScriptMessageHandler: NSObject, WKScriptMessageHandler {
    static let shared = ScriptMessageHandler()

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "imageLongPress", let dict = message.body as? [String: Any],
           let elementHTML = dict["elementContent"] as? String,
           let imageId = dict["imageId"] as? String,
           let imageSrc = dict["imageSrc"] as? String {

            // Send image HTML and ID with image long press event via NotificationCenter
            let userInfo = ["elementHTML": elementHTML, "imageId": imageId, "imageSrc": imageSrc]
            NotificationCenter.default.post(name: .imageLongPress, object: nil, userInfo: userInfo)
            return
        }
        
        if message.name == "imageClick", let dict = message.body as? [String: Any],
            let elementHTML = dict["elementContent"] as? String,
            let imageId = dict["imageId"] as? String,
            let imageSrc = dict["imageSrc"] as? String {
            let userInfo = ["elementHTML": elementHTML, "imageId": imageId, "imageSrc": imageSrc]
            NotificationCenter.default.post(name: .imageClick, object: nil, userInfo: userInfo)
            return
        }
        
        if message.name == "imageUrlMessage", let imageUrls = message.body as? [Any] {
            print(imageUrls)
            return
        }
        
        if message.name == "jsLog" {
            if let log = message.body as? String {
                print("JavaScript log: \(log)")
            }
            return
        }
        
        if message.name == "jsError" {
            if let errorMessage = message.body as? String {
                print("JavaScript Error: \(errorMessage)")
            }
            return
        }
    }
}
