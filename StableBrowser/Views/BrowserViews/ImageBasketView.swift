import SwiftUI

struct ImageBasketView: View {
    var parent: BrowserView
    var img_tag: String?
    var body: some View {
        VStack {
            Image(systemName: "photo.badge.plus")
                .font(.system(size: 40))
                .foregroundColor(.blue)
            Text("Drop image").fontWeight(.semibold)
        }
        .frame(width: 110, height: 110)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 5)
        .onTapGesture {
            parent.hideImageBasket()
        }
        .onDrop(of: [.image], isTargeted: nil) { providers in
            parent.hideImageBasket()
            providers.first?.loadObject(ofClass: UIImage.self) { image, error in
                if let image = image as? UIImage {
                    DispatchQueue.main.async {
                        parent.showSDView(with: image)
                    }
                }else {
                    if let img_tag = img_tag {
                        onImageDroppedTag(tag: img_tag) {
                            rst in
                        }
                    }
                }
            }
            return true
        }
    }
    
    func onImageDroppedTag(tag: String, completion: @escaping (Bool) -> Void) {
        parent.hideImageBasket()
        // Find the URL after "src=" in the tag and convert it to a URL
        let pattern = " src=\"[^ ]*?\""
        if let range = tag.range(of: pattern, options: .regularExpression) {
            var urlString = String(tag[range])

            // If it is a base64 image
            if urlString.contains("data:image") {
                let base64 = urlString.replacingOccurrences(of: "src=\"", with: "")
                .replacingOccurrences(of: "\"", with: "")
                .replacingOccurrences(of: "data:image/png;base64,", with: "")                
                .replacingOccurrences(of: "data:image/jpeg;base64,", with: "")
                .replacingOccurrences(of: "data:image/jpg;base64,", with: "")
                .replacingOccurrences(of: "data:image/gif;base64,", with: "")
                .replacingOccurrences(of: "data:image/webp;base64,", with: "")
                downloadImageBase64(from: base64) {
                    result in completion(result)
                }
                
            }
            // If it is not a base64 image
            else {
                // Add "https:" to urlString if it doesn't contain "https"
                if !urlString.contains("https") {
                    urlString = urlString.replacingOccurrences(of: "src=\"", with: "src=\"https:")
                }  
                let url = urlString.replacingOccurrences(of: " src=\"", with: "").replacingOccurrences(of: "\"", with: "")
                if let imageUrl = URL(string: url) {
                    downloadImage(from: imageUrl) {
                        result in completion(result)
                    }
                } else {
                    print("No valid image URL found in the string.")
                }
            }
        } else {
            completion(false)
        }
    }
    
    func onImageDroppedUrl(url: URL) {
        parent.hideImageBasket()
        let urlString = url.absoluteString
        // URL 패턴을 수정하여 첫 번째로 발견된 URL만 추출하도록 함
        let pattern = "http[^ ]*?\\.(jpg|jpeg|png|gif|webp|JPG|JPEG|PNG|GIF|WEBP)"
        
        if let range = urlString.range(of: pattern, options: .regularExpression), let imageUrl = URL(string: String(urlString[range])) {
            downloadImage(from: imageUrl) {
                result in
                    print(result)
            }
        } else {
            print(urlString)
            print("No valid image URL found in the string.")
        }
    }
    
    
    func downloadImage(from url: URL, completion: @escaping (Bool) -> Void) {
        // .jpg, .png, .gif 로 끝나는 url 주소만 UIImage로 변환
        if url.absoluteString.contains(".jpg")
        || url.absoluteString.contains(".jpeg")
        || url.absoluteString.contains(".png")
        || url.absoluteString.contains(".gif")
        || url.absoluteString.contains(".webp")
        {
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self.parent.showSDView(with: image)
                    }
                    completion(true)
                }else {
                    completion(false)
                }
            }.resume()
        }else {
            completion(false)
        }
    }

    func downloadImageBase64(from base64: String, completion: @escaping (Bool) -> Void) {
        if let data = Data(base64Encoded: base64) {
            if let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    parent.showSDView(with: image)
                }
                completion(true)
            }else {
                completion(false)
            }
        }else {
            completion(false)
        }
    }
        
    
}
