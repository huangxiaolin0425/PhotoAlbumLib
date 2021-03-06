//
//  PhotoAlbumManager.swift
//  wutong
//
//  Created by Jeejio on 2021/12/20.
//

import Foundation
import UIKit
import Photos

public class PhotoAlbumManager: NSObject {
    /// 1.图片选择器结果回调
    public var imageCallback: (([SelectAssetModel], Bool) -> Void)?
    /// 2.选择器file文件大小回调, 回调方法的返回值为是否关闭当前图片控制器， true关闭，false不关闭
    public var fileAcquisitionCallback: (([SelectAssetModel], CGFloat, Bool) -> Bool)?
    /// 3.图片选择器点击item时，事件回调（⚠️：此方法的maxImageCount = 1并且imageType = image时调用, 一旦调用此block，imageCallback 将不再回调）
    public var didSelectItemAtFileCallback: ((SelectAssetModel) -> Void)?
    /// present imagePicker
    /// - Parameters:
    ///   - controller: load controller
    ///   - photoConfig: imagePiker config
    ///   - callback: select model callback
    ///   - fileAcquisitionCallback: file size callback
    ///   - selectItemAtFileCallback: item file clicked callback
    public func presentPhotoAlbum(controller: UIViewController,
                                  photoConfig: PhotoConfiguration,
                                  callback: (([SelectAssetModel], Bool) -> Void)?,
                                  fileAcquisitionCallback: (([SelectAssetModel], CGFloat, Bool) -> Bool)? = nil,
                                  selectItemAtFileCallback: ((SelectAssetModel) -> Void)? = nil) {
        self.imageCallback = callback
        self.fileAcquisitionCallback = fileAcquisitionCallback
        self.didSelectItemAtFileCallback = selectItemAtFileCallback
        self.show(sender: controller, photoConfig: photoConfig)
    }
    
    public func dismissPhotoPicker() {
        guard let controller = UIViewController.currentViewController() else { return }
        if controller.isMember(of: PhotoPickerViewController.self) || controller.isMember(of: PhotoPreviewController.self) {
            controller.dismiss(animated: true, completion: nil)
        }
    }
}

extension PhotoAlbumManager {
    /// 1. 检测权限
    /// 2. 展示图片选择器
    private func show(sender: UIViewController, photoConfig: PhotoConfiguration) {
        let status = PHPhotoLibrary.authorizationStatus()
        if status == .restricted || status == .denied {
            self.alertPhotoAuthor()
        } else if status == .notDetermined {
            PHPhotoLibrary.requestAuthorization { (status) in
                DispatchQueue.main.async {
                    if status == .denied {
                        self.alertPhotoAuthor()
                    } else if status == .authorized {
                        self.showPhotoPickerViewController(sender: sender, photoConfig: photoConfig)
                    }
                }
            }
        } else {
            self.showPhotoPickerViewController(sender: sender, photoConfig: photoConfig)
        }
    }
    
    private func showPhotoPickerViewController(sender: UIViewController, photoConfig: PhotoConfiguration) {
        PhotoAlbumManager.getCameraRollAlbum(allowSelectImage: photoConfig.allowSelectImage, allowSelectVideo: photoConfig.allowSelectVideo) { [weak self] (cameraRoll) in
            guard let self = self else { return }
            let pickerController = PhotoPickerViewController(viewModel: PhotoPickerViewModel(albumList: cameraRoll, photoConfig: photoConfig))
            let nav = self.getImageNav(rootViewController: pickerController, photoConfig: photoConfig)
            sender.showDetailViewController(nav, sender: nil)
        }
    }
    
    private func getImageNav(rootViewController: UIViewController, photoConfig: PhotoConfiguration) -> ImageNavViewController {
        let nav = ImageNavViewController(rootViewController: rootViewController, photoConfig: photoConfig)
        nav.modalPresentationStyle = .fullScreen
        nav.selectImageBlock = { [weak self] (models, original) in
            guard let self = self else { return }
            guard let callback = self.imageCallback else { return }
            callback(models, original)
        }
        if self.fileAcquisitionCallback != nil {
            nav.fileAcquisitionCallback = { [weak self] (modes, fileSize, original) in
                guard let self = self else { return true }
                guard let callback = self.fileAcquisitionCallback else { return true }
                return callback(modes, fileSize, original)
            }
        }
        if self.didSelectItemAtFileCallback != nil {
            nav.didSelectItemAtFileCallback = { [weak self] (model) in
                guard let self = self else { return }
                guard let callback = self.didSelectItemAtFileCallback else { return }
                return callback(model)
            }
        }
        nav.selectImageRequestErrorBlock = { (assets, indexs) in
            print("photo manager select request error assets: \(assets) , indexs: \(indexs)")
        }
        nav.arrSelectedModels.removeAll()
        
        return nav
    }
}
extension PhotoAlbumManager {
    /// Fetch the image of the specified size
    @discardableResult
    public static func fetchImage(for asset: PHAsset, size: CGSize, progress: ( (CGFloat, Error?, UnsafeMutablePointer<ObjCBool>, [AnyHashable: Any]?) -> Void )? = nil, completion: @escaping ( (UIImage?, Bool) -> Void )) -> PHImageRequestID {
        return self.fetchImage(for: asset, size: size, resizeMode: .fast, progress: progress, completion: completion)
    }
    
    /// 获取相册原数据 ⚠️此回调会根据系统原则可能会调用两次，第一次为默认展示小图，第二次才是原始大图
    /// - Parameters:
    ///   - completion: Bool isDegraded 是否为缩减图，使用者可在外部自行判断
    @discardableResult
    public static func fetchOriginalImage(for asset: PHAsset, progress: ( (CGFloat, Error?, UnsafeMutablePointer<ObjCBool>, [AnyHashable: Any]?) -> Void )? = nil, completion: @escaping ( (UIImage?, Bool) -> Void)) -> PHImageRequestID {
        return self.fetchImage(for: asset, size: PHImageManagerMaximumSize, resizeMode: .fast, progress: progress, completion: completion)
    }
    
    /// Fetch photos from result.
    static func fetchPhoto(in result: PHFetchResult<PHAsset>, ascending: Bool, allowSelectImage: Bool, allowSelectVideo: Bool, allowSelectGif: Bool, limitCount: Int = .max) -> [PhotoModel] {
        var models: [PhotoModel] = []
        let option: NSEnumerationOptions = ascending ? .init(rawValue: 0) : .reverse
        var count = 1
        
        result.enumerateObjects(options: option) { (asset, _, stop) in
            let m = PhotoModel(asset: asset)
            
            if m.type == .image, !allowSelectImage {
                return
            }
            if m.type == .video, !allowSelectVideo {
                return
            }
            if m.type == .gif, !allowSelectGif {
                return
            }
            
            if count == limitCount {
                stop.pointee = true
            }
            
            models.append(m)
            count += 1
        }
        
        return models
    }
    /// Fetch asset data.
    @discardableResult
    public static func fetchOriginalImageData(for asset: PHAsset, isNetworkAccessAllowed: Bool = true, progress: ( (CGFloat, Error?, UnsafeMutablePointer<ObjCBool>, [AnyHashable: Any]?) -> Void )? = nil, completion: @escaping ( (Data?, [AnyHashable: Any]?, Bool) -> Void)) -> PHImageRequestID {
        let option = PHImageRequestOptions()
        if (asset.value(forKey: "filename") as? String)?.hasSuffix("GIF") == true {
            option.version = .original
        }
        option.isNetworkAccessAllowed = isNetworkAccessAllowed
        option.resizeMode = .fast
        option.deliveryMode = .highQualityFormat
        option.progressHandler = { (pro, error, stop, info) in
            DispatchQueue.main.async {
                progress?(CGFloat(pro), error, stop, info)
            }
        }
        
        return PHImageManager.default().requestImageData(for: asset, options: option) { (data, _, _, info) in
            let cancel = info?[PHImageCancelledKey] as? Bool ?? false
            let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool ?? false)
            if !cancel {
                completion(data, info, isDegraded)
            }
        }
    }
    /// Fetch all album list.
    static func getPhotoAlbumList(ascending: Bool, allowSelectImage: Bool, allowSelectVideo: Bool, allowSelectGif: Bool, completion: ( ([AlbumListModel]) -> Void )) {
        let option = PHFetchOptions()
        if !allowSelectImage {
            option.predicate = NSPredicate(format: "mediaType == %ld", PHAssetMediaType.video.rawValue)
        }
        if !allowSelectVideo {
            option.predicate = NSPredicate(format: "mediaType == %ld", PHAssetMediaType.image.rawValue)
        }
        
        let smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .albumRegular, options: nil) as! PHFetchResult<PHCollection>
        let albums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: nil) as! PHFetchResult<PHCollection>
        let streamAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumMyPhotoStream, options: nil) as! PHFetchResult<PHCollection>
        let syncedAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumSyncedAlbum, options: nil) as! PHFetchResult<PHCollection>
        let sharedAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumCloudShared, options: nil) as! PHFetchResult<PHCollection>
        let arr = [smartAlbums, albums, streamAlbums, syncedAlbums, sharedAlbums]
        
        var albumList: [AlbumListModel] = []
        arr.forEach { (album) in
            album.enumerateObjects { (collection, _, _) in
                guard let collection = collection as? PHAssetCollection else { return }
                if collection.assetCollectionSubtype == .smartAlbumAllHidden {
                    return
                }
                if #available(iOS 11.0, *), collection.assetCollectionSubtype.rawValue > PHAssetCollectionSubtype.smartAlbumLongExposures.rawValue {
                    return
                }
                if collection.assetCollectionSubtype == .smartAlbumAnimated && !allowSelectGif {
                    return
                }
                
                let result = PHAsset.fetchAssets(in: collection, options: option)
                // 过滤空相册
                if result.count == 0 {
                    return
                }
                let title = self.getCollectionTitle(collection)
                
                if collection.assetCollectionSubtype == .smartAlbumUserLibrary {
                    // Album of all photos.
                    let m = AlbumListModel(title: title, result: result, collection: collection, option: option)
                    albumList.insert(m, at: 0)
                } else {
                    let m = AlbumListModel(title: title, result: result, collection: collection, option: option)
                    albumList.append(m)
                }
            }
        }
        
        completion(albumList)
    }
    
    /// Fetch camera roll album.
    static func getCameraRollAlbum(allowSelectImage: Bool, allowSelectVideo: Bool, completion: @escaping ( (AlbumListModel) -> Void )) {
        let option = PHFetchOptions()
        if !allowSelectImage {
            option.predicate = NSPredicate(format: "mediaType == %ld", PHAssetMediaType.video.rawValue)
        }
        if !allowSelectVideo {
            option.predicate = NSPredicate(format: "mediaType == %ld", PHAssetMediaType.image.rawValue)
        }
        
        let smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .albumRegular, options: nil)
        smartAlbums.enumerateObjects { (collection, _, stop) in
            if collection.assetCollectionSubtype == .smartAlbumUserLibrary {
                let result = PHAsset.fetchAssets(in: collection, options: option)
                let albumModel = AlbumListModel(title: self.getCollectionTitle(collection), result: result, collection: collection, option: option)
                completion(albumModel)
                stop.pointee = true
            }
        }
    }
    
    public static func fetchVideo(for asset: PHAsset, progress: ( (CGFloat, Error?, UnsafeMutablePointer<ObjCBool>, [AnyHashable: Any]?) -> Void )? = nil, completion: @escaping ( (AVPlayerItem?, [AnyHashable: Any]?, Bool) -> Void )) -> PHImageRequestID {
        let option = PHVideoRequestOptions()
        option.isNetworkAccessAllowed = true
        option.progressHandler = { (pro, error, stop, info) in
            DispatchQueue.main.async {
                progress?(CGFloat(pro), error, stop, info)
            }
        }
        
        if asset.isInCloud {
            return PHImageManager.default().requestExportSession(forVideo: asset, options: option, exportPreset: AVAssetExportPresetHighestQuality, resultHandler: { (session, info) in
                DispatchQueue.main.async {
                    let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool ?? false)
                    if let avAsset = session?.asset {
                        let item = AVPlayerItem(asset: avAsset)
                        completion(item, info, isDegraded)
                    }
                }
            })
        } else {
            return PHImageManager.default().requestPlayerItem(forVideo: asset, options: option) { (item, info) in
                DispatchQueue.main.async {
                    let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool ?? false)
                    completion(item, info, isDegraded)
                }
            }
        }
    }
    
    public static func isFetchImageError(_ error: Error?) -> Bool {
        guard let e = error as NSError? else {
            return false
        }
        if e.domain == "CKErrorDomain" || e.domain == "CloudPhotoLibraryErrorDomain" {
            return true
        }
        return false
    }
    
    public static func fetchAVAsset(forVideo asset: PHAsset, completion: @escaping ( (AVAsset?, [AnyHashable: Any]?) -> Void )) -> PHImageRequestID {
        let options = PHVideoRequestOptions()
        options.version = .original
        options.deliveryMode = .automatic
        options.isNetworkAccessAllowed = true
        
        if asset.isInCloud {
            return PHImageManager.default().requestExportSession(forVideo: asset, options: options, exportPreset: AVAssetExportPresetHighestQuality) { (session, info) in
                // iOS11 and earlier, callback is not on the main thread.
                DispatchQueue.main.async {
                    if let avAsset = session?.asset {
                        completion(avAsset, info)
                    } else {
                        completion(nil, info)
                    }
                }
            }
        } else {
            return PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { (avAsset, _, info) in
                DispatchQueue.main.async {
                    completion(avAsset, info)
                }
            }
        }
    }
    
    /// 判断asset是否为Video
    public static func isVideo(asset: PHAsset) -> Bool {
        return asset.mediaType == .video
    }
    
    /// 获取一组asset的fileSize
    public static func photosBytes(with models: [SelectAssetModel], completion: @escaping ( (CGFloat) -> Void )) {
        var totalSize = 0.0
        var modelCount = 0
        
        let call = { (asset: PHAsset) in
            guard let resources = asset.assetResources else { return }
            guard let fileSize = (resources.value(forKey: "fileSize") as? CLong) else { return }
            totalSize += CGFloat(fileSize)
            modelCount += 1
            if modelCount >= models.count {
                if let size = Double(String(format: "%.2f", arguments: [totalSize])) {
                    completion(size)
                } else {
                    completion(totalSize)
                }
            }
        }
                
        for model in models {
            guard let asset = model.asset else { return }
            if asset.isInCloud {
              call(asset)
            } else {
                if !isVideo(asset: asset) {
                    PhotoAlbumManager.fetchOriginalImageData(for: asset, isNetworkAccessAllowed: false, progress: nil, completion: { (data, _, _) in
                        if let data = data {
                            totalSize += CGFloat(data.count)
                        } else {
                            totalSize += 0
                        }
                        modelCount += 1
                        if modelCount >= models.count {
                            if let size = Double(String(format: "%.2f", arguments: [totalSize])) {
                                completion(size)
                            } else {
                                completion(totalSize)
                            }
                        }
                    })
                } else {
                    call(asset)
                }
            }
        }
    }
    
    /// Save image to album.
    public static func saveImageToAlbum(image: UIImage, completion: ( (Bool, PHAsset?) -> Void )? ) {
        let status = PHPhotoLibrary.authorizationStatus()
        
        if status == .denied || status == .restricted {
            completion?(false, nil)
            return
        }
        
        var placeholderAsset: PHObjectPlaceholder?
        PHPhotoLibrary.shared().performChanges({
            let newAssetRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
            placeholderAsset = newAssetRequest.placeholderForCreatedAsset
        }) { (suc, _) in
            DispatchQueue.main.async {
                if suc {
                    let asset = self.getAsset(from: placeholderAsset?.localIdentifier)
                    completion?(suc, asset)
                } else {
                    completion?(false, nil)
                }
            }
        }
    }
    
    /// Save video to album.
    public static func saveVideoToAlbum(url: URL, completion: ( (Bool, PHAsset?) -> Void )? ) {
        let status = PHPhotoLibrary.authorizationStatus()
        
        if status == .denied || status == .restricted {
            completion?(false, nil)
            return
        }
        
        var placeholderAsset: PHObjectPlaceholder?
        PHPhotoLibrary.shared().performChanges({
            let newAssetRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            placeholderAsset = newAssetRequest?.placeholderForCreatedAsset
        }) { (suc, _) in
            DispatchQueue.main.async {
                if suc {
                    let asset = self.getAsset(from: placeholderAsset?.localIdentifier)
                    completion?(suc, asset)
                } else {
                    completion?(false, nil)
                }
            }
        }
    }
    
    private class func fetchImage(for asset: PHAsset, size: CGSize, resizeMode: PHImageRequestOptionsResizeMode, progress: ( (CGFloat, Error?, UnsafeMutablePointer<ObjCBool>, [AnyHashable: Any]?) -> Void )? = nil, completion: @escaping ( (UIImage?, Bool) -> Void )) -> PHImageRequestID {
        let option = PHImageRequestOptions()
        option.resizeMode = resizeMode
        option.isNetworkAccessAllowed = true
        option.progressHandler = { (pro, error, stop, info) in
            DispatchQueue.main.async {
                progress?(CGFloat(pro), error, stop, info)
            }
        }
        
        return PHImageManager.default().requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: option) { (image, info) in
            var downloadFinished = false
            if let info = info {
                downloadFinished = !(info[PHImageCancelledKey] as? Bool ?? false) && (info[PHImageErrorKey] == nil)
            }
            
            /// 坏视频，允许返回
            if let info = info, isVideo(asset: asset), info[PHImageErrorKey] != nil {
                downloadFinished = true
            }
            
            let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool ?? false)
            if downloadFinished {
                completion(image, isDegraded)
            }
        }
    }
    
    private static func getAsset(from localIdentifier: String?) -> PHAsset? {
        guard let id = localIdentifier else {
            return nil
        }
        let result = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil)
        if result.count > 0 {
            return result[0]
        }
        return nil
    }
    
    private static func getCollectionTitle(_ collection: PHAssetCollection) -> String {
        if collection.assetCollectionType == .album {
            // Albums created by user.
            var title: String?
            title = collection.localizedTitle
            return title ?? "所有照片"
        }
        
        var title: String?
        title = collection.localizedTitle
        return title ?? "所有照片"
    }
}

extension PhotoAlbumManager {
    private func alertPhotoAuthor() {
//        AlertViewController.showAlert("提示".localString,
//                                      message: "请在iOS的\"设置-隐私\"选项中允许照片-读取和写入。".localString,
//                                      showCheckout: false,
//                                      firstButtonTitle: "取消".localString,
//                                      secondButtonTitle: "去开启".localString,
//                                      actionButtonColor: .COLOR_5A90FB,
//                                      opacity: 0.3 ) { [weak self] (_, index: Int) in
//            guard let self = self else { return }
//            if index == 1 {
//                jumpToAppSettingPage()
//            }
//        }
        
        let alert = UIAlertController(title: "提示", message: "请在iOS的\"设置-隐私\"选项中允许照片-读取和写入。", preferredStyle: .alert)
        let action = UIAlertAction(title: "去开启", style: .default) { _ in
            jumpToAppSettingPage()
        }
        alert.addAction(action)
        let cancel = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        alert.addAction(cancel)
        UIApplication.shared.keyWindow?.rootViewController?.showDetailViewController(alert, sender: nil)
    }
}
