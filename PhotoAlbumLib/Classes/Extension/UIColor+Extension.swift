//
//  UIColor+Extension.swift
//  wutong
//
//  Created by blur on 2021/5/5.
//

import UIKit

/**
 Wutong's brand colors used throughout the app.

 Black and white colors are often paired with an opacity and in those cases, should be generated using the `black(opacity)` and `white(opacity)` functions.
 */
// MARK: - Initializers
extension UIColor {
    /// r 89
    /// g 31
    /// b 204
    /// a 1
    /// An alias for blue since some people thing FM668 is purple when it is actually blue.
//    static let mainBlue = UIColor(red: 89, green: 31, blue: 204)

    /**
     Generate a transparent white color.
     - parameters:
     - opacity: The opacity value as a CGFloat between 0.0 and 1.0.
     - returns:
     A white color with the provided opacity.
     */
    class func white(_ opacity: CGFloat) -> UIColor {
        return UIColor(white: 1.0, alpha: opacity)
    }

    /**
     Generate an opaque black color.
     - parameters:
     - opacity: The opacity value as a CGFloat between 0.0 and 1.0.
     - returns:
     A black color with the provided opacity.
     */
    class func black(_ opacity: CGFloat) -> UIColor {
        return UIColor(white: 0.0, alpha: opacity)
    }

    /// Random color.
    static var random: UIColor {
        let red = Int(arc4random_uniform(128)) + 128
        let green = Int(arc4random_uniform(128)) + 128
        let blue = Int(arc4random_uniform(128)) + 128
        return UIColor(red: red, green: green, blue: blue)
    }

    /// Create Color from RGB values with optional transparency.
    ///
    /// - Parameters:
    ///   - red: red component.
    ///   - green: green component.
    ///   - blue: blue component.
    ///   - transparency: optional transparency value (default is 1).
    convenience init(red: Int, green: Int, blue: Int, transparency: CGFloat = 1) {
        var redComponent = red
        if red < 0 { redComponent = 0 }
        if red > 255 { redComponent = 255 }

        var greenComponent = green
        if green < 0 { greenComponent = 0 }
        if green > 255 { greenComponent = 255 }

        var blueComponent = blue
        if blue < 0 { blueComponent = 0 }
        if blue > 255 { blueComponent = 255 }

        var trans = transparency
        if trans < 0 { trans = 0 }
        if trans > 1 { trans = 1 }

        self.init(red: CGFloat(redComponent) / 255.0, green: CGFloat(greenComponent) / 255.0, blue: CGFloat(blueComponent) / 255.0, alpha: trans)
    }

    /// Create Color from hexadecimal value with optional transparency.
    ///
    /// - Parameters:
    ///   - hex: hex Int (example: 0xDECEB5).
    ///   - transparency: optional transparency value (default is 1).
    convenience init(hex: Int, transparency: CGFloat = 1) {
        let red = (hex >> 16) & 0xff
        let green = (hex >> 8) & 0xff
        let blue = hex & 0xff
        self.init(red: red, green: green, blue: blue, transparency: transparency)
    }

    /// Create Color from hexadecimal string.
    ///
    /// - Parameter hexString: hex Int (example: "0xDECEB5" for rgb or "0xDECEB5FF" for rgba).
    convenience init(hexString: String) {
        var hexStr = hexString

        // remove common prefix
        if hexStr.hasPrefix("#") {
            hexStr = hexStr.sub(from: 1)
        }

        if hexStr.hasPrefix("0x") {
            hexStr = hexStr.sub(from: 2)
        }

        var r: Int = 0
        var g: Int = 0
        var b: Int = 0
        var a: CGFloat = 1

        var argb: UInt64 = 0
        // scan hex value to rgba
        let scanner = Scanner(string: hexStr)
        if scanner.scanHexInt64(&argb) {
            switch hexStr.count {
            case 8: // a
                a = CGFloat((argb >> 24) & 0xff) / 0xff
                fallthrough
            case 6: // rgb
                r = Int((argb >> 16) & 0xff)
                g = Int((argb >> 8) & 0xff)
                b = Int((argb) & 0xff)
            default:
                break
            }
        }
        self.init(red: r, green: g, blue: b, transparency: a)
    }
}
