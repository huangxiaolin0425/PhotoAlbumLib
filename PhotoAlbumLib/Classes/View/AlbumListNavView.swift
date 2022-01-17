//
//  AlbumListNavView.swift
//  wutong
//
//  Created by Jeejio on 2021/12/27.
//

import UIKit

// MARK: embed album list nav view
class AlbumListNavView: UIView {
    static let titleViewH: CGFloat = 30
    static let arrowH: CGFloat = 16
    
    var title: String {
        didSet {
            albumTitleLabel.text = title
            refreshTitleViewFrame()
        }
    }
        
    private lazy var bottomLine = UIView()
    
    private var photoConfig: PhotoConfiguration
    
    private lazy var titleBgControl = UIControl()
    
    private lazy var albumTitleLabel = UILabel()
    
    private lazy var arrowImageView = UIImageView(image: getImage("photo_nav_down"))
    
    private lazy var cancelButton = UIButton(type: .custom)
    
    var selectAlbumBlock: (() -> Void)?
    
    var cancelBlock: (() -> Void)?
    
    init(title: String, photoConfig: PhotoConfiguration) {
        self.title = title
        self.photoConfig = photoConfig
        super.init(frame: .zero)
        initialAppearance()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        refreshTitleViewFrame()
    }
    
    func refreshTitleViewFrame() {
        let albumTitleW = min(bounds.width / 2, title.boundingRect(for: UIFont.regular(ofSize: 15), constrained: CGSize(width: CGFloat.greatestFiniteMagnitude, height: 44)).width)
        let titleBgControlW = albumTitleW + AlbumListNavView.arrowH + 20
        cancelButton.frame = CGRect(x: 0, y: kStatusBarHeight, width: 44, height: 44)
        bottomLine.frame = CGRect(x: 0, y: self.frame.height - 0.5, width: self.frame.width, height: 0.5)
        UIView.animate(withDuration: 0.25) {
            self.titleBgControl.frame = CGRect(
                x: (self.frame.width - titleBgControlW) / 2,
                y: kStatusBarHeight + (44 - AlbumListNavView.titleViewH) / 2,
                width: titleBgControlW,
                height: AlbumListNavView.titleViewH
            )
            self.albumTitleLabel.frame = CGRect(x: 10, y: 0, width: albumTitleW, height: AlbumListNavView.titleViewH)
            self.arrowImageView.frame = CGRect(
                x: self.albumTitleLabel.frame.maxX + 3,
                y: (AlbumListNavView.titleViewH - AlbumListNavView.arrowH) / 2.0,
                width: AlbumListNavView.arrowH,
                height: AlbumListNavView.arrowH
            )
        }
    }
    
    func initialAppearance() {
        backgroundColor = photoConfig.navBarColor
        
        titleBgControl.backgroundColor = photoConfig.navEmbedTitleViewBgColor
        titleBgControl.layer.cornerRadius = AlbumListNavView.titleViewH / 2
        titleBgControl.layer.masksToBounds = true
        titleBgControl.addTarget(self, action: #selector(titleBgControlClick), for: .touchUpInside)
        addSubview(titleBgControl)
        
        albumTitleLabel.textColor = photoConfig.navTitleColor
        albumTitleLabel.font = .regular(ofSize: 15)
        albumTitleLabel.text = title
        albumTitleLabel.textAlignment = .center
        titleBgControl.addSubview(albumTitleLabel)
        
        arrowImageView.clipsToBounds = true
        arrowImageView.contentMode = .scaleAspectFill
        titleBgControl.addSubview(arrowImageView)
        
        cancelButton.setImage(getImage("nav_back"), for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelBtnClick), for: .touchUpInside)
        addSubview(cancelButton)
        
        bottomLine.backgroundColor = photoConfig.separatorColor
        addSubview(bottomLine)
    }
    
    @objc func titleBgControlClick() {
        selectAlbumBlock?()
        if self.arrowImageView.transform == .identity {
            UIView.animate(withDuration: 0.25) {
                self.arrowImageView.transform = CGAffineTransform(rotationAngle: .pi)
            }
        } else {
            UIView.animate(withDuration: 0.25) {
                self.arrowImageView.transform = .identity
            }
        }
    }
    
    @objc func cancelBtnClick() {
        cancelBlock?()
    }
    
    func reset() {
        UIView.animate(withDuration: 0.25) {
            self.arrowImageView.transform = .identity
        }
    }
}
