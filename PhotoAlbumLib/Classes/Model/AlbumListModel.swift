//
//  AlbumListModel.swift
//  wutong
//
//  Created by Jeejio on 2021/12/23.
//

import UIKit
import Photos

class AlbumListModel: NSObject {
    let title: String
    
    var count: Int {
        return result.count
    }
    
    var result: PHFetchResult<PHAsset>
    
    let collection: PHAssetCollection
    
    let option: PHFetchOptions
        
    var headImageAsset: PHAsset? {
        return result.lastObject
    }
    
    var models: [PhotoModel] = []
    
    var selectedModels: [PhotoModel] = []
    
    private var selectedCount: Int = 0
    
    init(title: String, result: PHFetchResult<PHAsset>, collection: PHAssetCollection, option: PHFetchOptions) {
        self.title = title
        self.result = result
        self.collection = collection
        self.option = option
    }
    
    func refetchPhotos(photoConfig: PhotoConfiguration) {
        let models = PhotoAlbumManager.fetchPhoto(in: self.result, ascending: photoConfig.sortAscending, allowSelectImage: photoConfig.allowSelectImage, allowSelectVideo: photoConfig.allowSelectVideo)
        self.models.removeAll()
        self.models.append(contentsOf: models)
    }
    
    func refreshResult() {
        self.result = PHAsset.fetchAssets(in: self.collection, options: self.option)
    }
}

func == (lhs: AlbumListModel, rhs: AlbumListModel) -> Bool {
    return lhs.title == rhs.title && lhs.count == rhs.count && lhs.headImageAsset?.localIdentifier == rhs.headImageAsset?.localIdentifier
}
