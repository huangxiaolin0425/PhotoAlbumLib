//
//  AssetCell.swift
//  wutong
//
//  Created by Jeejio on 2021/12/24.
//

import UIKit
import Photos

class AssetCell: UICollectionViewCell {
    private lazy var imageView = UIImageView()
    lazy var buttonSelect = UIButton(type: .custom)
    private lazy var bottomShadowView = UIView()
    private lazy var descLabel = UILabel()
    private lazy var coverView = UIView()
    lazy var indexLabel = UILabel()
    private(set) var enableSelect: Bool = true
    
    private lazy var progressView = PhotoProgressView()
    
    var selectedBlock: PhotoCompletionObjectHandler<Bool>?
    
    private var model: PhotoModel!
    
    private var photoConfig: PhotoConfiguration!
    
    private var index: Int = 0 {
        didSet {
            self.indexLabel.text = String(index)
        }
    }
    
    private var imageIdentifier: String = ""
    private var smallImageRequestID: PHImageRequestID = PHInvalidImageRequestID
    private var bigImageReqeustID: PHImageRequestID = PHInvalidImageRequestID
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initialAppearance()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func initialAppearance() {
        self.imageView.contentMode = .scaleAspectFill
        self.imageView.clipsToBounds = true
        self.contentView.addSubview(self.imageView)
        
        self.coverView.isUserInteractionEnabled = false
        self.coverView.isHidden = true
        self.contentView.addSubview(self.coverView)
        
        self.buttonSelect.setImage(getImage("photo_def_photoPickerVc"), for: .normal)
        self.buttonSelect.setImage(getImage("photo_preview_selected"), for: .selected)
        self.buttonSelect.addTarget(self, action: #selector(btnSelectClick), for: .touchUpInside)
        //        self.buttonSelect.enlargeResponseEdge = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        self.contentView.addSubview(self.buttonSelect)
        
        self.indexLabel.layer.cornerRadius = 22.0 / 2
        self.indexLabel.layer.masksToBounds = true
        self.indexLabel.textColor = .white
        self.indexLabel.font = .regular(ofSize: 14)
        self.indexLabel.adjustsFontSizeToFitWidth = true
        self.indexLabel.minimumScaleFactor = 0.5
        self.indexLabel.textAlignment = .center
        self.buttonSelect.addSubview(self.indexLabel)
        
        let gradientLayer: CAGradientLayer = CAGradientLayer()
        gradientLayer.frame = self.contentView.bounds
        gradientLayer.colors = NSArray(array: [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.4).cgColor]) as? [Any]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0, y: 1)
        bottomShadowView.layer.addSublayer(gradientLayer)
        self.contentView.addSubview(self.bottomShadowView)
        
        self.descLabel = UILabel()
        self.descLabel.font = .semibold(ofSize: 11)
        self.descLabel.textAlignment = .left
        self.descLabel.textColor = .white
        self.bottomShadowView.addSubview(self.descLabel)
        
        self.progressView.isHidden = true
        self.contentView.addSubview(self.progressView)
        
        self.layer.cornerRadius = 8
        self.layer.masksToBounds = true
        self.layer.borderWidth = 1
        self.layer.borderColor = RGB(237, 237, 237).cgColor
    }
    
    override func layoutSubviews() {
        self.imageView.frame = self.bounds
        self.coverView.frame = self.bounds
        self.buttonSelect.frame = CGRect(x: self.bounds.width - 32, y: 2, width: 30, height: 30)
        self.indexLabel.frame = CGRect(x: 4, y: 4, width: 22, height: 22)
        self.bottomShadowView.frame = CGRect(x: 0, y: self.bounds.height - 25, width: self.bounds.width, height: 25)
        self.descLabel.frame = CGRect(x: 8, y: self.bottomShadowView.frame.size.height - 25, width: self.bounds.width - 35, height: 25)
        self.progressView.frame = CGRect(x: (self.bounds.width - 20) / 2, y: (self.bounds.height - 20) / 2, width: 20, height: 20)
        
        super.layoutSubviews()
    }
    
    @objc func btnSelectClick() {
        if !self.enableSelect {
            return
        }
        
        self.buttonSelect.layer.removeAllAnimations()
        if !self.buttonSelect.isSelected {
            self.buttonSelect.springAnimation()
        }
        
        if self.buttonSelect.isSelected == false {
            self.fetchBigImage(or: true)
        } else {
            self.selectedBlock?(self.buttonSelect.isSelected)
            self.progressView.isHidden = true
            self.cancelFetchBigImage()
        }
    }
    
    func config(model: PhotoModel, photoConfig: PhotoConfiguration) {
        self.model = model
        self.photoConfig = photoConfig
        configureCell()
    }
    
    private func configureCell() {
        if self.model.type == .video {
            self.bottomShadowView.isHidden = false
            self.descLabel.text = self.model.duration
        } else if self.model.type == .gif {
            self.bottomShadowView.isHidden = !photoConfig.allowSelectGif
            self.descLabel.text = "GIF"
        } else if self.model.type == .livePhoto {
            self.bottomShadowView.isHidden = !photoConfig.allowSelectLivePhoto
            self.descLabel.text = "Live"
        } else {
            self.bottomShadowView.isHidden = true
        }
        
        let showSelBtn: Bool
        if photoConfig.maxImagesCount > 1 {
            if !photoConfig.allowPickingMultipleVideo {
                showSelBtn = self.model.type.rawValue < PhotoModel.MediaType.video.rawValue
            } else {
                showSelBtn = true
            }
        } else {
            showSelBtn = photoConfig.showSelectBtnWhenSingleSelect
        }
        
        self.buttonSelect.isHidden = !showSelBtn
        self.buttonSelect.isUserInteractionEnabled = showSelBtn
        self.buttonSelect.isSelected = self.model.isSelected
        
        self.indexLabel.backgroundColor = photoConfig.indexLabelBgColor
        
        if self.model.isSelected {
            self.fetchBigImage()
        } else {
            self.cancelFetchBigImage()
        }
        
        self.fetchSmallImage()
    }
    
    private func fetchSmallImage() {
        let size: CGSize
        let maxSideLength = self.bounds.width * 1.2
        if self.model.whRatio > 1 {
            let w = maxSideLength * self.model.whRatio
            size = CGSize(width: w, height: maxSideLength)
        } else {
            let h = maxSideLength / self.model.whRatio
            size = CGSize(width: maxSideLength, height: h)
        }
        
        if self.smallImageRequestID > PHInvalidImageRequestID {
            PHImageManager.default().cancelImageRequest(self.smallImageRequestID)
        }
        
        self.imageIdentifier = self.model.ident
        self.imageView.image = nil
        self.smallImageRequestID = PhotoAlbumManager.fetchImage(for: self.model.asset, size: size, completion: { [weak self] (image, isDegraded) in
            if self?.imageIdentifier == self?.model.ident {
                self?.imageView.image = image
            }
            if !isDegraded {
                self?.smallImageRequestID = PHInvalidImageRequestID
            }
        })
    }
    
    private func fetchBigImage(or getfileBytes: Bool = false) {
        self.cancelFetchBigImage()
        
        if getfileBytes {
            if self.model.asset.isInCloud {
                guard let resources = self.model.asset.assetResources else { return }
                guard let fileSize = (resources.value(forKey: "fileSize") as? CLong) else { return }
                guard self.isBytesGreaterMaxImageData(dataLength: CGFloat(fileSize)) else {
                    self.selectedBlock?(self.buttonSelect.isSelected)
                    return
                }
                showAlertView(String(format: "文件大小已超过%.2fM，不支持发送", arguments: [photoConfig.maxImageByte / 1024.0 / 1024.0]), nil)
            } else {
                if self.model.type != .video {
                    self.bigImageReqeustID = PhotoAlbumManager.fetchOriginalImageData(for: self.model.asset, isNetworkAccessAllowed: false, progress: { [weak self] (progress, error, _, _) in
                        if self?.model.isSelected == true {
                            self?.progressView.isHidden = false
                            self?.progressView.progress = max(0.1, progress)
                            self?.imageView.alpha = 0.5
                            if progress >= 1 {
                                self?.resetProgressViewStatus()
                            }
                        } else {
                            self?.cancelFetchBigImage()
                        }
                    }, completion: { [weak self] (data, _, _) in
                        guard let self = self else { return }
                        self.resetProgressViewStatus()
                        guard let data = data else {
                            self.selectedBlock?(self.buttonSelect.isSelected)
                            return
                        }
                        guard self.isBytesGreaterMaxImageData(dataLength: CGFloat(data.count)) else {
                            self.selectedBlock?(self.buttonSelect.isSelected)
                            return
                        }
                        showAlertView(String(format: "文件大小已超过%.2fM，不支持发送", arguments: [self.photoConfig.maxImageByte / 1024.0 / 1024.0]), nil)
                    })
                } else {
                    guard let resources = self.model.asset.assetResources else { return }
                    guard let fileSize = (resources.value(forKey: "fileSize") as? CLong) else { return }
                    guard self.isBytesGreaterMaxImageData(dataLength: CGFloat(fileSize)) else {
                        self.selectedBlock?(self.buttonSelect.isSelected)
                        return
                    }
                    showAlertView(String(format: "文件大小已超过%.2fM，不支持发送", arguments: [photoConfig.maxImageByte / 1024.0 / 1024.0]), nil)
                }
            }
        } else {
            self.bigImageReqeustID = PhotoAlbumManager.fetchOriginalImageData(for: self.model.asset, progress: { [weak self] (progress, error, _, _) in
                if self?.model.isSelected == true {
                    self?.progressView.isHidden = false
                    self?.progressView.progress = max(0.1, progress)
                    self?.imageView.alpha = 0.5
                    if progress >= 1 {
                        self?.resetProgressViewStatus()
                    }
                } else {
                    self?.cancelFetchBigImage()
                }
            }, completion: { [weak self] (_, _, _) in
                self?.resetProgressViewStatus()
            })
        }
    }
    
    private func isBytesGreaterMaxImageData(dataLength: CGFloat) -> Bool {
        if dataLength > photoConfig.maxImageByte {
            return true
        }
        return false
    }
    
    private func cancelFetchBigImage() {
        if self.bigImageReqeustID > PHInvalidImageRequestID {
            PHImageManager.default().cancelImageRequest(self.bigImageReqeustID)
        }
        self.resetProgressViewStatus()
    }
    
    func resetProgressViewStatus() {
        self.progressView.isHidden = true
        self.imageView.alpha = 1
    }
}
extension AssetCell {
    func setCellIndex(showIndexLabel: Bool, index: Int) {
        guard photoConfig.showSelectedIndex else {
            return
        }
        self.index = index
        self.indexLabel.isHidden = !showIndexLabel
    }
    
    func setCellMaskView(isSelected: Bool, model: PhotoModel) {
        coverView.isHidden = true
        enableSelect = true
        let arrSel = (self.viewController?.navigationController as? ImageNavViewController)?.arrSelectedModels ?? []
        
        if isSelected {
            coverView.backgroundColor = photoConfig.selectedMaskColor
            coverView.isHidden = !photoConfig.showSelectedMask
        } else {
            let selCount = arrSel.count
            if selCount < photoConfig.maxImagesCount {
                if photoConfig.allowPickingMultipleVideo {
                    let videoCount = arrSel.filter { $0.type == .video }.count
                    if videoCount >= photoConfig.maxVideoSelectCount, model.type == .video {
                        coverView.backgroundColor = photoConfig.invalidMaskColor
                        coverView.isHidden = !photoConfig.showInvalidMask
                        enableSelect = false
                    } else if (photoConfig.maxImagesCount - selCount) <= (photoConfig.minVideoSelectCount - videoCount), model.type != .video {
                        coverView.backgroundColor = photoConfig.invalidMaskColor
                        coverView.isHidden = !photoConfig.showInvalidMask
                        enableSelect = false
                    }
                } else if selCount > 0 {
                    coverView.backgroundColor = photoConfig.invalidMaskColor
                    coverView.isHidden = (!photoConfig.showInvalidMask || model.type != .video)
                    enableSelect = model.type != .video
                }
            } else if selCount >= photoConfig.maxImagesCount {
                coverView.backgroundColor = photoConfig.invalidMaskColor
                coverView.isHidden = !photoConfig.showInvalidMask
                enableSelect = false
            }
        }
    }
}
