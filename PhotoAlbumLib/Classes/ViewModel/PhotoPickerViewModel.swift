//
//  PhotoPickerViewModel.swift
//  wutong
//
//  Created by hxl on 2022/1/7.
//

import Foundation
import UIKit
import Photos

protocol PhotoPickerViewModelDelegate: AnyObject {
    func reloadData()
    func showEditImageVC(image: UIImage, model: PhotoModel, cell: AssetCell)
    func showPhotoPreviewController(photos: [PhotoModel], photoConfig: PhotoConfiguration, index: Int)
    func readytoReturn()
    func refreshBottomTool()
}

class PhotoPickerViewModel {
    weak var delegate: (PhotoPickerViewModelDelegate)?
    var arrDataSources: [PhotoModel] = []
    var albumList: AlbumListModel
    private(set) var photoConfig: PhotoConfiguration
    private lazy var fetchImageQueue: OperationQueue = OperationQueue()
    private(set) var isWebOneImage = false
    /// 记录是否需要刷新相册列表
    var hasTakeANewAsset = false

    init(albumList: AlbumListModel, photoConfig: PhotoConfiguration) {
        self.albumList = albumList
        self.photoConfig = photoConfig
    }
    
    func setAlbumList(model: AlbumListModel) {
        self.albumList = model
    }
    
    func loadPhotos(coordinator: ImageNavViewController) {
        if self.albumList.models.isEmpty {
            let loadingView = ProgressHUD(style: .darkBlur)
            loadingView.show()
            DispatchQueue.global().async {
                self.albumList.refetchPhotos(photoConfig: self.photoConfig)
                DispatchQueue.main.async {
                    self.arrDataSources.removeAll()
                    self.arrDataSources.append(contentsOf: self.albumList.models)
                    checkSelected(source: &self.arrDataSources, selected: &coordinator.arrSelectedModels)
                    loadingView.hide()
                    self.delegate?.reloadData()
                }
            }
        } else {
            self.arrDataSources.removeAll()
            self.arrDataSources.append(contentsOf: self.albumList.models)
            checkSelected(source: &self.arrDataSources, selected: &coordinator.arrSelectedModels)
            self.delegate?.reloadData()
        }
    }
    
    func showBottomToolBar() -> Bool {
        let condition1 = photoConfig.editAfterSelectThumbnailImage &&
        photoConfig.maxImagesCount == 1 &&
        (photoConfig.allowEditImage || photoConfig.allowEditVideo)
        let condition2 = photoConfig.maxImagesCount == 1 && !photoConfig.showSelectBtnWhenSingleSelect
        if condition1 || condition2 {
            return false
        }
        return true
    }
    
    func didSelectItemAt(indexPath: IndexPath, navController: ImageNavViewController, cell: AssetCell, offset: Int) {
        let model = arrDataSources[indexPath.row]
        
        let call = { [weak self] in
            guard let self = self else { return }
            if !self.photoConfig.allowPreviewPhotos {
                cell.btnSelectClick()
                return
            }
            if !cell.enableSelect, self.photoConfig.showInvalidMask { return }
            
            var index = indexPath.row
            if !self.photoConfig.sortAscending {
                index -= offset
            }
            
            self.delegate?.showPhotoPreviewController(photos: self.arrDataSources, photoConfig: self.photoConfig, index: index)
        }
        
        if photoConfig.maxImagesCount == 1, (model.type == .image || model.type == .livePhoto), photoConfig.allowCrop == true {
            let loadingView = ProgressHUD(style: .darkBlur)
            loadingView.show()
            PhotoAlbumManager.fetchImage(for: model.asset, size: model.previewSize) { [weak self] (image, isDegraded) in
                guard let self = self else { return }
                if !isDegraded {
                    loadingView.hide()
                    if let image = image {
                        self.delegate?.showEditImageVC(image: image, model: model, cell: cell)
                    } else {
                        showAlertView("图片加载失败", nil)
                    }
                }
            }
        } else if photoConfig.maxImagesCount == 1, (model.type == .image || model.type == .livePhoto) {
            if photoConfig.didSelectImageDirectreturn == true, photoConfig.allowPreviewPhotos == false {
                // 直接返回选中的图片
                navController.arrSelectedModels.append(model)
                self.delegate?.readytoReturn()
            } else {
                // 如果外部有点击回调， 那么直接返回选中的model
                if let callback = navController.didSelectItemAtFileCallback {
                    let operation = ImageRequstOperation(model: model, photoConfig: self.photoConfig, isOriginal: navController.isSelectedOriginal) { (image, data, asset) in
                        let models = SelectAssetModel()
                        models.photo = image
                        models.asset = asset ?? model.asset
                        models.data = data
                        models.icloud = model.asset.isInCloud
                        callback(models)
                    }
                    self.fetchImageQueue.addOperation(operation)
                } else {
                    self.isWebOneImage = true
                    navController.arrSelectedModels.removeAll()
                    navController.arrSelectedModels.append(model)
                    call()
                }
            }
        } else {
          call()
        }
    }
    
    func refreshCellIndexAndMaskViewAt(collectionView: UICollectionView, navController: ImageNavViewController, offset: Int) {
        let showIndex = photoConfig.showSelectedIndex
        let showMask = photoConfig.showSelectedMask || photoConfig.showInvalidMask
        
        guard showIndex || showMask else {
            return
        }
        
        let visibleIndexPaths = collectionView.indexPathsForVisibleItems
        
        visibleIndexPaths.forEach { (indexPath) in
            guard let cell = collectionView.cellForItem(at: indexPath) as? AssetCell else {
                return
            }
            var row = indexPath.row
            if !photoConfig.sortAscending {
                row -= offset
            }
            let model = arrDataSources[row]
            
            let arrSelectedModel = navController.arrSelectedModels
            var show = false
            var idx = 0
            var isSelected = false
            for (index, selectModel) in arrSelectedModel.enumerated() where selectModel == model {
                show = true
                idx = index + 1
                isSelected = true
                break
            }
            if showIndex {
                cell.setCellIndex(showIndexLabel: show, index: idx)
            }
            if showMask {
                cell.setCellMaskView(isSelected: isSelected, model: model)
            }
        }
    }
    
    func photoLibraryDidChange(changeInstance: PHChange, navController: ImageNavViewController) {
        guard let changes = changeInstance.changeDetails(for: albumList.result)
        else { return }
        DispatchQueue.main.async {
            // 相册变化后再次显示相册列表需要刷新
            self.albumList.result = changes.fetchResultAfterChanges
            if changes.hasIncrementalChanges {
                for sm in navController.arrSelectedModels {
                    let isDelete = changeInstance.changeDetails(for: sm.asset)?.objectWasDeleted ?? false
                    if isDelete {
                        navController.arrSelectedModels.removeAll { $0 == sm }
                    }
                }
                if !changes.removedObjects.isEmpty || !changes.insertedObjects.isEmpty {
                    self.albumList.models.removeAll()
                }
                
                self.loadPhotos(coordinator: navController)
            } else {
                for sm in navController.arrSelectedModels {
                    let isDelete = changeInstance.changeDetails(for: sm.asset)?.objectWasDeleted ?? false
                    if isDelete {
                        navController.arrSelectedModels.removeAll { $0 == sm }
                    }
                }
                self.albumList.models.removeAll()
                self.loadPhotos(coordinator: navController)
            }
            self.delegate?.refreshBottomTool()
        }
    }
    
    func handleDataArray(newModel: PhotoModel, collectionView: UICollectionView, navController: ImageNavViewController, sender: UIViewController?, offset: Int) {
        self.hasTakeANewAsset = true
        self.albumList.refreshResult()
        
        var insertIndex = 0
        
        if photoConfig.sortAscending {
            insertIndex = arrDataSources.count
            arrDataSources.append(newModel)
        } else {
            // 保存拍照的照片或者视频，说明肯定有camera cell
            insertIndex = offset
            arrDataSources.insert(newModel, at: 0)
        }
        
        var canSelect = true
        // If mixed selection is not allowed, and the newModel type is video, it will not be selected.
        if !photoConfig.allowPickingMultipleVideo, newModel.type == .video {
            canSelect = false
        }
        if canSelect, canAddModel(newModel, photoConfig: photoConfig, currentSelectCount: navController.arrSelectedModels.count, sender: sender, showAlert: false) {
            newModel.isSelected = true
            navController.arrSelectedModels.append(newModel)
        }
        
        let insertIndexPath = IndexPath(row: insertIndex, section: 0)
        collectionView.performBatchUpdates({
            collectionView.insertItems(at: [insertIndexPath])
        }) { (_) in
            collectionView.scrollToItem(at: insertIndexPath, at: .centeredVertically, animated: true)
            collectionView.reloadItems(at: collectionView.indexPathsForVisibleItems)
        }
        self.delegate?.refreshBottomTool()
    }
}
