//
//  VideoSlider.swift
//  wutong
//
//  Created by Jeejio on 2021/12/29.
//

import UIKit

class VideoSlider: UISlider {
    private var lastBounds = CGRect()
    private let sliderY = 40.0
    private let sliderX = 30.0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialAppearance()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func initialAppearance() {
        let image = UIImage.imageWithColor(.white, size: CGSize(width: 12, height: 12), radius: 6)
        self.minimumTrackTintColor  = .white
        self.setThumbImage(image, for: .highlighted)
        self.setThumbImage(image, for: .normal)
    }
    
    /// 控制slider的高度
    override func trackRect(forBounds bounds: CGRect) -> CGRect {
        super.trackRect(forBounds: bounds)
        return CGRect(x: bounds.origin.x, y: bounds.origin.y, width: bounds.width, height: 2)
    }
    
    override func thumbRect(forBounds bounds: CGRect, trackRect rect: CGRect, value: Float) -> CGRect {
        var rect = rect
        rect.origin.x -= 6
        rect.size.width += 12
        let result = super.thumbRect(forBounds: bounds, trackRect: rect, value: value)
        self.lastBounds = result
        return result
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        var result = super.hitTest(point, with: event)
        if result != self {
            /*如果这个view不是self,我们给slider扩充一下响应范围,
             这里的扩充范围数据就可以自己设置了
             */
            if point.y >= -15, point.y < (lastBounds.size.height + sliderY), point.x >= 0, point.x < self.bounds.width {
                /// 如果在这个填充的范围里面，就将这个event的处理权交给self
                result = self
            }
        }
        
        return result
    }
    /// 检查是点击事件的点是否在slider范围内
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        var result = super.point(inside: point, with: event)
        if !result {
            /// 如果不在slider的范围里面，扩充相应范围
            if point.x >= lastBounds.origin.x - sliderX, point.x <= lastBounds.origin.x + lastBounds.size.width + sliderX, point.y >= -sliderY, point.y < lastBounds.size.height + sliderY {
                result = true
            }
        }
        return result
    }
}
