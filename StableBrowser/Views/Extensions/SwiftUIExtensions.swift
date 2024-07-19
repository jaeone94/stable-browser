import SwiftUI

extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

extension Color {
    init?(cssColor: String) {
        // Regular expression to match both rgb and rgba formats
        let rgbaPattern = "rgba?\\((\\d+),\\s*(\\d+),\\s*(\\d+)(?:,\\s*(\\d+(?:\\.\\d+)?))?\\)"
        
        guard let regex = try? NSRegularExpression(pattern: rgbaPattern),
              let match = regex.firstMatch(in: cssColor, options: [], range: NSRange(cssColor.startIndex..., in: cssColor)) else {
            return nil
        }
        
        let components = (1..<regex.numberOfCaptureGroups+1).compactMap { groupIndex -> Double? in
            let range = match.range(at: groupIndex)
            guard let substringRange = Range(range, in: cssColor) else { return nil }
            return Double(cssColor[substringRange])
        }
        
        guard components.count >= 3 else { return nil }
        
        let red = components[0] / 255
        let green = components[1] / 255
        let blue = components[2] / 255
        let alpha = components.count == 4 ? components[3] : 1
        
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}

extension UIColor {
    convenience init?(cssColor: String) {
        let pattern = #"rgb\((\d+),\s*(\d+),\s*(\d+)\)"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: cssColor, range: NSRange(location: 0, length: cssColor.count)),
              match.numberOfRanges == 4 else {
            return nil
        }
        
        let rRange = match.range(at: 1)
        let gRange = match.range(at: 2)
        let bRange = match.range(at: 3)
        
        guard let rString = Range(rRange, in: cssColor),
              let gString = Range(gRange, in: cssColor),
              let bString = Range(bRange, in: cssColor),
              let r = Float(String(cssColor[rString])),
              let g = Float(String(cssColor[gString])),
              let b = Float(String(cssColor[bString])) else {
            return nil
        }
        
        let red = CGFloat(r) / 255.0
        let green = CGFloat(g) / 255.0
        let blue = CGFloat(b) / 255.0
        
        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
    
    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        var r: CGFloat = 0.0
        var g: CGFloat = 0.0
        var b: CGFloat = 0.0
        var a: CGFloat = 1.0

        let length = hexSanitized.count

        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        if length == 6 {
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgb & 0x0000FF) / 255.0

        } else if length == 8 {
            r = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            g = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
            a = CGFloat(rgb & 0x000000FF) / 255.0

        } else {
            return nil
        }

        self.init(red: r, green: g, blue: b, alpha: a)
    }

    var luminance: CGFloat {
        let rgba = rgbComponents
        return 0.2126 * rgba.r + 0.7152 * rgba.g + 0.0722 * rgba.b
    }

    var rgbComponents: (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return (r, g, b, a)
    }
}



struct VisualEffectBlur: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: blurStyle)
    }
}

struct TransparentBackground: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        DispatchQueue.main.async {
            view.superview?.superview?.backgroundColor = .clear
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
