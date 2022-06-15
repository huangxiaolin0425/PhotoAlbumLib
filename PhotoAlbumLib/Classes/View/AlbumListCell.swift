//
//  AlbumListCell.swift
//  wutong
//
//  Created by Jeejio on 2021/12/24.
//

import UIKit

class AlbumListCell: UITableViewCell {
    private lazy var albumImageView = UIImageView()
    private lazy var titleLabel = UILabel()
    private lazy var countLabel = UILabel()
    private lazy var lineView = UIView()
    private lazy var selectButton = UIButton(type: .custom)
    private var imageIdentifier: String?
    private var model: AlbumListModel?
    private var photoConfig: PhotoConfiguration?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        initialAppearance()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
   
    override func layoutSubviews() {
        super.layoutSubviews()
            
        self.albumImageView.frame = CGRect(x: 15, y: 12, width: 46, height: 46)
        if let m = self.model {
            let titleW = min(self.bounds.width / 3 * 2, m.title.boundingRect(for: UIFont.regular(ofSize: 15), constrained: CGSize(width: CGFloat.greatestFiniteMagnitude, height: 30)).width)
            self.titleLabel.frame = CGRect(x: self.albumImageView.frame.maxX + 10, y: (self.bounds.height - 30) / 2, width: titleW, height: 30)
            
            let countSize = ("(" + String(m.count) + ")").boundingRect(for: UIFont.regular(ofSize: 15), constrained: CGSize(width: CGFloat.greatestFiniteMagnitude, height: 30))
            self.countLabel.frame = CGRect(x: self.titleLabel.frame.maxX + 10, y: (self.bounds.height - 30) / 2, width: countSize.width, height: 30)
        }
        self.selectButton.frame = CGRect(x: self.bounds.width - 30, y: (self.bounds.height - 24) / 2, width: 24, height: 24)
        self.lineView.frame = CGRect(x: 15, y: self.bounds.height - 1, width: self.bounds.width - 15, height: 0.5)
    }
    func initialAppearance() {
        albumImageView.contentMode = .scaleAspectFill
        albumImageView.clipsToBounds = true
        albumImageView.cornerRadius = 8
        self.contentView.addSubview(albumImageView)

        titleLabel.font = .regular(ofSize: 15)
      
        titleLabel.lineBreakMode = .byTruncatingTail
        contentView.addSubview(self.titleLabel)
        
        countLabel.font = .regular(ofSize: 15)
        contentView.addSubview(self.countLabel)
        
        selectButton.isUserInteractionEnabled = false
        selectButton.isHidden = true
        selectButton.setImage(getImage("imageAlbum_select"), for: .selected)
        contentView.addSubview(self.selectButton)
        
        contentView.addSubview(lineView)
        
        self.backgroundColor = .white
        titleLabel.textColor = .black
        countLabel.textColor = .black
        lineView.backgroundColor = .gray
    }
    
    func config(with model: AlbumListModel, currentModel: AlbumListModel, photoConfig: PhotoConfiguration) {
        self.model = model
        self.photoConfig = photoConfig
        
        guard let model = self.model else { return }
        self.albumImageView.image = getImage("albumsDefault")
        self.titleLabel.text = model.title
        self.countLabel.text = "(" + String(model.count) + ")"
        self.selectButton.isHidden = false
        self.selectButton.isSelected = model == currentModel
        
        self.imageIdentifier = model.headImageAsset?.localIdentifier
        if let asset = model.headImageAsset {
            let w = self.bounds.height * 2.5
            PhotoAlbumManager.fetchImage(for: asset, size: CGSize(width: w, height: w)) { [weak self] (image, _) in
                if self?.imageIdentifier == model.headImageAsset?.localIdentifier {
                    self?.albumImageView.image = image ?? getImage("albumsDefault")
                }
            }
        }
        guard let photoConfig = self.photoConfig else { return }
        self.backgroundColor = photoConfig.albumListBgColor
        titleLabel.textColor = photoConfig.albumListTitleColor
        countLabel.textColor = photoConfig.albumListCountColor
        lineView.backgroundColor = photoConfig.separatorColor
    }
}
