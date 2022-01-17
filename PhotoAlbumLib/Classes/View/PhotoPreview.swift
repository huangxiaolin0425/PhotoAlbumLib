//
//  PhotoPreview.swift
//  wutong
//
//  Created by Jeejio on 2021/12/28.
//

import UIKit
import Photos

class PhotoPreview: UIView {
    private let defaultMaxZoomScale: CGFloat = 3
    var scrollView = UIScrollView()
    var containerView = UIView()
    private var imageView = UIImageView()
    private var progressView = PhotoProgressView()
    var image: UIImage? {
        self.imageView.image
    }
    var singleTapBlock: PhotoCompletionHandler?
    
    var doubleTapBlock: PhotoCompletionHandler?
    
    var imageRequestID: PHImageRequestID = PHInvalidImageRequestID
    
    var gifImageRequestID: PHImageRequestID = PHInvalidImageRequestID
    
    var imageIdentifier: String = ""
    
    var onFetchingGif = false
    
    var fetchGifDone = false
    
    private var model: PhotoModel!
    private var photoConfig: PhotoConfiguration!

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initialAppearance()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.scrollView.frame = self.bounds
        self.progressView.frame = CGRect(x: self.bounds.width / 2 - 20, y: self.bounds.height / 2 - 20, width: 40, height: 40)
        self.scrollView.zoomScale = 1
        self.resetSubViewSize()
    }
    
    func initialAppearance() {
        self.scrollView.maximumZoomScale = defaultMaxZoomScale
        self.scrollView.minimumZoomScale = 1
        self.scrollView.isMultipleTouchEnabled = true
        self.scrollView.delegate = self
        self.scrollView.showsHorizontalScrollIndicator = false
        self.scrollView.showsVerticalScrollIndicator = false
        self.scrollView.delaysContentTouches = false
        addSubview(self.scrollView)
        
        self.scrollView.addSubview(self.containerView)
        
        self.imageView.contentMode = .scaleAspectFill
        self.imageView.clipsToBounds = true
        self.containerView.addSubview(self.imageView)
        
        addSubview(self.progressView)
        
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(singleTapAction(_:)))
        self.addGestureRecognizer(singleTap)
        
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubleTapAction(_:)))
        doubleTap.numberOfTapsRequired = 2
        self.addGestureRecognizer(doubleTap)
        
        singleTap.require(toFail: doubleTap)
    }
    
    @objc func singleTapAction(_ tap: UITapGestureRecognizer) {
        self.singleTapBlock?()
    }
    
    @objc func doubleTapAction(_ tap: UITapGestureRecognizer) {
        let scale: CGFloat = self.scrollView.zoomScale != self.scrollView.maximumZoomScale ? self.scrollView.maximumZoomScale : 1
        let tapPoint = tap.location(in: self)
        var rect = CGRect.zero
        rect.size.width = self.scrollView.frame.width / scale
        rect.size.height = self.scrollView.frame.height / scale
        rect.origin.x = tapPoint.x - (rect.size.width / 2)
        rect.origin.y = tapPoint.y - (rect.size.height / 2)
        self.scrollView.zoom(to: rect, animated: true)
    }
    
    func configure(model: PhotoModel, photoConfig: PhotoConfiguration) {
        self.model = model
        self.photoConfig = photoConfig
        if self.imageRequestID > PHInvalidImageRequestID {
            PHImageManager.default().cancelImageRequest(self.imageRequestID)
        }
        if self.gifImageRequestID > PHInvalidImageRequestID {
            PHImageManager.default().cancelImageRequest(self.gifImageRequestID)
        }
        
        self.scrollView.zoomScale = 1
        self.imageIdentifier = self.model.ident
        
        if photoConfig.allowSelectGif, self.model.type == .gif {
            self.loadGifFirstFrame()
        } else {
            self.loadPhoto()
        }
    }
    
    func requestPhotoSize(gif: Bool) -> CGSize {
        // gif 情况下优先加载一个小的缩略图
        var size = self.model.previewSize
        if gif {
            size.width /= 2
            size.height /= 2
        }
        return size
    }
    
    func loadPhoto() {
        self.imageRequestID = PhotoAlbumManager.fetchImage(for: self.model.asset, size: self.requestPhotoSize(gif: false), progress: { [weak self] (progress, _, _, _) in
            guard let self = self else { return }
            self.progressView.progress = progress
            if progress >= 1 {
                self.progressView.isHidden = true
            } else {
                self.progressView.isHidden = false
            }
        }, completion: { [weak self] (image, isDegraded) in
            guard let self = self else { return }
            guard self.imageIdentifier == self.model.ident else {
                return
            }
            self.imageView.image = image
            self.resetSubViewSize()
            if !isDegraded {
                self.progressView.isHidden = true
                self.imageRequestID = PHInvalidImageRequestID
            }
        })
    }
    
    func loadGifFirstFrame() {
        self.onFetchingGif = false
        self.fetchGifDone = false
        
        self.imageRequestID = PhotoAlbumManager.fetchImage(for: self.model.asset, size: self.requestPhotoSize(gif: true), completion: { [weak self] (image, _) in
            guard let self = self else { return }
            guard self.imageIdentifier == self.model.ident else {
                return
            }
            if self.fetchGifDone == false {
                self.imageView.image = image
                self.resetSubViewSize()
            }
        })
    }
    
    func loadGifData() {
        guard !self.onFetchingGif else {
            if self.fetchGifDone {
                self.resumeGif()
            }
            return
        }
        self.onFetchingGif = true
        self.fetchGifDone = false
        self.imageView.layer.speed = 1
        self.imageView.layer.timeOffset = 0
        self.imageView.layer.beginTime = 0
        self.gifImageRequestID = PhotoAlbumManager.fetchOriginalImageData(for: self.model.asset, progress: { [weak self] (progress, _, _, _) in
            guard let self = self else { return }
            self.progressView.progress = progress
            if progress >= 1 {
                self.progressView.isHidden = true
            } else {
                self.progressView.isHidden = false
            }
        }, completion: { [weak self] (data, _, isDegraded) in
            guard let self = self else { return }
            guard self.imageIdentifier == self.model.ident else {
                return
            }
            if !isDegraded {
                self.fetchGifDone = true
                if let data = data {
                    self.imageView.image = UIImage.animateGifImage(data: data)
                }
                self.resetSubViewSize()
            }
        })
    }
    
    func resetSubViewSize() {
        let size: CGSize
        if let _ = self.model {
            size = CGSize(width: self.model.asset.pixelWidth, height: self.model.asset.pixelHeight)
        } else {
            size = self.imageView.image?.size ?? self.bounds.size
        }
        
        var frame: CGRect = .zero
        
        let viewW = self.bounds.width
        let viewH = self.bounds.height
        
        var width = viewW
        
        if UIApplication.shared.statusBarOrientation.isLandscape {
            let height = viewH
            frame.size.height = height
            
            let imageWHRatio = size.width / size.height
            let viewWHRatio = viewW / viewH
            
            if imageWHRatio > viewWHRatio {
                frame.size.width = floor(height * imageWHRatio)
                if frame.size.width > viewW {
                    // 宽图
                    frame.size.width = viewW
                    frame.size.height = viewW / imageWHRatio
                }
            } else {
                width = floor(height * imageWHRatio)
                if width < 1 || width.isNaN {
                    width = viewW
                }
                frame.size.width = width
            }
        } else {
            frame.size.width = width
            
            let imageHWRatio = size.height / size.width
            let viewHWRatio = viewH / viewW
            
            if imageHWRatio > viewHWRatio {
                // 长图
                frame.size.width = min(size.width, viewW)
                frame.size.height = floor(frame.size.width * imageHWRatio)
            } else {
                var height = floor(frame.size.width * imageHWRatio)
                if height < 1 || height.isNaN {
                    height = viewH
                }
                frame.size.height = height
            }
        }
        
        // 优化 scroll view zoom scale
        if frame.width < frame.height {
            self.scrollView.maximumZoomScale = max(defaultMaxZoomScale, viewW / frame.width)
        } else {
            self.scrollView.maximumZoomScale = max(defaultMaxZoomScale, viewH / frame.height)
        }
        
        self.containerView.frame = frame
        
        var contenSize: CGSize = .zero
        if UIApplication.shared.statusBarOrientation.isLandscape {
            contenSize = CGSize(width: width, height: max(viewH, frame.height))
            if frame.height < viewH {
                self.containerView.center = CGPoint(x: viewW / 2, y: viewH / 2)
            } else {
                self.containerView.frame = CGRect(origin: CGPoint(x: (viewW - frame.width) / 2, y: 0), size: frame.size)
            }
        } else {
            contenSize = frame.size
            if frame.height < viewH {
                self.containerView.center = CGPoint(x: viewW / 2, y: viewH / 2)
            } else {
                self.containerView.frame = CGRect(origin: CGPoint(x: (viewW - frame.width) / 2, y: 0), size: frame.size)
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            self.scrollView.contentSize = contenSize
            self.imageView.frame = self.containerView.bounds
            self.scrollView.contentOffset = .zero
        }
    }
    
    func resumeGif() {
        guard let m = self.model else { return }
        guard photoConfig.allowSelectGif && m.type == .gif else { return }
        guard self.imageView.layer.speed != 1 else { return }
        
        let pauseTime = self.imageView.layer.timeOffset
        self.imageView.layer.speed = 1
        self.imageView.layer.timeOffset = 0
        self.imageView.layer.beginTime = 0
        let timeSincePause = self.imageView.layer.convertTime(CACurrentMediaTime(), from: nil) - pauseTime
        self.imageView.layer.beginTime = timeSincePause
    }
    
    func pauseGif() {
        guard let m = self.model else { return }
        guard photoConfig.allowSelectGif && m.type == .gif else { return }
        guard self.imageView.layer.speed != 0 else { return }
        
        let pauseTime = self.imageView.layer.convertTime(CACurrentMediaTime(), from: nil)
        self.imageView.layer.speed = 0
        self.imageView.layer.timeOffset = pauseTime
    }
}
extension PhotoPreview: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.containerView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let offsetX = (scrollView.frame.width > scrollView.contentSize.width) ? (scrollView.frame.width - scrollView.contentSize.width) * 0.5 : 0
        let offsetY = (scrollView.frame.height > scrollView.contentSize.height) ? (scrollView.frame.height - scrollView.contentSize.height) * 0.5 : 0
        self.containerView.center = CGPoint(x: scrollView.contentSize.width * 0.5 + offsetX, y: scrollView.contentSize.height * 0.5 + offsetY)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.resumeGif()
    }
}
