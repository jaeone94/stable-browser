import UIKit

extension UIApplication {
    func hideKeyboard() {
        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        guard let window = windowScene?.windows.first else { return }
        
        let tapRecognizer = UITapGestureRecognizer(target: window, action: #selector(UIView.endEditing))
        tapRecognizer.cancelsTouchesInView = false
        tapRecognizer.delegate = self
        window.addGestureRecognizer(tapRecognizer)
    }
}

extension UIApplication: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
}

extension UIView {
    func showToast(message: String, duration: TimeInterval = 3.0) {
        let toastLabel = UILabel(frame: CGRect(x: self.frame.size.width / 2 - 75, y: self.frame.size.height - 100, width: 150, height: 35))
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        toastLabel.textColor = UIColor.white
        toastLabel.textAlignment = .center;
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10;
        toastLabel.clipsToBounds  =  true
        self.addSubview(toastLabel)
        UIView.animate(withDuration: duration, delay: 0.1, options: .curveEaseOut, animations: {
            toastLabel.alpha = 0.0
        }, completion: {(isCompleted) in
            toastLabel.removeFromSuperview()
        })
    }
}

extension UIImage {
    func resized(withPercentage percentage: CGFloat) -> UIImage? {
        let canvasSize = CGSize(width: size.width * percentage, height: size.height * percentage)
        UIGraphicsBeginImageContextWithOptions(canvasSize, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: canvasSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    func resizedImage(toScale scale: CGFloat) -> UIImage? {
        let newSize = CGSize(width: self.size.width * scale, height: self.size.height * scale)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        self.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage
    }
    
    func cropToNearest8Multiple() -> UIImage? {
        guard let cgImage = self.cgImage else { return nil }

        let width = cgImage.width
        let height = cgImage.height
        let adjustedWidth = width - (width % 8)
        let adjustedHeight = height - (height % 8)
        
        let xOffset = (width - adjustedWidth) / 2
        let yOffset = (height - adjustedHeight) / 2
        
        let rect = CGRect(x: xOffset, y: yOffset, width: adjustedWidth, height: adjustedHeight)
        guard let croppedCgImage = cgImage.cropping(to: rect) else { return nil }

        return UIImage(cgImage: croppedCgImage, scale: self.scale, orientation: self.imageOrientation)
    }
    
    func resizeTargetImageToMatchSource(src: UIImage) -> UIImage {
        let deviceScale = UIScreen.main.scale // Get the device scale factor
        let srcSize = src.size // Get the source image size
        let srcScale = src.scale // Get the source image scale
        
        let scale1SrcSize = CGSize(width: srcSize.width * srcScale, height: srcSize.height * srcScale)
        let adjustTargetSizeUsingDeviceScale = CGSize(width: scale1SrcSize.width / deviceScale, height: scale1SrcSize.height / deviceScale)
        
        let renderer = UIGraphicsImageRenderer(size: adjustTargetSizeUsingDeviceScale)
        let resizedImage = renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: adjustTargetSizeUsingDeviceScale))
        }
        
        return UIImage(cgImage: resizedImage.cgImage!, scale: 1, orientation: resizedImage.imageOrientation)
    }

}

extension CGSize {
    // CGSize의 너비와 높이를 8의 배수 중 가장 가까운 큰 값으로 조정하는 함수
    func adjustedToNearest8Multiple() -> CGSize {
        let width = Int(self.width)
        let height = Int(self.height)
        let adjustedWidth = width + (8 - width % 8) % 8
        let adjustedHeight = height + (8 - height % 8) % 8
        return CGSize(width: adjustedWidth, height: adjustedHeight)
    }
}
