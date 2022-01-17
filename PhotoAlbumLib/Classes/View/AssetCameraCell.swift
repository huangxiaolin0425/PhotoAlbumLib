//
//  AssetCameraCell.swift
//  wutong
//
//  Created by Jeejio on 2021/12/24.
//

import UIKit

class AssetCameraCell: UICollectionViewCell {
    private var imageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initialAppearance()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.imageView.frame = CGRect(x: 0, y: 0, width: self.bounds.width / 3, height: self.bounds.width / 3)
        self.imageView.center = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
    }
    
    func initialAppearance() {
        self.layer.cornerRadius = 8
        self.layer.masksToBounds = true
        self.layer.borderWidth = 1
        self.layer.borderColor = RGB(237, 237, 237).cgColor
        
        self.imageView = UIImageView(image: getImage("photo_takePicture"))
        self.imageView.contentMode = .scaleAspectFit
        self.imageView.clipsToBounds = true
        self.contentView.addSubview(self.imageView)
        self.backgroundColor = .white
    }
}
