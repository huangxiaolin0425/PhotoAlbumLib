//
//  PhotoPickerViewController.swift
//  wutong
//
//  Created by Jeejio on 2021/12/24.
//

import UIKit
import Photos

class PhotoPickerViewController: UIViewController {
    private lazy var collectionView = UICollectionView()
    private lazy var bottomView = UIView()
    private lazy var previewButton = UIButton(type: .custom)
    private lazy var originalButton = UIButton(type: .custom)
    private lazy var doneButton = UIButton(type: .custom)
    private lazy var bottomLine = UIView()
    private var navgationView: AlbumListNavView?
    private var albumListTableView: AlbumListTableView?
    
    private var viewModel: PhotoPickerViewModel
    /// 记录是否需要刷新相册列表
    private var hasTakeANewAsset = false
    
    private var showCameraCell: Bool {
        if viewModel.photoConfig.showCaptureImageOnTakePhotoBtn {
            return true
        }
        return false
    }
    /// 照相按钮
    private var offset: Int {
        return (self.showCameraCell ? 1: 0)
    }
    
    init(viewModel: PhotoPickerViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        self.viewModel.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialAppearance()
        
        let nav = self.navigationController as! ImageNavViewController
        self.viewModel.loadPhotos(coordinator: nav)
        
        if #available(iOS 14.0, *), PHPhotoLibrary.authorizationStatus(for: .readWrite) == .limited {
            PHPhotoLibrary.shared().register(self)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = true
        self.collectionView.reloadItems(at: self.collectionView.indexPathsForVisibleItems)
        self.resetBottomToolBtnStatus() // 进入页面时刷新底部视图
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let navViewFrame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: kNavHeight)
        self.navgationView?.frame = navViewFrame
        self.albumListTableView?.frame = CGRect(x: 0, y: navViewFrame.maxY, width: self.view.bounds.width, height: self.view.bounds.height - navViewFrame.maxY)
        
        let showBottomToolBtns = viewModel.showBottomToolBar()
        
        let bottomViewH = 50 + kSafeBottomHeight
        
        if showBottomToolBtns {
            self.collectionView.frame = CGRect(x: 0, y: kNavHeight, width: kScreenWidth, height: kScreenHeight - kNavHeight - kTabBarHeight)
        } else {
            self.collectionView.frame = CGRect(x: 0, y: kNavHeight, width: kScreenWidth, height: kScreenHeight - kNavHeight)
        }
        
        guard showBottomToolBtns else { return }
        
        self.bottomView.frame = CGRect(x: 0, y: self.view.frame.height - bottomViewH, width: self.view.bounds.width, height: bottomViewH)
        
        self.previewButton.frame = CGRect(x: 15, y: 10, width: 50, height: 30)
        
        self.originalButton.frame = CGRect(x: self.previewButton.right + 10, y: 10, width: 80, height: 30)
        
        self.doneButton.frame = CGRect(x: self.bottomView.bounds.width - 100 - 15, y: 10, width: 100, height: 36)
        
        self.bottomLine.frame = CGRect(x: 0, y: 0, width: self.bottomView.width, height: 0.5)
    }
    
    func initialAppearance() {
        self.edgesForExtendedLayout = .all
        self.view.backgroundColor = viewModel.photoConfig.thumbnailBgColor
        
        let layout = UICollectionViewFlowLayout()
        let inset = PhotoLayout.thumbCollectionViewFlowLayoutSectionInset
        layout.sectionInset = UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)
        
        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        self.collectionView.backgroundColor = viewModel.photoConfig.thumbnailBgColor
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        self.collectionView.alwaysBounceVertical = true
        if #available(iOS 11.0, *) {
            self.collectionView.contentInsetAdjustmentBehavior = .always
        }
        view.addSubview(self.collectionView)
        
        self.collectionView.register(AssetCell.self, forCellWithReuseIdentifier: String(describing: AssetCell.self))
        self.collectionView.register(AssetCameraCell.self, forCellWithReuseIdentifier: String(describing: AssetCameraCell.self))
        
        setupNavView()
        setupBottomView()
    }
    
    func setupNavView() {
        let nav = self.navigationController as! ImageNavViewController
        
        self.navgationView = AlbumListNavView(title: self.viewModel.albumList.title, photoConfig: viewModel.photoConfig)
        guard let navView = navgationView else { return }
        
        navView.selectAlbumBlock = { [weak self] in
            if self?.albumListTableView?.isHidden == true {
                self?.albumListTableView?.show(reloadAlbumList: self?.hasTakeANewAsset ?? false)
                self?.hasTakeANewAsset = false
            } else {
                self?.albumListTableView?.hide()
            }
        }
        
        navView.cancelBlock = { [weak self] in
            let nav = self?.navigationController as? ImageNavViewController // 调用导航页的退出方法
            nav?.dismiss(animated: true, completion: {
                nav?.cancelBlock?()
            })
        }
        
        view.addSubview(navView)
        
        self.albumListTableView = AlbumListTableView(selectedAlbum: self.viewModel.albumList, photoConfig: viewModel.photoConfig)
        guard let navTableView = albumListTableView else { return }
        
        navTableView.isHidden = true
        
        navTableView.selectAlbumBlock = { [weak self] (album) in
            guard let self = self else { return }
            guard self.viewModel.albumList != album else { return }
            self.viewModel.albumList = album
            self.navgationView?.title = album.title
            self.viewModel.loadPhotos(coordinator: nav)
            self.navgationView?.reset()
        }
        
        navTableView.hideBlock = { [weak self] in
            guard let self = self else { return }
            self.navgationView?.reset()
        }
        
        view.addSubview(navTableView)
    }
    
    func setupBottomView() {
        self.bottomView.backgroundColor = viewModel.photoConfig.bottomToolViewBgColor
        view.addSubview(self.bottomView)
        
        bottomLine.backgroundColor = viewModel.photoConfig.separatorColor
        self.bottomView.addSubview(bottomLine)
        
        self.previewButton.setTitleColor(viewModel.photoConfig.bottomToolViewBtnNormalTitleColor, for: .normal)
        self.previewButton.setTitleColor(viewModel.photoConfig.bottomToolViewBtnDisableTitleColor, for: .disabled)
        self.previewButton.contentHorizontalAlignment = .left
        self.previewButton.setTitle("预览", for: .normal)
        self.previewButton.isHidden = !viewModel.photoConfig.showPreviewButtonInAlbum
        self.previewButton.titleLabel?.font = .regular(ofSize: 14)
        self.previewButton.addTarget(self, action: #selector(previewBtnClick), for: .touchUpInside)
        self.bottomView.addSubview(self.previewButton)
        
        self.originalButton.setTitleColor(viewModel.photoConfig.bottomToolViewBtnNormalTitleColor, for: .normal)
        self.originalButton.setTitleColor(viewModel.photoConfig.bottomToolViewBtnDisableTitleColor, for: .disabled)
        self.originalButton.contentHorizontalAlignment = .left
        self.originalButton.setTitle("原图", for: .normal)
        self.originalButton.setImage(getImage("photo_unselected"), for: .normal)
        self.originalButton.setImage(getImage("photo_select"), for: .selected)
        self.originalButton.setImage(getImage("photo_select"), for: [.selected, .highlighted])
        self.originalButton.adjustsImageWhenHighlighted = false
        self.originalButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)
        self.originalButton.isHidden = !(viewModel.photoConfig.allowSelectOriginal && viewModel.photoConfig.allowSelectImage)
        self.originalButton.isSelected = (self.navigationController as! ImageNavViewController).isSelectedOriginal
        self.originalButton.titleLabel?.font = .regular(ofSize: 14)
        self.originalButton.addTarget(self, action: #selector(originalPhotoClick), for: .touchUpInside)
        self.bottomView.addSubview(self.originalButton)
        
        self.doneButton.layer.masksToBounds = true
        self.doneButton.layer.cornerRadius = 18
        self.doneButton.titleLabel?.font = .regular(ofSize: 14)
        self.doneButton.addTarget(self, action: #selector(doneBtnClick), for: .touchUpInside)
        self.bottomView.addSubview(self.doneButton)
        
        if viewModel.photoConfig.showPreviewSelectPhotoBar {
            self.previewButton.isHidden = true
            self.originalButton.isHidden = true
        }
        
        guard let navTableView = albumListTableView else { return }
        view.bringSubviewToFront(navTableView)
    }
    func resetBottomToolBtnStatus() {
        guard viewModel.showBottomToolBar() else { return }
        
        let nav = self.navigationController as! ImageNavViewController
        if nav.arrSelectedModels.count > 0 {
            self.previewButton.isEnabled = true
            self.doneButton.isEnabled = true
            let doneTitle = "发送" + "(" + String(nav.arrSelectedModels.count) + ")"
            self.doneButton.setTitle(viewModel.photoConfig.showPreviewSelectPhotoBar ? "添加" : doneTitle, for: .normal)
            self.doneButton.backgroundColor = viewModel.photoConfig.bottomToolViewBtnNormalBgColor
        } else {
            self.previewButton.isEnabled = false
            self.doneButton.isEnabled = false
            self.doneButton.setTitle(viewModel.photoConfig.showPreviewSelectPhotoBar ? "添加" : "发送", for: .normal)
            self.doneButton.backgroundColor = viewModel.photoConfig.bottomToolViewBtnDisableBgColor
        }
        self.originalButton.isSelected = nav.isSelectedOriginal
        self.doneButton.frame = CGRect(x: self.bottomView.bounds.width - 100 - 15, y: 10, width: 100, height: 36)
    }
    
    // MARK: btn actions
    @objc func previewBtnClick() {
        let nav = self.navigationController as? ImageNavViewController
        guard let selectedModels = nav?.arrSelectedModels else { return }
        let previewController = PhotoPreviewController(photos: selectedModels, photoConfig: viewModel.photoConfig, index: 0)
        self.show(previewController, sender: nil)
    }
    
    @objc func originalPhotoClick() {
        self.originalButton.isSelected = !self.originalButton.isSelected
        (self.navigationController as? ImageNavViewController)?.isSelectedOriginal = self.originalButton.isSelected
    }
    
    @objc func doneBtnClick() {
        let nav = self.navigationController as? ImageNavViewController
        nav?.requestSelectPhoto(viewController: nav)
    }
    /// 滚动到最底部
    func scrollToBottom() {
        guard viewModel.photoConfig.sortAscending, self.viewModel.arrDataSources.count > 0 else {
            return
        }
        let index = self.viewModel.arrDataSources.count - 1 + self.offset
        self.collectionView.scrollToItem(at: IndexPath(row: index, section: 0), at: .centeredVertically, animated: false)
    }
}

extension PhotoPickerViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.viewModel.arrDataSources.count + self.offset
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if self.showCameraCell && ((viewModel.photoConfig.sortAscending && indexPath.row == self.viewModel.arrDataSources.count) || (!viewModel.photoConfig.sortAscending && indexPath.row == 0)) {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: AssetCameraCell.self), for: indexPath) as? AssetCameraCell else {
                fatalError("Unknown cell type (\(AssetCameraCell.self)) for reuse identifier: \( String(describing: AssetCameraCell.self))")
            }

            return cell
        }
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: AssetCell.self), for: indexPath) as? AssetCell else {
            fatalError("Unknown cell type (\(AssetCell.self)) for reuse identifier: \( String(describing: AssetCell.self))")
        }
        
        let model: PhotoModel
        
        if !viewModel.photoConfig.sortAscending {
            model = self.viewModel.arrDataSources[indexPath.row - self.offset]
        } else {
            model = self.viewModel.arrDataSources[indexPath.row]
        }
        cell.config(model: model, photoConfig: viewModel.photoConfig)

        let nav = self.navigationController as? ImageNavViewController
        cell.selectedBlock = { [weak self, weak nav, weak cell] (isSelected) in
            guard let self = self else { return }
            if !isSelected {
                let currentSelectCount = nav?.arrSelectedModels.count ?? 0
                // 检测是否可以选中
                guard canAddModel(model, photoConfig: self.viewModel.photoConfig, currentSelectCount: currentSelectCount, sender: self) else {
                    return
                }
                model.isSelected = true
                nav?.arrSelectedModels.append(model)
                cell?.buttonSelect.isSelected = true
                self.refreshCellIndexAndMaskView()
            } else {
                cell?.buttonSelect.isSelected = false
                model.isSelected = false
                nav?.arrSelectedModels.removeAll { $0 == model }
                self.refreshCellIndexAndMaskView()
            }
            self.resetBottomToolBtnStatus()
        }
        cell.indexLabel.isHidden = true
        if viewModel.photoConfig.showSelectedIndex {
            for (index, selM) in (nav?.arrSelectedModels ?? []).enumerated() where selM == model {
                cell.setCellIndex(showIndexLabel: true, index: index + 1)
                break
            }
        }
        
        cell.setCellMaskView(isSelected: model.isSelected, model: model)
                
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? AssetCell else {
            return
        }
        var index = indexPath.row
        if !viewModel.photoConfig.sortAscending {
            index -= self.offset
        }
        let model = self.viewModel.arrDataSources[index]
        cell.setCellMaskView(isSelected: model.isSelected, model: model)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        if cell is AssetCameraCell {
            fetchCameraStatus()
            return
        }
        let nav = self.navigationController as? ImageNavViewController
        
        guard let cell = cell as? AssetCell else { return }
                
        let model = self.viewModel.arrDataSources[indexPath.row]
        if viewModel.photoConfig.maxImagesCount == 1, (model.type == .image || model.type == .livePhoto), viewModel.photoConfig.allowCrop == true {
            let loadingView = ProgressHUD(style: .darkBlur)
            loadingView.show()
            PhotoAlbumManager.fetchImage(for: model.asset, size: model.previewSize) { [weak self] (image, isDegraded) in
                guard let self = self else { return }
                if !isDegraded {
                    loadingView.hide()
                    if let image = image {
                        self.showEditImageVC(image: image, model: model, cell: cell)
                    } else {
                        showAlertView("图片加载失败", nil)
                    }
                }
            }
        } else if viewModel.photoConfig.allowPreviewPhotos == false {
            /// 直接返回选中的图片
            nav?.arrSelectedModels.append(model)
            doneBtnClick()
        } else {
            if !viewModel.photoConfig.allowPreviewPhotos {
                cell.btnSelectClick()
                return
            }
            if !cell.enableSelect, viewModel.photoConfig.showInvalidMask { return }
            
            var index = indexPath.row
            if !viewModel.photoConfig.sortAscending {
                index -= self.offset
            }
            
            let previewController = PhotoPreviewController(photos: self.viewModel.arrDataSources, photoConfig: viewModel.photoConfig, index: index)
            self.show(previewController, sender: nil)
        }
    }
    
    private func showEditImageVC(image: UIImage, model: PhotoModel, cell: AssetCell) {
        let nav = self.navigationController as! ImageNavViewController
        let clipImageController = ClipImageViewController(model: model, image: image)
        clipImageController.imageClipBlock = { image in
            guard let block = nav.selectImageBlock else { return }
            let model = SelectAssetModel()
            model.photo = image
            block([model], nav.isSelectedOriginal)
        }
        self.show(clipImageController, sender: nil)
    }
    
    private func refreshCellIndexAndMaskView() {
        let showIndex = viewModel.photoConfig.showSelectedIndex
        let showMask = viewModel.photoConfig.showSelectedMask || viewModel.photoConfig.showInvalidMask
        
        guard showIndex || showMask else {
            return
        }
        
        let visibleIndexPaths = self.collectionView.indexPathsForVisibleItems
        
        visibleIndexPaths.forEach { (indexPath) in
            guard let cell = self.collectionView.cellForItem(at: indexPath) as? AssetCell else {
                return
            }
            var row = indexPath.row
            if !viewModel.photoConfig.sortAscending {
                row -= self.offset
            }
            let model = self.viewModel.arrDataSources[row]
            
            let arrSelectedModel = (self.navigationController as? ImageNavViewController)?.arrSelectedModels ?? []
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
}

extension PhotoPickerViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return PhotoLayout.thumbCollectionViewItemSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return PhotoLayout.thumbCollectionViewLineSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let columnCount = CGFloat(viewModel.photoConfig.columnCount)
        let totalW = collectionView.bounds.width - (columnCount + 1) * PhotoLayout.thumbCollectionViewItemSpacing
        let singleW = totalW / columnCount
        return CGSize(width: singleW, height: singleW)
    }
}

extension PhotoPickerViewController: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        guard let changes = changeInstance.changeDetails(for: self.viewModel.albumList.result)
        else { return }
        DispatchQueue.main.async {
            // 相册变化后再次显示相册列表需要刷新
            self.viewModel.albumList.result = changes.fetchResultAfterChanges
            let nav = (self.navigationController as! ImageNavViewController)
            if changes.hasIncrementalChanges {
                for sm in nav.arrSelectedModels {
                    let isDelete = changeInstance.changeDetails(for: sm.asset)?.objectWasDeleted ?? false
                    if isDelete {
                        nav.arrSelectedModels.removeAll { $0 == sm }
                    }
                }
                if (!changes.removedObjects.isEmpty || !changes.insertedObjects.isEmpty) {
                    self.viewModel.albumList.models.removeAll()
                }
                
                self.viewModel.loadPhotos(coordinator: nav)
            } else {
                for sm in nav.arrSelectedModels {
                    let isDelete = changeInstance.changeDetails(for: sm.asset)?.objectWasDeleted ?? false
                    if isDelete {
                        nav.arrSelectedModels.removeAll { $0 == sm }
                    }
                }
                self.viewModel.albumList.models.removeAll()
                self.viewModel.loadPhotos(coordinator: nav)
            }
            self.resetBottomToolBtnStatus()
        }
    }
}

extension PhotoPickerViewController {
    private func showCamera() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = false
        picker.videoQuality = .typeHigh
        picker.sourceType = .camera
        picker.cameraFlashMode = .auto
        var mediaTypes = [String]()
        if viewModel.photoConfig.allowTakePhoto {
            mediaTypes.append("public.image")
        }
        if viewModel.photoConfig.allowRecordVideo {
            mediaTypes.append("public.movie")
        }
        picker.mediaTypes = mediaTypes
        picker.videoMaximumDuration = TimeInterval(10)
        self.showDetailViewController(picker, sender: nil)
    }
    
    private func fetchCameraStatus() {
        PermissionsManager.shared.fetchStatus(for: .camera) { [weak self] (status) in
            guard let self = self else { return }
            switch status {
            case .notDetermined: self.requestPermission()
            case .denied: self.showPermissionAlert()
            default:
                self.showCamera()
            }
        }
    }
    
    private func requestPermission() {
        PermissionsManager.shared.request(permisson: .camera) { [weak self] (status) in
            guard let self = self else { return }
            if status == PermissionStatus.denied {
                self.showPermissionAlert()
            } else {
                self.showCamera()
            }
        }
    }
    
    private func showPermissionAlert() {
        let alert = UIAlertController(title: "提示", message: "请在“设置-隐私”选项中\n允许使用相机权限", preferredStyle: .alert)
        let action = UIAlertAction(title: "去开启", style: .default) { _ in
            jumpToAppSettingPage()
        }
        alert.addAction(action)
        let cancel = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        alert.addAction(cancel)
        UIApplication.shared.keyWindow?.rootViewController?.showDetailViewController(alert, sender: nil)
    }
    
    private func save(image: UIImage?, videoUrl: URL?) {
        let loadingView = ProgressHUD(style: .darkBlur)
        loadingView.show()
        if let image = image {
            PhotoAlbumManager.saveImageToAlbum(image: image) { [weak self] (suc, asset) in
                guard let self = self else { return }
                if suc, let at = asset {
                    let model = PhotoModel(asset: at)
                    self.handleDataArray(newModel: model)
                } else {
                    showAlertView("保存图片失败", nil)
                }
                loadingView.hide()
            }
        } else if let videoUrl = videoUrl {
            PhotoAlbumManager.saveVideoToAlbum(url: videoUrl) { [weak self] (suc, asset) in
                guard let self = self else { return }
                if suc, let at = asset {
                    let model = PhotoModel(asset: at)
                    self.handleDataArray(newModel: model)
                } else {
                    showAlertView("保存视频失败", nil)
                }
                loadingView.hide()
            }
        }
    }
    
    /// 刷新相册列表 和底部视图
    func handleDataArray(newModel: PhotoModel) {
        self.hasTakeANewAsset = true
        self.viewModel.albumList.refreshResult()
        
        let nav = self.navigationController as? ImageNavViewController
        var insertIndex = 0
        
        if viewModel.photoConfig.sortAscending {
            insertIndex = self.viewModel.arrDataSources.count
            self.viewModel.arrDataSources.append(newModel)
        } else {
            // 保存拍照的照片或者视频，说明肯定有camera cell
            insertIndex = self.offset
            self.viewModel.arrDataSources.insert(newModel, at: 0)
        }
        
        var canSelect = true
        // If mixed selection is not allowed, and the newModel type is video, it will not be selected.
        if !viewModel.photoConfig.allowPickingMultipleVideo, newModel.type == .video {
            canSelect = false
        }
        if canSelect, canAddModel(newModel, photoConfig: viewModel.photoConfig, currentSelectCount: nav?.arrSelectedModels.count ?? 0, sender: self, showAlert: false) {
            newModel.isSelected = true
            nav?.arrSelectedModels.append(newModel)
        }
        
        let insertIndexPath = IndexPath(row: insertIndex, section: 0)
        self.collectionView.performBatchUpdates({
            self.collectionView.insertItems(at: [insertIndexPath])
        }) { (_) in
            self.collectionView.scrollToItem(at: insertIndexPath, at: .centeredVertically, animated: true)
            self.collectionView.reloadItems(at: self.collectionView.indexPathsForVisibleItems)
        }
        
        self.resetBottomToolBtnStatus()
    }
}

extension PhotoPickerViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true) {
            let image = info[.originalImage] as? UIImage
            let url = info[.mediaURL] as? URL
            self.save(image: image, videoUrl: url)
        }
    }
}

extension PhotoPickerViewController: PhotoPickerViewModelDelegate {
    func reloadData() {
        self.collectionView.reloadData()
        self.scrollToBottom()
    }
}
