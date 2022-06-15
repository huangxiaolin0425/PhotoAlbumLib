//
//  PhotoPreviewSelectedView.swift
//  wutong
//
//  Created by Jeejio on 2021/12/31.
//

import UIKit
import Photos

/// 预览视图显示的已选择照片列表
class PhotoPreviewSelectedView: UIView {
    private lazy var collectionView = UICollectionView()
    
    private var photoConfig: PhotoConfiguration
    
    private var arrSelectedModels: [PhotoModel]
    
    private var currentShowModel: PhotoModel
    
    var selectBlock: PhotoCompletionObjectHandler<PhotoModel>?
    
    var endSortBlock: PhotoCompletionObjectHandler<[PhotoModel]>?
    
    init(selModels: [PhotoModel], currentShowModel: PhotoModel, photoConfig: PhotoConfiguration) {
        self.arrSelectedModels = selModels
        self.currentShowModel = currentShowModel
        self.photoConfig = photoConfig
        super.init(frame: .zero)
        self.initialAppearance()
    }
    
    func initialAppearance() {
        self.backgroundColor = photoConfig.bottomToolViewBgColorOfPreviewVC
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 60, height: 60)
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        layout.scrollDirection = .horizontal
        
        layout.sectionInset = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16)
        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        self.collectionView.backgroundColor = .clear
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        self.collectionView.showsHorizontalScrollIndicator = false
        self.collectionView.alwaysBounceHorizontal = true
        self.addSubview(self.collectionView)
        
        self.collectionView.register(PhotoPreviewSelectedViewCell.self, forCellWithReuseIdentifier: String(describing: PhotoPreviewSelectedViewCell.self))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.collectionView.frame = CGRect(x: 0, y: 10, width: self.bounds.width, height: 85)
        if let index = self.arrSelectedModels.firstIndex(where: { $0 == self.currentShowModel }) {
            self.collectionView.scrollToItem(at: IndexPath(row: index, section: 0), at: .centeredHorizontally, animated: true)
        }
    }
    
    func currentShowModelChanged(model: PhotoModel) {
        guard !(self.currentShowModel == model) else {
            return
        }
        self.currentShowModel = model
        
        if let index = self.arrSelectedModels.firstIndex(where: { $0 == self.currentShowModel }) {
            self.collectionView.performBatchUpdates({
                self.collectionView.scrollToItem(at: IndexPath(row: index, section: 0), at: .centeredHorizontally, animated: true)
            }) { (_) in
                self.collectionView.reloadItems(at: self.collectionView.indexPathsForVisibleItems)
            }
        } else {
            self.collectionView.reloadItems(at: self.collectionView.indexPathsForVisibleItems)
        }
    }
    
    func addSelModel(model: PhotoModel) {
        self.arrSelectedModels.append(model)
        let ip = IndexPath(row: self.arrSelectedModels.count - 1, section: 0)
        self.collectionView.insertItems(at: [ip])
        self.collectionView.scrollToItem(at: ip, at: .centeredHorizontally, animated: true)
    }
    
    func removeSelModel(model: PhotoModel) {
        guard let index = self.arrSelectedModels.firstIndex(where: { $0 == model }) else {
            return
        }
        self.arrSelectedModels.remove(at: index)
        self.collectionView.deleteItems(at: [IndexPath(row: index, section: 0)])
    }
    
    func refreshCell(for model: PhotoModel) {
        guard let index = self.arrSelectedModels.firstIndex(where: { $0 == model }) else {
            return
        }
        self.collectionView.reloadItems(at: [IndexPath(row: index, section: 0)])
    }
}

extension PhotoPreviewSelectedView: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.arrSelectedModels.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: PhotoPreviewSelectedViewCell.self), for: indexPath) as? PhotoPreviewSelectedViewCell else {
            fatalError("Unknown cell type (\(PhotoPreviewSelectedViewCell.self)) for reuse identifier: \( String(describing: PhotoPreviewSelectedViewCell.self))")
        }
        let model = self.arrSelectedModels[indexPath.row]
        cell.config(with: model, photoConfig: photoConfig)
        
        if model == self.currentShowModel {
            cell.layer.borderWidth = 3
        } else {
            cell.layer.borderWidth = 0
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let model = self.arrSelectedModels[indexPath.row]
        self.currentShowModel = model
        self.collectionView.performBatchUpdates({
            self.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        }) { (_) in
            self.collectionView.reloadItems(at: self.collectionView.indexPathsForVisibleItems)
        }
        self.selectBlock?(model)
    }
}

class PhotoPreviewSelectedViewCell: UICollectionViewCell {
    private lazy var imageView = UIImageView()
    private var imageRequestID: PHImageRequestID = PHInvalidImageRequestID
    private var imageIdentifier: String = ""
    private var model: PhotoModel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.layer.borderWidth = 3
        self.layer.cornerRadius = 6
        self.layer.masksToBounds = true

        self.imageView = UIImageView()
        self.imageView.contentMode = .scaleAspectFill
        self.imageView.clipsToBounds = true
        self.contentView.addSubview(self.imageView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.imageView.frame = self.bounds
    }
    
    func config(with model: PhotoModel, photoConfig: PhotoConfiguration) {
        self.model = model

        let size = CGSize(width: self.bounds.width * 1.5, height: self.bounds.height * 1.5)
        
        if self.imageRequestID > PHInvalidImageRequestID {
            PHImageManager.default().cancelImageRequest(self.imageRequestID)
        }
        
        self.imageIdentifier = self.model.ident
        self.imageView.image = nil
        
        self.layer.borderColor = photoConfig.indexLabelBgColor.cgColor
        
        self.imageRequestID = PhotoAlbumManager.fetchImage(for: self.model.asset, size: size, completion: { [weak self] (image, _) in
            if self?.imageIdentifier == self?.model.ident {
                self?.imageView.image = image
            }
        })
    }
}
