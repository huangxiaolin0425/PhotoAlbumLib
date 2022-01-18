//
//  ViewController.swift
//  PhotoAlbumLib
//
//  Created by huangxiaolin0425 on 01/17/2022.
//  Copyright (c) 2022 huangxiaolin0425. All rights reserved.
//

import UIKit
import PhotoAlbumLib

class ViewController: UIViewController {

    let photoAlbumManager = PhotoAlbumManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let but = UIButton(type: .custom)
        but.addTarget(self, action: #selector(photoClick), for: .touchUpInside)
        but.frame = CGRect(x: 100, y: 400, width: 100, height: 50)
        but.backgroundColor = .red
        view.addSubview(but)
        // Do any additional setup after loading the view.
    }

    @objc func photoClick() {
        let photoConfig = PhotoConfiguration()
        photoConfig.chatConfiguration()
        photoAlbumManager.presentPhotoAlbum(controller: self, photoConfig: photoConfig) { [weak self] models, original in
        }
    }
}

