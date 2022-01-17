//
//  ClipImageViewController.swift
//  wutong
//
//  Created by Jeejio on 2021/12/29.
//

import UIKit

class ClipImageViewController: UIViewController {
    private let bottomToolViewH: CGFloat = 90
    private let clipRatioItemSize: CGSize = CGSize(width: 60, height: 70)
    private let model: PhotoModel?
    private var editImage = UIImage()
    private let originalImage: UIImage
    /// 用作进入裁剪界面首次动画frame
    var presentAnimateFrame: CGRect?
    
    /// 用作进入裁剪界面首次动画和取消裁剪时动画的image
    var presentAnimateImage: UIImage?
    
    /// 取消裁剪时动画frame
    var cancelClipAnimateFrame: CGRect = .zero
    
    private var viewDidAppearCount = 0
            
    /// 初次进入界面时候，裁剪范围
    var editRect: CGRect
    
    private var scrollView = UIScrollView()
    private var containerView = UIView()
    private var imageView = UIImageView()
    private var shadowView = ClipShadowView()
    private var overlayView = ClipOverlayView(frame: .zero)
    private var navgationView = UIView()
    private var backButton = UIButton(type: .custom)
    private var doneButton = UIButton(type: .custom)
    private var navtitleLabel = UILabel()
   
    private var gridPanGes: UIPanGestureRecognizer!

    private var shouldLayout = true
        
    private var beginPanPoint: CGPoint = .zero
    
    private var clipBoxFrame: CGRect = .zero
        
    private lazy var maxClipFrame: CGRect = {
        var rect = CGRect.zero
        rect.origin.x = 15
        rect.origin.y = kStatusBarHeight
        rect.size.width = UIScreen.main.bounds.width - 15 * 2
        rect.size.height = UIScreen.main.bounds.height - kStatusBarHeight - bottomToolViewH - clipRatioItemSize.height - 25
        return rect
    }()
    
    private var minClipSize = CGSize(width: 45, height: 45)
        
    private var dismissAnimateFromRect: CGRect = .zero
    
    private var dismissAnimateImage: UIImage?
    
    var cancelClipBlock: PhotoCompletionHandler?
    var imageClipBlock: PhotoCompletionObjectHandler<UIImage>?

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    init(model: PhotoModel, image: UIImage) {
        self.model = model
        self.editRect = .zero
        self.originalImage = image
        self.editImage = self.originalImage
        super.init(nibName: nil, bundle: nil)
        calculateClipRect()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.initialAppearance()
        self.viewDidAppearCount += 1
        
        guard self.viewDidAppearCount == 1 else {
            return
        }
        /// 当前页面为push进入， 放在viewDidAppear在进行动画比较生硬
        if let frame = self.presentAnimateFrame, let image = self.presentAnimateImage {
            let animateImageView = UIImageView(image: image)
            animateImageView.contentMode = .scaleAspectFill
            animateImageView.clipsToBounds = true
            animateImageView.frame = frame
            self.view.addSubview(animateImageView)
            
            self.cancelClipAnimateFrame = self.clipBoxFrame
            UIView.animate(withDuration: 0.25, animations: {
                animateImageView.frame = self.clipBoxFrame
            }) { (_) in
                UIView.animate(withDuration: 0.1, animations: {
                    self.scrollView.alpha = 1
                    self.overlayView.alpha = 1
                }) { (_) in
                    animateImageView.removeFromSuperview()
                }
            }
        } else {
            self.scrollView.alpha = 1
            self.overlayView.alpha = 1
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        guard self.shouldLayout else {
            return
        }
        self.shouldLayout = false
        
        self.scrollView.frame = self.view.bounds
        self.shadowView.frame = self.view.bounds
        
        self.layoutInitialImage()
        
        self.navgationView.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: kNavHeight)
        self.backButton.frame = CGRect(x: 0, y: kStatusBarHeight, width: 60, height: 44)
        self.navtitleLabel.frame = CGRect(x: 0, y: kStatusBarHeight, width: 200, height: 44)
        self.navtitleLabel.center.x = self.navgationView.center.x
        self.doneButton.frame = CGRect(x: self.view.bounds.width - 60, y: kStatusBarHeight, width: 60, height: 44)
    }
    
    func initialAppearance() {
        self.view.backgroundColor = .black
        
        self.scrollView = UIScrollView()
        self.scrollView.alwaysBounceVertical = true
        self.scrollView.alwaysBounceHorizontal = true
        self.scrollView.showsVerticalScrollIndicator = false
        self.scrollView.showsHorizontalScrollIndicator = false
        if #available(iOS 11.0, *) {
            self.scrollView.contentInsetAdjustmentBehavior = .never
        } else {
            // Fallback on earlier versions
        }
        self.scrollView.delegate = self
        self.view.addSubview(self.scrollView)
        
        self.containerView = UIView()
        self.scrollView.addSubview(self.containerView)
        
        self.imageView = UIImageView(image: self.editImage)
        self.imageView.contentMode = .scaleAspectFit
        self.imageView.clipsToBounds = true
        self.containerView.addSubview(self.imageView)
        
        self.shadowView.isUserInteractionEnabled = false
        self.shadowView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        self.view.addSubview(self.shadowView)
        
        self.view.addSubview(self.overlayView)
        
        navgationView.backgroundColor = .white
        self.view.addSubview(self.navgationView)
        
        self.backButton = UIButton(type: .custom)
        self.backButton.setImage(getImage("nav_back"), for: .normal)
        self.backButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: 0)
        self.backButton.addTarget(self, action: #selector(cancelBtnClick), for: .touchUpInside)
        self.navgationView.addSubview(self.backButton)
        
        navtitleLabel.adjustsFontSizeToFitWidth = true
        navtitleLabel.font = .regular(ofSize: 16)
        navtitleLabel.textColor = .black
        navtitleLabel.textAlignment = .center
        navtitleLabel.text = "移动和缩放"
        self.navgationView.addSubview(navtitleLabel)
        
        doneButton.titleLabel?.font = .regular(ofSize: 15)
        doneButton.setTitle("完成", for: .normal)
        doneButton.setTitleColor(RGB(90, 144, 251), for: .normal)
        doneButton.addTarget(self, action: #selector(doneBtnClick), for: .touchUpInside)
        self.navgationView.addSubview(doneButton)
        self.doneButton.adjustsImageWhenHighlighted = false
                
        self.scrollView.alpha = 0
        self.overlayView.alpha = 0
        
        self.gridPanGes = UIPanGestureRecognizer(target: self, action: #selector(gridGesPanAction(_:)))
        self.gridPanGes.delegate = self
        self.view.addGestureRecognizer(self.gridPanGes)
        self.scrollView.panGestureRecognizer.require(toFail: self.gridPanGes) /// 设置pan手势 阻断scrollView原本的pan手势
    }
    
    func calculateClipRect() {
        self.editRect = CGRect(origin: .zero, size: self.editImage.size)
    }
    
    func layoutInitialImage() {
        self.scrollView.minimumZoomScale = 1
        self.scrollView.maximumZoomScale = 1
        self.scrollView.zoomScale = 1
        
        let editSize = self.editRect.size
        self.scrollView.contentSize = editSize
        let maxClipRect = self.maxClipFrame
        
        self.containerView.frame = CGRect(origin: .zero, size: self.editImage.size)
        self.imageView.frame = self.containerView.bounds
        
        // editRect比例，计算editRect所占frame
        let editScale = min(maxClipRect.width / editSize.width, maxClipRect.height / editSize.height)
        let scaledSize = CGSize(width: floor(editSize.width * editScale), height: floor(editSize.height * editScale))
        
        var frame = CGRect.zero
        frame.size = scaledSize
        frame.origin.x = maxClipRect.minX + floor((maxClipRect.width - frame.width) / 2)
        frame.origin.y = maxClipRect.minY + floor((maxClipRect.height - frame.height) / 2)
        
        // 按照edit image进行计算最小缩放比例
        let originalScale = min(maxClipRect.width / self.editImage.size.width, maxClipRect.height / self.editImage.size.height)
        // 将 edit rect 相对 originalScale 进行缩放，缩放到图片未放大时候的clip rect
        let scaleEditSize = CGSize(width: self.editRect.width * originalScale, height: self.editRect.height * originalScale)
        // 计算缩放后的clip rect相对maxClipRect的比例
        let clipRectZoomScale = min(maxClipRect.width / scaleEditSize.width, maxClipRect.height / scaleEditSize.height)
        
        self.scrollView.minimumZoomScale = originalScale
        self.scrollView.maximumZoomScale = 10
        // 设置当前zoom scale
        let zoomScale = (clipRectZoomScale * originalScale)
        self.scrollView.zoomScale = zoomScale
        self.scrollView.contentSize = CGSize(width: self.editImage.size.width * zoomScale, height: self.editImage.size.height * zoomScale)
        
        self.changeClipBoxFrame(newFrame: frame)
        
        if (frame.size.width < scaledSize.width - CGFloat.ulpOfOne) || (frame.size.height < scaledSize.height - CGFloat.ulpOfOne) {
            var offset = CGPoint.zero
            offset.x = -floor((self.scrollView.frame.width - scaledSize.width) / 2)
            offset.y = -floor((self.scrollView.frame.height - scaledSize.height) / 2)
            self.scrollView.contentOffset = offset
        }
        
        // edit rect 相对 image size 的 偏移量
        let diffX = self.editRect.origin.x / self.editImage.size.width * self.scrollView.contentSize.width
        let diffY = self.editRect.origin.y / self.editImage.size.height * self.scrollView.contentSize.height
        self.scrollView.contentOffset = CGPoint(x: -self.scrollView.contentInset.left + diffX, y: -self.scrollView.contentInset.top + diffY)
    }
    
    func changeClipBoxFrame(newFrame: CGRect) {
        guard self.clipBoxFrame != newFrame else {
            return
        }
        if newFrame.width < CGFloat.ulpOfOne || newFrame.height < CGFloat.ulpOfOne {
            return
        }
        var frame = newFrame
        frame = CGRect(x: 15, y: (kScreenHeight - (kScreenWidth - 30)) / 2, width: (kScreenWidth - 30), height: (kScreenWidth - 30))
        let originX = ceil(self.maxClipFrame.minX)
        let diffX = frame.minX - originX
        frame.origin.x = max(frame.minX, originX)
        if diffX < -CGFloat.ulpOfOne {
            frame.size.width += diffX
        }
        let originY = ceil(self.maxClipFrame.minY)
        let diffY = frame.minY - originY
        frame.origin.y = max(frame.minY, originY)
        if diffY < -CGFloat.ulpOfOne {
            frame.size.height += diffY
        }
        let maxW = self.maxClipFrame.width + self.maxClipFrame.minX - frame.minX
        frame.size.width = max(self.minClipSize.width, min(frame.width, maxW))
        
        let maxH = self.maxClipFrame.height + self.maxClipFrame.minY - frame.minY
        frame.size.height = max(self.minClipSize.height, min(frame.height, maxH))
        
        self.clipBoxFrame = frame
        self.shadowView.clearRect = frame
        self.overlayView.frame = frame
        
        self.scrollView.contentInset = UIEdgeInsets(top: frame.minY, left: frame.minX, bottom: self.scrollView.frame.maxY - frame.maxY, right: self.scrollView.frame.maxX - frame.maxX)
        
        let scale = max(frame.height / self.editImage.size.height, frame.width / self.editImage.size.width)
        self.scrollView.minimumZoomScale = scale
        
        self.scrollView.zoomScale = self.scrollView.zoomScale
    }
    
    @objc func cancelBtnClick() {
        self.dismissAnimateFromRect = self.cancelClipAnimateFrame
        self.dismissAnimateImage = self.presentAnimateImage
        self.cancelClipBlock?()
        self.navigationController?.dismiss(animated: true, completion: nil)
    }

    @objc func doneBtnClick() {
        let image = clipImage()
        dismissAnimateFromRect = clipBoxFrame
        dismissAnimateImage = image.clipImage
        self.imageClipBlock?(image.clipImage)
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
    @objc func gridGesPanAction(_ pan: UIPanGestureRecognizer) {
        // 后续需要改变裁剪框大小时， 在此处理UIScrollView的手势
    }
    
    func clipImage() -> (clipImage: UIImage, editRect: CGRect) {
        let frame = self.convertClipRectToEditImageRect()
        let clipImage = self.editImage.clipImage(editRect: frame, isCircle: false) ?? self.editImage
        return (clipImage, frame)
    }
    
    func convertClipRectToEditImageRect() -> CGRect {
        let imageSize = self.editImage.size
        let contentSize = self.scrollView.contentSize
        let offset = self.scrollView.contentOffset
        let insets = self.scrollView.contentInset
        
        var frame = CGRect.zero
        frame.origin.x = floor((offset.x + insets.left) * (imageSize.width / contentSize.width))
        frame.origin.x = max(0, frame.origin.x)
        
        frame.origin.y = floor((offset.y + insets.top) * (imageSize.height / contentSize.height))
        frame.origin.y = max(0, frame.origin.y)
        
        frame.size.width = ceil(self.clipBoxFrame.width * (imageSize.width / contentSize.width))
        frame.size.width = min(imageSize.width, frame.width)
        
        frame.size.height = ceil(self.clipBoxFrame.height * (imageSize.height / contentSize.height))
        frame.size.height = min(imageSize.height, frame.height)
        
        return frame
    }
}

extension ClipImageViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer == self.gridPanGes else {
            return true
        }
        let point = gestureRecognizer.location(in: self.view)
        let frame = self.overlayView.frame
        let innerFrame = frame.insetBy(dx: 22, dy: 22)
        let outerFrame = frame.insetBy(dx: -22, dy: -22)
        
        if innerFrame.contains(point) || !outerFrame.contains(point) {
            return false
        }
        return true
    }
}
class ClipShadowView: UIView {
    var clearRect: CGRect = .zero {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
        self.isOpaque = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        UIColor(white: 0, alpha: 0.7).setFill()
        UIRectFill(rect)
        let cr = self.clearRect.intersection(rect)
        UIColor.clear.setFill()
        UIRectFill(cr)
    }
}
// MARK: 裁剪视图
class ClipOverlayView: UIImageView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
        self.image = getImage("imageClippingMask")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ClipImageViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.containerView
    }
    
    /// 在此处理以后可能需要 改变clip大小
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        guard scrollView == self.scrollView else {
            return
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        guard scrollView == self.scrollView else {
            return
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView == self.scrollView else {
            return
        }
      }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard scrollView == self.scrollView else {
            return
        }
      }
}
