//
//  UIView+Extention.swift
//  PhotoPickerTest
//
//  Created by hxl on 2022/1/14.
//

import UIKit

extension CGRect {
    var center: CGPoint {
        return CGPoint(x: width / 2, y: height / 2)
    }
}

@objc extension UIView {
    var origin: CGPoint {
        get {
            return self.frame.origin
        }
        set(newOrigin) {
            var frame = self.frame
            frame.origin = newOrigin
            self.frame = frame
        }
    }

    var x: CGFloat {
        get {
            return self.frame.origin.x
        }
        set(newX) {
            var frame = self.frame
            frame.origin.x = newX
            self.frame = frame
        }
    }

    var y: CGFloat {
        get {
            return self.frame.origin.y
        }

        set(newY) {
            var frame = self.frame
            frame.origin.y = newY
            self.frame = frame
        }
    }

    var screenX: CGFloat {
        var x = self.x
        var background = self
        while let superView = background.superview {
            x += superView.x
            background = superView
        }
        return x
    }

    var screenY: CGFloat {
        var y = self.y
        var background = self
        while let superView = background.superview {
            y += superView.y
            background = superView
        }
        return y
    }

    var size: CGSize {
        get {
            return self.frame.size
        }
        set(newSize) {
            var frame = self.frame
            frame.size = newSize
            self.frame = frame
        }
    }

    var width: CGFloat {
        get {
            return self.frame.size.width
        }

        set(newWidth) {
            var frame = self.frame
            frame.size.width = newWidth
            self.frame = frame
        }
    }

    var height: CGFloat {
        get {
            return self.frame.size.height
        }

        set(newHeight) {
            var frame = self.frame
            frame.size.height = newHeight
            self.frame = frame
        }
    }

    var maxX: CGFloat {
        return self.frame.maxX
    }

    var maxY: CGFloat {
        return self.frame.maxY
    }

    var centerX: CGFloat {
        get {
            return self.center.x
        }

        set(newCenterX) {
            var center = self.center
            center.x = newCenterX
            self.center = center
        }
    }

    var centerY: CGFloat {
        get {
            return self.center.y
        }

        set(newCenterY) {
            var center = self.center
            center.y = newCenterY
            self.center = center
        }
    }

    var left: CGFloat {
        get {
            return self.frame.origin.x
        }
        set (newValue) {
            var frame = self.frame
            frame.origin.x = newValue
            self.frame = frame
        }
    }

    var right: CGFloat {
        get {
            return self.frame.maxX
        }
        set (newValue) {
            var frame = self.frame
            frame.origin.x = newValue - frame.size.width
            self.frame = frame
        }
    }

    var top: CGFloat {
        get {
            return self.frame.origin.y
        }
        set (newValue) {
            var frame = self.frame
            frame.origin.y = newValue
            self.frame = frame
        }
    }

    var bottom: CGFloat {
        get {
            return self.frame.maxY
        }
        set (newValue) {
            var frame = self.frame
            frame.origin.y = newValue - frame.size.height
            self.frame = frame
        }
    }
}

extension UIView {
    @IBInspectable var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
        }
    }

    @IBInspectable var shadowRadius: CGFloat {
        get {
            return layer.shadowRadius
        }
        set {
            layer.shadowOffset = CGSize.zero
            layer.shadowColor = UIColor.black.cgColor
            layer.shadowOpacity = 0.5
            layer.shadowRadius = newValue
        }
    }

    /// SwifterSwift: Set some or all corners radiuses of view.
    ///
    /// - Parameters:
    ///   - corners: array of corners to change (example: [.bottomLeft, .topRight]).
    ///   - radius: radius for selected corners.
    func roundCorners(_ corners: UIRectCorner, radius: CGFloat) {
        let size = CGSize(width: radius, height: radius)
        let maskPath = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: size)

        let shape = CAShapeLayer()
        shape.path = maskPath.cgPath
        layer.mask = shape
    }

    /// SwifterSwift: Add shadow to view.
    ///
    /// - Parameters:
    ///   - color: shadow color (default is black).
    ///   - radius: shadow radius (default is 4).
    ///   - offset: shadow offset (default is .zero).
    ///   - opacity: shadow opacity (default is 0.5).
    func addShadow(_ color: UIColor = UIColor.black, radius: CGFloat = 4, offset: CGSize = .zero, opacity: Float = 0.5) {
        layer.shadowColor = color.cgColor
        layer.shadowOffset = offset
        layer.shadowRadius = radius
        layer.shadowOpacity = opacity
        layer.masksToBounds = false
    }

    func applySuperEllipseRound(_ bounds: CGRect, n: CGFloat = CGFloat(M_E)) {
        let maskLayer = CAShapeLayer()
        maskLayer.frame = bounds
        let path = UIBezierPath.superellipse(in: maskLayer.bounds, n: n).cgPath
        maskLayer.path = path
        maskLayer.fillColor = UIColor.white.cgColor
        self.layer.mask = maskLayer
        self.layer.masksToBounds = true
    }

    func applySuperEllipseRoundAndLayerLine(_ bounds: CGRect,
                                            n: CGFloat = CGFloat(M_E),
                                            lineWidth: CGFloat = 1,
                                            strokeColor: UIColor) {
        let maskLayer = CAShapeLayer()
        maskLayer.frame = bounds
        let path = UIBezierPath.superellipse(in: maskLayer.bounds, n: n).cgPath
        maskLayer.path = path
        maskLayer.fillColor = UIColor.white.cgColor
        self.layer.mask = maskLayer
        self.layer.masksToBounds = true

        let borderLayer = CAShapeLayer()
        borderLayer.path = path
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.strokeColor = strokeColor.cgColor
        borderLayer.lineWidth = lineWidth
        borderLayer.frame = self.bounds
        self.layer.addSublayer(borderLayer)
    }
}

extension UIView {
    /// get view controller
    var viewController: UIViewController? {
        var responder: UIResponder = self
        while let next = responder.next {
            if let vc = next as? UIViewController {
                return vc
            }
            responder = next
        }
        return nil
    }

    /// Creates a UIImage representation of the view
    func snapshot() -> UIImage? {
        defer { UIGraphicsEndImageContext() }

        UIGraphicsBeginImageContextWithOptions(self.size, isOpaque, 0)
        if let context = UIGraphicsGetCurrentContext() {
            layer.render(in: context)
        }

        return UIGraphicsGetImageFromCurrentImageContext()
    }

    func snapshot(snapshotLayer: CALayer?) -> UIImage? {
        let tempLayer = snapshotLayer ?? layer
        defer { UIGraphicsEndImageContext() }

        UIGraphicsBeginImageContextWithOptions(self.size, isOpaque, 0)
        if let context = UIGraphicsGetCurrentContext() {
            tempLayer.render(in: context)
        }

        return UIGraphicsGetImageFromCurrentImageContext()
    }

    func snapshotView() -> UIImage? {
        let render = UIGraphicsImageRenderer(size: bounds.size)
        let image = render.image { (ctx) in
            // Important to capture the presentation layer of the view for animation to be recorded
            layer.presentation()?.render(in: ctx.cgContext)
        }
        return image
//        UIGraphicsBeginImageContextWithOptions(frame.size, true, 0)
//        guard let context = UIGraphicsGetCurrentContext() else { return nil }
//        layer.presentation()?.render(in: context)
//        let rasterizedView = UIGraphicsGetImageFromCurrentImageContext()
//        UIGraphicsEndImageContext()
//        return rasterizedView
    }
}

// MARK: - convenience Animation
extension UIView {
    func startRotateAnimation() {
        let rotateAnimate = CAKeyframeAnimation(keyPath: "transform.rotation.z")
        let rotateDirection = CGFloat.pi / 12
        let duration = 0.4
        rotateAnimate.values = [
            -rotateDirection,
            0,
            rotateDirection,
            0,
            -rotateDirection
        ]
        rotateAnimate.timingFunctions = [CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)]
        rotateAnimate.duration = duration
        rotateAnimate.repeatCount = Float.infinity
        self.layer.add(rotateAnimate, forKey: "rotate")
    }
    
    func startAppRotateAnimation() {
        let keyAnimation = CAKeyframeAnimation(keyPath: "transform.rotation")
        keyAnimation.beginTime = CACurrentMediaTime()
        keyAnimation.duration = 0.5
        keyAnimation.values = [-CGFloat.pi / 20, CGFloat.pi / 20, -CGFloat.pi / 20]
        keyAnimation.repeatCount = MAXFLOAT
        keyAnimation.isRemovedOnCompletion = false
        self.layer.add(keyAnimation, forKey: "rotate")
    }

    func showFadeAnimation() {
        let fadeAnimate = CABasicAnimation(keyPath: "opacity")
        fadeAnimate.fromValue = 1
        fadeAnimate.toValue = 0
        fadeAnimate.duration = 2
        fadeAnimate.repeatCount = .infinity
        fadeAnimate.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        fadeAnimate.isRemovedOnCompletion = true
        self.layer.add(fadeAnimate, forKey: "fadeInOut")
    }

    func flipAnimation() {
        let flipAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        flipAnimation.fromValue = 0
        flipAnimation.toValue = Double.pi
        flipAnimation.duration = 0.2
        flipAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        flipAnimation.repeatCount = 1
        self.layer.add(flipAnimation, forKey: "flip")
    }

    func flickerAnimation() {
        let flickerAnimation = CABasicAnimation(keyPath: "hidden")
        flickerAnimation.fromValue = false
        flickerAnimation.toValue = true
        flickerAnimation.duration = 0.5
        flickerAnimation.repeatCount = .infinity
        flickerAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        flickerAnimation.isRemovedOnCompletion = true
        self.layer.add(flickerAnimation, forKey: "flicker")
    }
}

extension UIView {
    typealias IndicatorView = UIActivityIndicatorView

    func showBusyIndicator(style: IndicatorView.Style = .white, location: CGPoint? = nil) {
        DispatchQueue.main.async {
            let indicator = self.indicator ?? UIActivityIndicatorView(style: style)
            indicator.center = location ?? self.bounds.center
            self.addSubview(indicator)
            indicator.startAnimating()
        }
    }

    func hideBusyIndicator() {
        DispatchQueue.main.async {
            guard let indecator = self.indicator else {
                return
            }
            indecator.stopAnimating()
            indecator.removeFromSuperview()
        }
    }

    fileprivate var indicator: IndicatorView? {
        return subviews.first { $0 is IndicatorView } as? IndicatorView
    }
}

extension UIView {
    func getNestedSubviews<T: UIView>() -> [T] {
        return self.subviews.flatMap { subView -> [T] in
            var result = subView.getNestedSubviews() as [T]
            if let view = subView as? T {
                result.append(view)
            }
            return result
        }
    }
}
extension UIView {
    func findFirstResponder() -> UIView? {
        if self.isFirstResponder {
            return self
        } else {
            for sub in self.subviews {
                let  responder = sub.findFirstResponder()
                if responder != nil {
                    return responder
                }
            }
        }
        return nil
    }
}
