//
//  ImageNavViewController.swift
//  wutong
//
//  Created by Jeejio on 2021/12/24.
//

import UIKit
import Photos
import SwiftUI

class ImageNavViewController: UINavigationController {
    var photoConfig = PhotoConfiguration()
    
    var isSelectedOriginal: Bool = false
    
    var arrSelectedModels: [PhotoModel] = []
        
    var cancelBlock: PhotoCompletionHandler?
    
    var selectImageBlock: ( ([SelectAssetModel], Bool) -> Void )?
    var fileAcquisitionCallback: (([SelectAssetModel], CGFloat, Bool) -> Bool)?
    var selectImageRequestErrorBlock: ( ([PHAsset], [Int]) -> Void )?
    
    private lazy var fetchImageQueue: OperationQueue = OperationQueue()

    deinit {
        print("ImageNavController deinit")
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return photoConfig.statusBarStyle
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchImageQueue.maxConcurrentOperationCount = 3
    }
    
    init(rootViewController: UIViewController, photoConfig: PhotoConfiguration) {
        self.photoConfig = photoConfig
        super.init(rootViewController: rootViewController)
        self.navigationBar.barStyle = .black
        self.navigationBar.isTranslucent = true
        self.modalPresentationStyle = .fullScreen
        self.isNavigationBarHidden = true
        
        self.navigationBar.setBackgroundImage(UIImage.imageWithColor(photoConfig.navBarColor), for: .default)
        self.navigationBar.tintColor = photoConfig.navTitleColor
        self.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: photoConfig.navTitleColor]
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func requestSelectPhoto(viewController: UIViewController? = nil) {
        let nav = viewController as! ImageNavViewController
        
        guard !nav.arrSelectedModels.isEmpty else {
            selectImageBlock?([], isSelectedOriginal)
            viewController?.dismiss(animated: true, completion: nil)
            return
        }
                
        let loadingView = ProgressHUD(style: .darkBlur)
        loadingView.show()

        let callback = { [weak self] (sucModels: [SelectAssetModel], errorAssets: [PHAsset], errorIndexs: [Int]) in
            guard let self = self else { return }
            loadingView.hide()
            func call() {
                self.selectImageBlock?(sucModels, self.isSelectedOriginal)
                if !errorAssets.isEmpty {
                    self.selectImageRequestErrorBlock?(errorAssets, errorIndexs)
                }
            }
            
            if let vc = viewController {
                if let fileAcquisitionCallback = self.fileAcquisitionCallback {
                    PhotoAlbumManager.photosBytes(with: sucModels) { [weak self] size in
                        guard let self = self else { return }
                        let autoDismiss = fileAcquisitionCallback(sucModels, size, self.isSelectedOriginal)
                        if !autoDismiss {
                            call()
                        } else {
                            if self.photoConfig.autoCallbacksFirst {
                                call()
                                vc.dismiss(animated: true, completion: nil)
                            } else {
                                vc.dismiss(animated: true) {
                                    call()
                                }
                            }
                        }
                    }
                } else {
                    if self.photoConfig.autoCallbacksFirst {
                        call()
                        vc.dismiss(animated: true, completion: nil)
                    } else {
                        vc.dismiss(animated: true) {
                            call()
                        }
                    }
                }
            } else {
                call()
            }
        }
        
        var models: [SelectAssetModel?] = Array(repeating: nil, count: arrSelectedModels.count)
        var errorAssets: [PHAsset] = []
        var errorIndexs: [Int] = []
        
        var sucCount = 0
        let totalCount = arrSelectedModels.count
        for (i, m) in arrSelectedModels.enumerated() {
            let operation = ImageRequstOperation(model: m, photoConfig: photoConfig, isOriginal: self.isSelectedOriginal) { (image, data, asset) in
                sucCount += 1
                if let image = image {
                    let model = SelectAssetModel()
                    model.photo = image
                    model.asset = asset ?? m.asset
                    model.data = data
                    model.icloud = m.asset.isInCloud
                    models[i] = model
                } else {
                    errorAssets.append(m.asset)
                    errorIndexs.append(i)
                }
                
                guard sucCount >= totalCount else { return }
                
                callback(
                    models.compactMap { $0 },
                    errorAssets,
                    errorIndexs
                )
            }
            fetchImageQueue.addOperation(operation)
        }
    }
}
