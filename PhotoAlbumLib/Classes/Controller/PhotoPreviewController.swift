//
//  PhotoPreviewController.swift
//  wutong
//
//  Created by Jeejio on 2021/12/27.
//

import UIKit

class PhotoPreviewController: UIViewController {
    static let previewVCScrollNotification = Notification.Name("previewVCScrollNotification")

    private lazy var navgationView = UIView()
    private lazy var backButton = UIButton(type: .custom)
    
    private lazy var bottomView = UIView()
    private lazy var selectButton = UIButton(type: .custom)
    private lazy var indexLabel = UILabel()
    private lazy var originalButton = UIButton(type: .custom)
    private lazy var doneButton = UIButton(type: .custom)
    
    private let arrDataSources: [PhotoModel]
    private let showBottomViewAndSelectBtn: Bool
    private var currentIndex: Int
    private var indexBeforOrientationChanged: Int
    private lazy var collectionView = UICollectionView()
    /// 预览条
    private var selPhotoPreview: PhotoPreviewSelectedView?
    private var photoConfig: PhotoConfiguration
    /// 顶部导航是否隐藏
    private var hideNavView = false
    private var isFirstAppear = true
    /// 界面消失时，通知上个界面刷新（针对预览视图）
    var dismissCallback: PhotoCompletionHandler?
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialAppearance()
        resetSubViewStatus()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard self.isFirstAppear else { return }
        self.isFirstAppear = false
        
        self.reloadCurrentCell()
    }
    
    init(photos: [PhotoModel], photoConfig: PhotoConfiguration, index: Int, showBottomViewAndSelectBtn: Bool = true) {
        self.arrDataSources = photos
        self.currentIndex = index
        self.showBottomViewAndSelectBtn = showBottomViewAndSelectBtn
        self.indexBeforOrientationChanged = index
        self.photoConfig = photoConfig
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let itemSpacing = PhotoLayout.previcewCollectionItemSpacing
        self.collectionView.frame = CGRect(x: -(itemSpacing / 2), y: 0, width: self.view.frame.width + itemSpacing, height: self.view.frame.height)
        
        self.navgationView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: kNavHeight)
        
        self.backButton.frame = CGRect(x: 0, y: kStatusBarHeight, width: 60, height: 44)
        /// 设置偏移量
        self.collectionView.setContentOffset(CGPoint(x: (self.view.frame.width + itemSpacing) * CGFloat(self.indexBeforOrientationChanged), y: 0), animated: false)
        self.collectionView.performBatchUpdates({
            self.collectionView.setContentOffset(CGPoint(x: (self.view.frame.width + itemSpacing) * CGFloat(self.indexBeforOrientationChanged), y: 0), animated: false)
        })
        
        let bottomViewH = 50 + kSafeBottomHeight
        if photoConfig.showPreviewSelectPhotoBar {
            self.selectButton.frame = CGRect(x: kScreenWidth - 40, y: 0, width: 25, height: 25)
            self.selectButton.centerY = self.backButton.centerY
        } else {
            self.selectButton.frame = CGRect(x: 15, y: 10, width: 25, height: 25)
        }
        self.indexLabel.frame = self.selectButton.bounds
        
        self.bottomView.frame = CGRect(x: 0, y: self.view.frame.height - bottomViewH, width: self.view.bounds.width, height: bottomViewH)
        
        self.originalButton.frame = CGRect(x: self.selectButton.right + 10, y: 10, width: 80, height: 30)
        
        self.doneButton.frame = CGRect(x: self.bottomView.bounds.width - 100 - 15, y: 10, width: 100, height: 36)
        
        resetBottomToolBtnStatus()
    }
    
    func initialAppearance() {
        view.backgroundColor = .black
        
        // nav view
        self.navgationView = UIView()
        self.navgationView.backgroundColor = photoConfig.navBarColorOfPreviewVC
        view.addSubview(self.navgationView)
        
        self.backButton = UIButton(type: .custom)
        self.backButton.setImage(getImage("nav_back_white"), for: .normal)
        self.backButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: 0)
        self.backButton.addTarget(self, action: #selector(backBtnClick), for: .touchUpInside)
        self.navgationView.addSubview(self.backButton)
        // collection view
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        
        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        self.collectionView.backgroundColor = .clear
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        self.collectionView.isPagingEnabled = true
        self.collectionView.showsHorizontalScrollIndicator = false
        self.collectionView.contentInsetAdjustmentBehavior = .never
        
        view.addSubview(self.collectionView)
        
        self.collectionView.register(PhotoPreviewCell.self, forCellWithReuseIdentifier: String(describing: PhotoPreviewCell.self))
        self.collectionView.register(GIFPreviewCell.self, forCellWithReuseIdentifier: String(describing: GIFPreviewCell.self))
        self.collectionView.register(VideoPreviewCell.self, forCellWithReuseIdentifier: String(describing: VideoPreviewCell.self))
        
        view.bringSubviewToFront(self.navgationView)
        
        // bottom view
        self.bottomView.backgroundColor = photoConfig.bottomToolViewBgColorOfPreviewVC
        view.addSubview(self.bottomView)
        
        if photoConfig.showPreviewSelectPhotoBar {
            let nav = self.navigationController as! ImageNavViewController
            self.selPhotoPreview = PhotoPreviewSelectedView(selModels: nav.arrSelectedModels, currentShowModel: self.arrDataSources[self.currentIndex], photoConfig: photoConfig)
            self.selPhotoPreview?.selectBlock = { [weak self] (model) in
                self?.scrollToSelPreviewCell(model)
            }
            self.selPhotoPreview?.endSortBlock = { [weak self] (models) in
                self?.refreshCurrentCellIndex(models)
            }
            self.view.addSubview(self.selPhotoPreview!)
        }
        
        self.selectButton = UIButton(type: .custom)
        self.selectButton.setImage(getImage("photo_preview_unselected"), for: .normal)
        self.selectButton.setImage(getImage("photo_preview_selected"), for: .selected)
//        self.selectButton.enlargeResponseEdge = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        self.selectButton.addTarget(self, action: #selector(selectBtnClick), for: .touchUpInside)
    
        if photoConfig.showPreviewSelectPhotoBar {
            self.navgationView.addSubview(self.selectButton)
        } else {
            self.bottomView.addSubview(self.selectButton)
        }
        self.indexLabel = UILabel()
        self.indexLabel.backgroundColor = photoConfig.indexLabelBgColor
        self.indexLabel.font = .regular(ofSize: 15)
        self.indexLabel.textColor = .white
        self.indexLabel.textAlignment = .center
        self.indexLabel.layer.cornerRadius = 25.0 / 2
        self.indexLabel.layer.masksToBounds = true
        self.indexLabel.isHidden = true
        self.selectButton.addSubview(self.indexLabel)
        
        self.originalButton.setImage(getImage("photo_unselected"), for: .normal)
        self.originalButton.setImage(getImage("photo_select"), for: .selected)
        self.originalButton.setImage(getImage("photo_select"), for: [.selected, .highlighted])
        self.originalButton.adjustsImageWhenHighlighted = false
        self.originalButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)
        self.originalButton.isHidden = !(photoConfig.allowSelectOriginal && photoConfig.allowSelectImage)
        self.originalButton.setTitleColor(UIColor.white, for: .normal)
        self.originalButton.setTitle("原图", for: .normal)
        self.originalButton.isSelected = (self.navigationController as! ImageNavViewController).isSelectedOriginal
        self.originalButton.titleLabel?.font = .regular(ofSize: 14)
        self.originalButton.addTarget(self, action: #selector(originalPhotoClick), for: .touchUpInside)
        self.bottomView.addSubview(self.originalButton)
        
        self.doneButton.layer.masksToBounds = true
        self.doneButton.layer.cornerRadius = 18
        self.doneButton.titleLabel?.font = .regular(ofSize: 14)
        self.doneButton.addTarget(self, action: #selector(doneBtnClick), for: .touchUpInside)
        self.bottomView.addSubview(self.doneButton)
        
        resetBottomToolBtnStatus()
    }
    
    private func resetBottomToolBtnStatus() {
        let nav = self.navigationController as! ImageNavViewController
        if nav.arrSelectedModels.count > 0 {
            self.doneButton.isEnabled = true
            let doneTitle = "发送" + "(" + String(nav.arrSelectedModels.count) + ")"
            self.doneButton.setTitle(photoConfig.showPreviewSelectPhotoBar ? "添加" : doneTitle, for: .normal)
            self.doneButton.backgroundColor = photoConfig.bottomToolViewBtnNormalBgColor
        } else {
            self.doneButton.isEnabled = false
            self.doneButton.setTitle(photoConfig.showPreviewSelectPhotoBar ? "添加" :"发送", for: .normal)
            self.doneButton.backgroundColor = photoConfig.bottomToolViewBtnDisableBgColor
        }
        self.originalButton.isSelected = nav.isSelectedOriginal
        self.doneButton.frame = CGRect(x: self.bottomView.bounds.width - 100 - 15, y: 10, width: 100, height: 36)
        
        if photoConfig.showPreviewSelectPhotoBar, let nav = self.navigationController as? ImageNavViewController {
            if !nav.arrSelectedModels.isEmpty {
                self.selPhotoPreview?.frame = CGRect(x: 0, y: kScreenHeight - (50 + kSafeBottomHeight) - PhotoLayout.previewCollectionViewHeight, width: self.view.frame.width, height: PhotoLayout.previewCollectionViewHeight)
            }
        }
    }
    
    func scrollToSelPreviewCell(_ model: PhotoModel) {
        guard let index = self.arrDataSources.lastIndex(of: model) else {
            return
        }
        self.collectionView.performBatchUpdates({
            self.collectionView.scrollToItem(at: IndexPath(row: index, section: 0), at: .centeredHorizontally, animated: false)
        }) { (_) in
            self.indexBeforOrientationChanged = self.currentIndex
            self.reloadCurrentCell()
        }
    }
    
    func refreshCurrentCellIndex(_ models: [PhotoModel]) {
        let nav = self.navigationController as? ImageNavViewController
        nav?.arrSelectedModels.removeAll()
        nav?.arrSelectedModels.append(contentsOf: models)
        guard photoConfig.showSelectedIndex else {
            return
        }
        self.resetIndexLabelStatus()
    }
    // MARK: btn actions
    @objc func backBtnClick() {
        self.dismissCallback?()
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func selectBtnClick() {
        let nav = self.navigationController as! ImageNavViewController
        let currentModel = self.arrDataSources[self.currentIndex]
        self.selectButton.layer.removeAllAnimations()
        if currentModel.isSelected {
            currentModel.isSelected = false
            nav.arrSelectedModels.removeAll { $0 == currentModel }
            self.selPhotoPreview?.removeSelModel(model: currentModel)
        } else {
            self.selectButton.layer.add(getSpringAnimation(), forKey: nil)
            if !canAddModel(currentModel, photoConfig: photoConfig, currentSelectCount: nav.arrSelectedModels.count, sender: self) {
                return
            }
            currentModel.isSelected = true
            nav.arrSelectedModels.append(currentModel)
            self.selPhotoPreview?.addSelModel(model: currentModel)
        }
        self.resetSubViewStatus()
    }
    
    private func resetSubViewStatus() {
        let nav = self.navigationController as! ImageNavViewController
        let currentModel = self.arrDataSources[self.currentIndex]
        
        if (!photoConfig.allowPickingMultipleVideo && currentModel.type == .video) || (!photoConfig.showSelectBtnWhenSingleSelect && photoConfig.maxImagesCount == 1) {
            self.selectButton.isHidden = true
        } else {
            self.selectButton.isHidden = false
        }
        self.selectButton.isSelected = self.arrDataSources[self.currentIndex].isSelected
        self.resetIndexLabelStatus()
        
        guard self.showBottomViewAndSelectBtn else {
            self.selectButton.isHidden = true
            self.bottomView.isHidden = true
            self.selPhotoPreview?.isHidden = true
            return
        }
        
        let selCount = nav.arrSelectedModels.count
        self.selPhotoPreview?.isHidden = selCount == 0
        resetBottomToolBtnStatus()
        
        if photoConfig.allowSelectOriginal && photoConfig.allowSelectImage {
            self.originalButton.isHidden = !((currentModel.type == .image) || (currentModel.type == .livePhoto && !photoConfig.allowSelectLivePhoto) || (currentModel.type == .gif && !photoConfig.allowSelectGif))
        }
        
        if photoConfig.showPreviewSelectPhotoBar {
            self.originalButton.isHidden = true
        }
    }
    /// 不展示 indexLabel 直接展示选中按钮
    private func resetIndexLabelStatus() {
        guard photoConfig.showSelectedIndex else {
            self.indexLabel.isHidden = true
            return
        }
        let nav = self.navigationController as! ImageNavViewController
        if let index = nav.arrSelectedModels.firstIndex(where: { $0 == self.arrDataSources[self.currentIndex] }) {
            self.indexLabel.isHidden = false
            self.indexLabel.text = String(index + 1)
        } else {
            self.indexLabel.isHidden = true
        }
        
        self.indexLabel.isHidden = true
    }
    private func reloadCurrentCell() {
        guard let cell = self.collectionView.cellForItem(at: IndexPath(row: self.currentIndex, section: 0)) else {
            return
        }
        if let cell = cell as? GIFPreviewCell {
            cell.loadGifWhenCellDisplaying()
        }
    }
    private func tapPreviewCell() {
        self.hideNavView = !self.hideNavView
        let currentCell = self.collectionView.cellForItem(at: IndexPath(row: self.currentIndex, section: 0))
        if let cell = currentCell as? VideoPreviewCell {
            if cell.isPlaying {
                self.hideNavView = true
            }
        }
        self.navgationView.isHidden = self.hideNavView
        self.bottomView.isHidden = self.showBottomViewAndSelectBtn ? self.hideNavView : true
        self.selPhotoPreview?.isHidden = self.bottomView.isHidden
    }
    
    @objc func originalPhotoClick() {
        originalButton.isSelected.toggle()
        
        let nav = (navigationController as? ImageNavViewController)
        nav?.isSelectedOriginal = originalButton.isSelected
        if nav?.arrSelectedModels.count == 0, originalButton.isSelected == true {
            selectBtnClick()
        }
    }
    
    @objc func doneBtnClick() {
        let nav = self.navigationController as! ImageNavViewController
        nav.requestSelectPhoto(viewController: nav)
    }
}

extension PhotoPreviewController: UICollectionViewDelegate {}

extension PhotoPreviewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.arrDataSources.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let model = self.arrDataSources[indexPath.row]
        let baseCell: PhotoPreviewBaseCell
        
        if photoConfig.allowSelectGif, model.type == .gif {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: GIFPreviewCell.self), for: indexPath) as? GIFPreviewCell else {
                fatalError("Unknown cell type (\(GIFPreviewCell.self)) for reuse identifier: \( String(describing: GIFPreviewCell.self))")
            }
            cell.singleTapBlock = { [weak self] in
                self?.tapPreviewCell()
            }
            cell.config(model: model, photoConfig: photoConfig)
            baseCell = cell
        } else if photoConfig.allowSelectVideo, model.type == .video {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: VideoPreviewCell.self), for: indexPath) as? VideoPreviewCell else {
                fatalError("Unknown cell type (\(VideoPreviewCell.self)) for reuse identifier: \( String(describing: VideoPreviewCell.self))")
            }
            cell.config(model: model)
            baseCell = cell
        } else {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: PhotoPreviewCell.self), for: indexPath) as? PhotoPreviewCell else {
                fatalError("Unknown cell type (\(PhotoPreviewCell.self)) for reuse identifier: \( String(describing: PhotoPreviewCell.self))")
            }
            cell.singleTapBlock = { [weak self] in
                self?.tapPreviewCell()
            }
            
            cell.config(model: model, photoConfig: photoConfig)
            
            baseCell = cell
        }
        
        baseCell.singleTapBlock = { [weak self] in
            self?.tapPreviewCell()
        }
        
        return baseCell
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? PhotoPreviewBaseCell {
            cell.resetSubViewStatusWhenCellEndDisplay()
        }
    }
}

extension PhotoPreviewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return PhotoLayout.previcewCollectionItemSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return PhotoLayout.previcewCollectionItemSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: PhotoLayout.previcewCollectionItemSpacing / 2, bottom: 0, right: PhotoLayout.previcewCollectionItemSpacing / 2)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: self.view.bounds.width, height: self.view.bounds.height)
    }
}

extension PhotoPreviewController {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView == self.collectionView else {
            return
        }
        NotificationCenter.default.post(name: PhotoPreviewController.previewVCScrollNotification, object: nil)
        let offset = scrollView.contentOffset
        var page = Int(round(offset.x / (self.view.bounds.width + PhotoLayout.previcewCollectionItemSpacing)))
        page = max(0, min(page, self.arrDataSources.count - 1))
        if page == self.currentIndex {
            return
        }
        self.currentIndex = page
        self.resetSubViewStatus()
                self.selPhotoPreview?.currentShowModelChanged(model: self.arrDataSources[self.currentIndex])
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.indexBeforOrientationChanged = self.currentIndex
        let cell = self.collectionView.cellForItem(at: IndexPath(row: self.currentIndex, section: 0))
        if let cell = cell as? GIFPreviewCell {
            cell.loadGifWhenCellDisplaying()
        }
    }
}
