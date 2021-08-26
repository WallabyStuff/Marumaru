//
//  ViewGlobalExtension.swift
//  Marumaru
//
//  Created by 이승기 on 2021/08/08.
//

import UIKit

extension UIButton {
    
    // set image edge insets with same value
    func imageEdgeInsets(with width: CGFloat) {
        self.imageEdgeInsets = UIEdgeInsets(top: width,
                                            left: width,
                                            bottom: width,
                                            right: width)
    }
    
}

public extension UIImage {
    
    // return image's average color
    var averageColor: UIColor? {
        guard let inputImage = CIImage(image: self) else { return nil }
        let extentVector = CIVector(x: inputImage.extent.origin.x, y: inputImage.extent.origin.y, z: inputImage.extent.size.width, w: inputImage.extent.size.height)

        guard let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: inputImage, kCIInputExtentKey: extentVector]) else { return nil }
        guard let outputImage = filter.outputImage else { return nil }

        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: kCFNull])
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)

        return UIColor(red: CGFloat(bitmap[0]) / 255, green: CGFloat(bitmap[1]) / 255, blue: CGFloat(bitmap[2]) / 255, alpha: CGFloat(bitmap[3]) / 255)
    }
    
    func isEmpty() -> Bool {
        return self.size.width == 0 ? true : false
    }
}

public extension UIView {
    
    // start fade in animation
    func startFadeInAnim(duration: Double) {
        self.alpha = 0
        UIView.animate(withDuration: duration) {
            self.alpha = 1
        }
    }
    
    // start fade out animation
    func startFadeOutAnim(duration: Double) {
        UIView.animate(withDuration: duration) {
            self.alpha = 0
        }
    }
    
    // view from safeArea
    var xFromSafeArea: CGFloat {
        self.frame.origin.x + SafeAreaInset.left
    }
    
    var yFromSafeArea: CGFloat {
        self.frame.origin.y + SafeAreaInset.top
    }
    
    // thumbnail image shadow (default)
    func setThubmailShadow() {
        self.layer.shadowColor = ColorSet.shadowColor?.cgColor
        self.layer.shadowOffset = .zero
        self.layer.shadowRadius = 7
        self.layer.shadowOpacity = 0.6
        self.layer.masksToBounds = false
        self.layer.borderWidth = 0
        self.layer.shouldRasterize = true
    }
    
    // thumbnail image shadow with custom color
    func setThumbnailShadow(with color: CGColor) {
        self.layer.shadowColor = color
        self.layer.shadowOffset = .zero
        self.layer.shadowRadius = 7
        self.layer.shadowOpacity = 0.9
        self.layer.masksToBounds = false
        self.layer.borderWidth = 0
        self.layer.shouldRasterize = true
    }
}

public extension UILabel {
    
    func makeRoundedBackground(cornerRadius: CGFloat, backgroundColor: UIColor, foregroundColor: UIColor) {
        self.clipsToBounds = true
        self.backgroundColor = backgroundColor
        self.textColor = foregroundColor
        self.layer.cornerRadius = cornerRadius
        self.text = "  \(self.text!)  "
    }
    
    func removeRoundedBackground(foregroundColor: UIColor) {
        self.backgroundColor = .clear
        self.textColor = foregroundColor
    }
}

public extension UIColor {
    
    // UIColor -> HexString
    func toHexString() -> String {
        var r:CGFloat = 0
        var g:CGFloat = 0
        var b:CGFloat = 0
        var a:CGFloat = 0

        getRed(&r, green: &g, blue: &b, alpha: &a)

        let rgb:Int = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0

        return String(format:"#%06x", rgb)
    }
    
    // HexString -> UIColor
    convenience init(hexString: String) {
            let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
            var int = UInt64()
            Scanner(string: hex).scanHexInt64(&int)
            let a, r, g, b: UInt64
            switch hex.count {
            case 3: // RGB (12-bit)
                (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
            case 6: // RGB (24-bit)
                (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
            case 8: // ARGB (32-bit)
                (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
            default:
                (a, r, g, b) = (255, 0, 0, 0)
            }
            self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
        }
    
    static var patternedColor: UIColor {
        let tileImage = UIImage(named: "Tile")!
        let patternBackground = UIColor(patternImage: tileImage)
        return patternBackground
    }
}
