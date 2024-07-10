import SwiftUI
import UIKit

struct GIFImage: UIViewRepresentable {
    let name: String

    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        
        if let asset = NSDataAsset(name: name) {
            let image = UIImage.gifImageWithData(asset.data)
            imageView.image = image
        } else {
            print("Couldn't find \(name) in assets")
        }
        
        return imageView
    }

    func updateUIView(_ uiView: UIImageView, context: Context) {}
}

extension UIImage {
    static func gifImageWithData(_ data: Data) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let count = CGImageSourceGetCount(source)
        var images = [UIImage]()
        var duration: Double = 0
        
        for i in 0..<count {
            if let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) {
                if let properties = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [String: Any],
                   let gifProperties = properties[kCGImagePropertyGIFDictionary as String] as? [String: Any] {
                    if let delayTime = gifProperties[kCGImagePropertyGIFDelayTime as String] as? Double {
                        duration += delayTime
                    }
                }
                images.append(UIImage(cgImage: cgImage))
            }
        }
        
        let gifImage = UIImage.animatedImage(with: images, duration: duration)
        return gifImage
    }
}
