//
//  PhotoPickerViewModel.swift
//  wutong
//
//  Created by hxl on 2022/1/7.
//

import Foundation

protocol PhotoPickerViewModelDelegate: AnyObject {
    func reloadData()
}

class PhotoPickerViewModel {
    weak var delegate: (PhotoPickerViewModelDelegate)?
    var arrDataSources: [PhotoModel] = []
    var albumList: AlbumListModel
    private(set) var photoConfig: PhotoConfiguration
    
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
}
