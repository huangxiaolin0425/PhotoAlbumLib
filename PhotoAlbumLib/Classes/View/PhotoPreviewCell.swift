//
//  PhotoPreviewCell.swift
//  wutong
//
//  Created by Jeejio on 2021/12/28.
//

import UIKit
import Photos

class PhotoPreviewBaseCell: UICollectionViewCell {
    var singleTapBlock: PhotoCompletionHandler?
    var currentImage: UIImage? {
        return nil
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(previewVCScroll),
                                               name: PhotoPreviewController.previewVCScrollNotification,
                                               object: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    /// cell 手动滚动的监听 处理视频暂停等相关事件
    @objc func previewVCScroll() {}
    /// 重置当前cell结束事件
    func resetSubViewStatusWhenCellEndDisplay() {}
    
    func resizeImageView(imageView: UIImageView, asset: PHAsset) {
        let size = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
        var frame: CGRect = .zero
        
        let viewW = self.bounds.width
        let viewH = self.bounds.height
        
        var width = viewW
        
        // video和livephoto没必要处理长图和宽图
        if UIApplication.shared.statusBarOrientation.isLandscape {
            let height = viewH
            frame.size.height = height
            
            let imageWHRatio = size.width / size.height
            let viewWHRatio = viewW / viewH
            
            if imageWHRatio > viewWHRatio {
                frame.size.width = floor(height * imageWHRatio)
                if frame.size.width > viewW {
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
                frame.size.height = floor(width * imageHWRatio)
            } else {
                var height = floor(width * imageHWRatio)
                if height < 1 || height.isNaN {
                    height = viewH
                }
                frame.size.height = height
            }
        }
        
        imageView.frame = frame
        
        if UIApplication.shared.statusBarOrientation.isLandscape {
            if frame.height < viewH {
                imageView.center = CGPoint(x: viewW / 2, y: viewH / 2)
            } else {
                imageView.frame = CGRect(origin: CGPoint(x: (viewW - frame.width) / 2, y: 0), size: frame.size)
            }
        } else {
            if frame.width < viewW || frame.height < viewH {
                imageView.center = CGPoint(x: viewW / 2, y: viewH / 2)
            }
        }
    }
    
    func animateImageFrame(convertTo view: UIView) -> CGRect {
        return .zero
    }
}

class PhotoPreviewCell: PhotoPreviewBaseCell {
    override var currentImage: UIImage? {
        return self.preview.image
    }
    
    private var preview = PhotoPreview()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initialAppearance()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.preview.frame = self.bounds
    }
    
    private func initialAppearance() {
        self.preview.singleTapBlock = { [weak self] in
            self?.singleTapBlock?()
        }
        self.contentView.addSubview(self.preview)
    }
    
    override func resetSubViewStatusWhenCellEndDisplay() {
        self.preview.scrollView.zoomScale = 1
    }
    
    override func animateImageFrame(convertTo view: UIView) -> CGRect {
        let r1 = self.preview.scrollView.convert(self.preview.containerView.frame, to: self)
        return self.convert(r1, to: view)
    }
    
    func config(model: PhotoModel, photoConfig: PhotoConfiguration) {
        self.preview.configure(model: model, photoConfig: photoConfig)
    }
}

class GIFPreviewCell: PhotoPreviewBaseCell {
    private var preview = PhotoPreview()
    override var currentImage: UIImage? {
        return self.preview.image
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initialAppearance()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.preview.frame = self.bounds
    }
    
    private func initialAppearance() {
        self.preview = PhotoPreview()
        self.preview.singleTapBlock = { [weak self] in
            self?.singleTapBlock?()
        }
        self.contentView.addSubview(self.preview)
    }
    
    override func previewVCScroll() {
        self.preview.pauseGif()
    }
    
    func config(model: PhotoModel, photoConfig: PhotoConfiguration) {
        self.preview.configure(model: model, photoConfig: photoConfig)
    }
    
    func resumeGif() {
        self.preview.resumeGif()
    }
    
    func pauseGif() {
        self.preview.pauseGif()
    }
    
    /// gif图加载会导致主线程卡顿，所以放在willdisplay时候加载
    func loadGifWhenCellDisplaying() {
        self.preview.loadGifData()
    }
    
    override func resetSubViewStatusWhenCellEndDisplay() {
        self.preview.scrollView.zoomScale = 1
    }
    
    override func animateImageFrame(convertTo view: UIView) -> CGRect {
        let r1 = self.preview.scrollView.convert(self.preview.containerView.frame, to: self)
        return self.convert(r1, to: view)
    }
}

class VideoPreviewCell: PhotoPreviewBaseCell {
    private var progressView = PhotoProgressView()
    override var currentImage: UIImage? {
        return self.imageView.image
    }
    
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var imageView = UIImageView()
    private var playButton = UIButton(type: .custom)
    private var syncErrorLabel = UILabel()
    
    private lazy var timePlayButton = UIButton(type: .custom)
    private lazy var progressLineView = UIView()
    private lazy var videoSlider = VideoSlider()
    private lazy var timeplayLabel = UILabel()
    private lazy var timeLabel = UILabel()
    
    var imageRequestID: PHImageRequestID = PHInvalidImageRequestID
    var videoRequestID: PHImageRequestID = PHInvalidImageRequestID
    
    var onFetchingVideo = false

    var fetchVideoDone = false
    
    var isPlaying: Bool {
        if self.player != nil, self.player?.rate != 0 {
            return true
        }
        return false
    }
    private var model: PhotoModel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initialAppearance()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let bottomViewH = 50 + kSafeBottomHeight
        self.playerLayer?.frame = self.bounds
        self.playButton.frame = CGRect(x: 0, y: 0, width: 65, height: 65)
        self.playButton.center = CGPoint(x: self.bounds.width / 2, y: self.bounds.height / 2)
        self.syncErrorLabel.frame = CGRect(x: 10, y: kStatusBarHeight + 60, width: self.bounds.width - 20, height: 35)
        self.progressView.frame = CGRect(x: self.bounds.width / 2 - 30, y: self.bounds.height / 2 - 30, width: 60, height: 60)
        self.resizeImageView(imageView: self.imageView, asset: model.asset)
        self.timePlayButton.frame = CGRect(x: 30, y: kScreenHeight - bottomViewH - 45, width: 30, height: 30)
        self.progressLineView.frame = CGRect(x: self.timePlayButton.right + 20, y: 0, width: kScreenWidth - 25 - self.timePlayButton.width - 50, height: 2)
        self.progressLineView.centerY = self.timePlayButton.centerY
        self.videoSlider.frame = self.progressLineView.frame
        self.timeplayLabel.frame = CGRect(x: self.progressLineView.left, y: self.progressLineView.bottom + 5, width: 100, height: 20)
        self.timeLabel.frame = CGRect(x: kScreenWidth - 25 - 100, y: self.progressLineView.bottom + 5, width: 100, height: 20)
    }
    
    private func initialAppearance() {
        let sigleGesture = UITapGestureRecognizer(target: self, action: #selector(singleTap))
        self.contentView.addGestureRecognizer(sigleGesture)
        
        self.imageView = UIImageView()
        self.imageView.clipsToBounds = true
        self.imageView.contentMode = .scaleAspectFill
        self.contentView.addSubview(self.imageView)
        
        let attStr = NSMutableAttributedString()
        let attach = NSTextAttachment()
        attach.image = getImage("videoLoadFailed")
        attach.bounds = CGRect(x: 0, y: -10, width: 30, height: 30)
        attStr.append(NSAttributedString(attachment: attach))
        let errorText = NSAttributedString(string: "iCloud无法同步", attributes: [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont.regular(ofSize: 12)])
        attStr.append(errorText)
        self.syncErrorLabel = UILabel()
        self.syncErrorLabel.attributedText = attStr
        self.contentView.addSubview(self.syncErrorLabel)
        
        self.contentView.addSubview(self.progressView)
        
        self.playButton.setImage(getImage("message_video_play_icon"), for: .normal)
        self.playButton.addTarget(self, action: #selector(playBtnClick), for: .touchUpInside)
        self.contentView.addSubview(self.playButton)
        
        self.timePlayButton.setImage(getImage("videoPreview_play"), for: .normal)
        self.timePlayButton.addTarget(self, action: #selector(playBtnClick), for: .touchUpInside)
        self.contentView.addSubview(self.timePlayButton)
        
        self.progressLineView.backgroundColor = .lightGray.withAlphaComponent(0.4)
        self.contentView.addSubview(self.progressLineView)
        
        self.videoSlider.maximumTrackTintColor = .clear
        self.videoSlider.addTarget(self, action: #selector(progressSliderTouchBegan(sender:)), for: .touchDown)
        self.videoSlider.addTarget(self, action: #selector(progressSliderValueChanged(sender:)), for: .valueChanged)
        self.videoSlider.addTarget(self, action: #selector(progressSliderTouchEnded(sender:)), for: [.touchUpInside, .touchCancel, .touchUpOutside])
        self.contentView.addSubview(self.videoSlider)
        
        self.timeplayLabel.textColor = .white
        self.timeplayLabel.font = .regular(ofSize: 12)
        self.contentView.addSubview(self.timeplayLabel)
        
        self.timeLabel.textColor = .white
        self.timeLabel.textAlignment = .right
        self.timeLabel.font = .regular(ofSize: 12)
        self.contentView.addSubview(self.timeLabel)
        
        NotificationCenter.default.addObserver(self, selector: #selector(appWillResignActive), name: UIApplication.willResignActiveNotification, object: nil)
    }
    
    func config(model: PhotoModel) {
        self.model = model
        configureCell()
    }
    func configureCell() {
        self.imageView.image = nil
        self.imageView.isHidden = false
        self.syncErrorLabel.isHidden = true
        self.playButton.isEnabled = false
        self.player = nil
        self.playerLayer?.removeFromSuperlayer()
        self.playerLayer = nil
        self.timeplayLabel.text = "00:00"
        self.timeLabel.text = model.duration
        
        if self.imageRequestID > PHInvalidImageRequestID {
            PHImageManager.default().cancelImageRequest(self.imageRequestID)
        }
        if self.videoRequestID > PHInvalidImageRequestID {
            PHImageManager.default().cancelImageRequest(self.videoRequestID)
        }
        
        // 视频预览图尺寸
        var size = self.model.previewSize
        size.width /= 2
        size.height /= 2
        
        self.resizeImageView(imageView: self.imageView, asset: self.model.asset)
        self.imageRequestID = PhotoAlbumManager.fetchImage(for: self.model.asset, size: size, completion: { (image, _) in
            self.imageView.image = image
        })
    
        self.videoRequestID = PhotoAlbumManager.fetchVideo(for: self.model.asset, progress: { [weak self] (progress, _, _, _) in
            self?.progressView.progress = progress
            if progress >= 1 {
                self?.progressView.isHidden = true
            } else {
                self?.progressView.isHidden = false
            }
        }, completion: { [weak self] (item, info, isDegraded) in
            let error = info?[PHImageErrorKey] as? Error
            let isFetchError = PhotoAlbumManager.isFetchImageError(error)
            if isFetchError {
                self?.syncErrorLabel.isHidden = false
                self?.playButton.setImage(nil, for: .normal)
            }
            if !isDegraded, item != nil {
                self?.fetchVideoDone = true
                self?.configurePlayerLayer(item!)
            }
        })
    }
    
    func configurePlayerLayer(_ item: AVPlayerItem) {
        self.playButton.setImage(getImage("message_video_play_icon"), for: .normal)
        self.playButton.isEnabled = true
        
        self.player = AVPlayer(playerItem: item)
        self.playerLayer = AVPlayerLayer(player: self.player)
        self.playerLayer?.frame = self.bounds
        self.layer.insertSublayer(self.playerLayer!, at: 0)

        self.player?.addPeriodicTimeObserver(forInterval: CMTime(value: 1, timescale: CMTimeScale(NSEC_PER_SEC)),
                                             queue: .main, using: { [weak self] time in
            guard let self = self else { return }
            guard let duration = self.player?.currentItem?.duration else { return }
            let totalTime = CGFloat(duration.value) / CGFloat(duration.timescale)
            let _duration = CMTimeGetSeconds(duration)
            let time = CMTimeGetSeconds(time)
            if _duration.isNaN || time.isNaN { return }
            let progress = (time / _duration)
            self.videoSlider.value = Float(progress)
            self.timeplayLabel.text = self.getFormatPlayTime(secounds: Int(time))
            self.timeLabel.text = self.getFormatPlayTime(secounds: Int(totalTime))
        })
        
        NotificationCenter.default.addObserver(self, selector: #selector(playFinish), name: .AVPlayerItemDidPlayToEndTime, object: self.player?.currentItem)
    }
    
    private func getFormatPlayTime(secounds: Int) -> String {
        if secounds == 0 {
            return "00:00"
        }
        var Min = Int(secounds / 60)
        let Sec = Int(secounds % 60)
        var Hour = 0
        if Min >= 60 {
            Hour = Int(Min / 60)
            Min -= Hour * 60
            return String(format: "%02d:%02d:%02d", Hour, Min, Sec)
        }
        return String(format: "%02d:%02d", Min, Sec)
    }
    
    @objc func singleTap() {
        playBtnClick()
    }
    
    @objc func playBtnClick() {
        let currentTime = self.player?.currentItem?.currentTime()
        let duration = self.player?.currentItem?.duration
        if self.player?.rate == 0 {
            if currentTime?.value == duration?.value {
                self.player?.currentItem?.seek(to: CMTimeMake(value: 0, timescale: 1), completionHandler: nil)
            }
            self.imageView.isHidden = true
            self.player?.play()
            self.playButton.setImage(nil, for: .normal)
            self.timePlayButton.setImage(getImage("videoPreview_pause"), for: .normal)
            self.singleTapBlock?()
        } else {
            self.pausePlayer(seekToZero: false)
        }
    }
    
    @objc func playFinish() {
        self.pausePlayer(seekToZero: true)
    }
    
    @objc func appWillResignActive() {
        if self.player != nil, self.player?.rate != 0 {
            self.pausePlayer(seekToZero: false)
        }
    }
    
    override func previewVCScroll() {
        if self.player != nil, self.player?.rate != 0 {
            self.pausePlayer(seekToZero: false)
        }
    }
    
    override func resetSubViewStatusWhenCellEndDisplay() {
        self.imageView.isHidden = false
        self.player?.currentItem?.seek(to: CMTimeMake(value: 0, timescale: 1), completionHandler: nil)
    }
    
    func pausePlayer(seekToZero: Bool) {
        self.player?.pause()
        if seekToZero {
            self.player?.seek(to: .zero)
        }
        self.playButton.setImage(getImage("message_video_play_icon"), for: .normal)
        self.timePlayButton.setImage(getImage("videoPreview_play"), for: .normal)
        self.singleTapBlock?()
    }
    
    func pauseWhileTransition() {
        self.player?.pause()
        self.playButton.setImage(getImage("message_video_play_icon"), for: .normal)
    }
    
    override func animateImageFrame(convertTo view: UIView) -> CGRect {
        return self.convert(self.imageView.frame, to: view)
    }
}
extension VideoPreviewCell {
    /** 开始拖动事件 */
    @objc func progressSliderTouchBegan(sender: UISlider) {
        self.player?.pause()
        NSObject.cancelPreviousPerformRequests(withTarget: self)
    }
    /** 拖动中事件 */
    @objc func progressSliderValueChanged(sender: UISlider) {
        guard let duration = self.player?.currentItem?.duration else { return }
        let totalTime = CGFloat(duration.value) / CGFloat(duration.timescale)
        let dragedSeconds = totalTime * CGFloat(sender.value)
        /// 转换成CMTime才能给player来控制播放进度
        let dragedCMTime: CMTime = CMTimeMake(value: Int64(dragedSeconds), timescale: 1)
        self.player?.seek(to: dragedCMTime, toleranceBefore: .zero, toleranceAfter: .zero)
        let currentTime = Int(CMTimeGetSeconds(dragedCMTime))
        
        /// 更新播放进度
        let playtimeStr = getFormatPlayTime(secounds: currentTime)
        self.timeplayLabel.text = playtimeStr
    }
    /** 结束拖动事件 */
    @objc func progressSliderTouchEnded(sender: UISlider) {
        let currentTime = self.player?.currentItem?.currentTime()
        let durationTime = self.player?.currentItem?.duration
        if self.player?.rate == 0 {
            if currentTime?.value == durationTime?.value {
                self.player?.currentItem?.seek(to: CMTimeMake(value: 0, timescale: 1), completionHandler: nil)
            }
            self.player?.play()
            self.imageView.isHidden = true
            self.playButton.setImage(nil, for: .normal)
            self.timePlayButton.setImage(getImage("videoPreview_pause"), for: .normal)
        } else {
            self.pausePlayer(seekToZero: false)
        }
    }
}
