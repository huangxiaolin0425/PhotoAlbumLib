//
//  AlbumListNavView.swift
//  wutong
//
//  Created by Jeejio on 2021/12/24.
//

import UIKit
import Photos

class AlbumListTableView: UIView {
    private lazy var tableBgView = UIView()
    private lazy var tableView = UITableView()
    private let rowHight: CGFloat = 70
    private var selectedAlbum: AlbumListModel
    private var arrDataSource: [AlbumListModel] = []
    private var photoConfig: PhotoConfiguration
    var selectAlbumBlock: PhotoCompletionObjectHandler<AlbumListModel>?
    var hideBlock: PhotoCompletionHandler?
        
    init(selectedAlbum: AlbumListModel, photoConfig: PhotoConfiguration) {
        self.selectedAlbum = selectedAlbum
        self.photoConfig = photoConfig
        super.init(frame: .zero)
        self.initialAppearance()
        self.loadAlbumList()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        guard !self.isHidden else {
            return
        }
        
        let bgFrame = self.calculateBgViewBounds()
        
        self.tableBgView.layer.mask = nil
        self.tableBgView.roundCorners([.bottomLeft, .bottomRight], radius: 8)
        
        self.tableBgView.frame = bgFrame
        self.tableView.frame = self.tableBgView.bounds
    }
    
    private func initialAppearance() {
        self.clipsToBounds = true
        
        self.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        self.tableBgView = UIView()
        self.addSubview(self.tableBgView)
        
        self.tableView = UITableView(frame: .zero, style: .plain)
        self.tableView.separatorStyle = .none
        self.tableView.backgroundColor = .white
        self.tableView.tableFooterView = UIView()
        self.tableView.rowHeight = rowHight
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableBgView.addSubview(self.tableView)
        self.tableView.register(AlbumListCell.self, forCellReuseIdentifier: String(describing: AlbumListCell.self))
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapAction(_:)))
        tap.delegate = self
        self.addGestureRecognizer(tap)
    }
    
    func loadAlbumList(completion: PhotoCompletionHandler? = nil) {
        DispatchQueue.global().async {
            PhotoAlbumManager.getPhotoAlbumList(ascending: self.photoConfig.sortAscending, allowSelectImage: self.photoConfig.allowSelectImage, allowSelectVideo: self.photoConfig.allowSelectVideo, allowSelectGif: self.photoConfig.allowSelectGif) { [weak self] (albumList) in
                self?.arrDataSource.removeAll()
                self?.arrDataSource.append(contentsOf: albumList)
                
                DispatchQueue.main.async {
                    completion?()
                    self?.tableView.reloadData()
                }
            }
        }
    }
    /// 设置tableview展示最高度
   private func calculateBgViewBounds() -> CGRect {
        let contentH = CGFloat(self.arrDataSource.count) * rowHight
        
        let maxH = min(kScreenHeight - kTabBarHeight - kNavHeight, contentH)
    
        return CGRect(x: 0, y: 0, width: self.frame.width, height: maxH)
    }
    
    func show(reloadAlbumList: Bool) {
        if reloadAlbumList {
            if #available(iOS 14.0, *), PHPhotoLibrary.authorizationStatus(for: .readWrite) == .limited {
                self.loadAlbumList { [weak self] in
                    self?.animateShow()
                }
            } else {
                self.loadAlbumList()
                animateShow()
            }
        } else {
            animateShow()
        }
    }
    
    func hide() {
        var toFrame = self.tableBgView.frame
        toFrame.origin.y = -toFrame.height
        
        UIView.animate(withDuration: 0.25, animations: {
            self.alpha = 0
            self.tableBgView.frame = toFrame
        }) { (_) in
            self.isHidden = true
            self.alpha = 1
        }
    }
    
    private func animateShow() {
        let toFrame = self.calculateBgViewBounds()
        
        self.isHidden = false
        self.alpha = 0
        var newFrame = toFrame
        newFrame.origin.y -= newFrame.height
        
        if newFrame != self.tableBgView.frame {
            let path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: newFrame.width, height: newFrame.height), byRoundingCorners: [.bottomLeft, .bottomRight], cornerRadii: CGSize(width: 8, height: 8))
            self.tableBgView.layer.mask = nil
            let maskLayer = CAShapeLayer()
            maskLayer.path = path.cgPath
            self.tableBgView.layer.mask = maskLayer
        }
        
        self.tableBgView.frame = newFrame
        self.tableView.frame = self.tableBgView.bounds
        UIView.animate(withDuration: 0.25) {
            self.alpha = 1
            self.tableBgView.frame = toFrame
        }
    }
    
    @objc func tapAction(_ tap: UITapGestureRecognizer) {
        self.hide()
        self.hideBlock?()
    }
}

extension AlbumListTableView: UIGestureRecognizerDelegate {
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let gesture = gestureRecognizer.location(in: self)
        return !self.tableBgView.frame.contains(gesture)
    }
}

extension AlbumListTableView: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.arrDataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: AlbumListCell.self), for: indexPath) as? AlbumListCell else {
            fatalError("Unknown cell type (\(AlbumListCell.self)) for reuse identifier: \( String(describing: AlbumListCell.self))")
        }

        let model = self.arrDataSource[indexPath.row]
        cell.config(with: model, currentModel: self.selectedAlbum, photoConfig: photoConfig)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = self.arrDataSource[indexPath.row]
        self.selectedAlbum = model
        self.selectAlbumBlock?(model)
        self.hide()
        if let inx = tableView.indexPathsForVisibleRows {
            tableView.reloadRows(at: inx, with: .none)
        }
    }
}
