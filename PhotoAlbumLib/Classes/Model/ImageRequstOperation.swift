//
//  ImageRequstOperation.swift
//  wutong
//
//  Created by Jeejio on 2021/12/30.
//

import UIKit
import Photos
import SwiftUI

class ImageRequstOperation: Operation {
    let model: PhotoModel
    
    let isOriginal: Bool
    
    let progress: ( (CGFloat, Error?, UnsafeMutablePointer<ObjCBool>, [AnyHashable: Any]?) -> Void )?
    
    let completion: ( (UIImage?, Data?, PHAsset?) -> Void )
    
    private var photoConfig: PhotoConfiguration
    
    var pri_isExecuting = false {
        willSet {
            self.willChangeValue(forKey: "isExecuting")
        }
        didSet {
            self.didChangeValue(forKey: "isExecuting")
        }
    }
    
    override var isExecuting: Bool {
        return self.pri_isExecuting
    }
    
    var pri_isFinished = false {
        willSet {
            self.willChangeValue(forKey: "isFinished")
        }
        didSet {
            self.didChangeValue(forKey: "isFinished")
        }
    }
    
    override var isFinished: Bool {
        return self.pri_isFinished
    }
    
    var pri_isCancelled = false {
        willSet {
            self.willChangeValue(forKey: "isCancelled")
        }
        didSet {
            self.didChangeValue(forKey: "isCancelled")
        }
    }
    
    var requestImageID: PHImageRequestID = PHInvalidImageRequestID
    
    override var isCancelled: Bool {
        return self.pri_isCancelled
    }
    
    init(model: PhotoModel, photoConfig: PhotoConfiguration, isOriginal: Bool, progress: ( (CGFloat, Error?, UnsafeMutablePointer<ObjCBool>, [AnyHashable: Any]?) -> Void )? = nil, completion: @escaping ( (UIImage?, Data?, PHAsset?) -> Void )) {
        self.model = model
        self.isOriginal = isOriginal
        self.progress = progress
        self.completion = completion
        self.photoConfig = photoConfig
        super.init()
    }
    
    override func start() {
        if self.isCancelled {
            self.fetchFinish()
            return
        }
        self.pri_isExecuting = true
        
        if photoConfig.allowSelectGif, self.model.type == .gif {
            self.requestImageID = PhotoAlbumManager.fetchOriginalImageData(for: self.model.asset) { [weak self] (data, _, isDegraded) in
                if !isDegraded {
                    if let data = data {
                        let image = UIImage.animateGifImage(data: data)
                        self?.completion(image, data, nil)
                        self?.fetchFinish()
                    }
                }
            }
            return
        }
        
        if self.isOriginal {
            self.requestImageID = PhotoAlbumManager.fetchOriginalImage(for: self.model.asset, progress: self.progress) { [weak self] (image, isDegraded) in
                if !isDegraded {
                    self?.completion(image?.fixedOrientation(), nil, nil)
                    self?.fetchFinish()
                }
            }
        } else {
            self.requestImageID = PhotoAlbumManager.fetchImage(for: self.model.asset, size: self.model.previewSize, progress: self.progress) { [weak self] (image, isDegraded) in
                guard let self = self else { return }
                if !isDegraded {
                    if let image = image {
                        self.completion(self.scaleImage(image.fixedOrientation()), nil, nil)
                    } else {
                        self.completion(self.scaleImage(UIImage.imageWithColor(.white, size: self.model.previewSize).fixedOrientation()), nil, nil)
                    }
                    self.fetchFinish()
                }
            }
        }
    }
    /// 不是原图的时候进行裁剪
    func scaleImage(_ image: UIImage?) -> UIImage? {
        guard let i = image else {
            return nil
        }
        guard let data = i.jpegData(compressionQuality: 1) else {
            return i
        }
        let mUnit: CGFloat = 1024 * 1024
        
        if data.count < Int(0.2 * mUnit) {
            return i
        }
        let scale: CGFloat = (data.count > Int(mUnit) ? 0.5 : 0.7)
        
        guard let d = i.jpegData(compressionQuality: scale) else {
            return i
        }
        return UIImage(data: d)
    }
    
    func fetchFinish() {
        self.pri_isExecuting = false
        self.pri_isFinished = true
    }
    
    override func cancel() {
        super.cancel()
        PHImageManager.default().cancelImageRequest(self.requestImageID)
        self.pri_isCancelled = true
        if self.isExecuting {
            self.fetchFinish()
        }
    }
}
