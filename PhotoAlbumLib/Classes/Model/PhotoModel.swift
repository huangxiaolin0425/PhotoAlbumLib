//
//  PhotoModel.swift
//  wutong
//
//  Created by Jeejio on 2021/12/23.
//

import Foundation
import Photos
import UIKit

class PhotoModel: Equatable {
    let ident: String
    let asset: PHAsset
    var type: PhotoModel.MediaType = .unknown
    var isSelected: Bool = false
    var duration: String = ""
    var whRatio: CGFloat {
        return CGFloat(self.asset.pixelWidth) / CGFloat(self.asset.pixelHeight)
    }
    
    var second: Int {
        guard type == .video else {
            return 0
        }
        return Int(round(asset.duration))
    }
    
    init(asset: PHAsset) {
        self.ident = asset.localIdentifier
        self.asset = asset
        
        self.type = self.transformAssetType(for: asset)
        if self.type == .video {
            self.duration = self.transformDuration(for: asset)
        }
    }
    
    private func transformAssetType(for asset: PHAsset) -> PhotoModel.MediaType {
        switch asset.mediaType {
        case .video:
            return .video
        case .image:
            if (asset.value(forKey: "filename") as? String)?.hasSuffix("GIF") == true {
                return .gif
            }
            if #available(iOS 9.1, *) {
                if asset.mediaSubtypes.contains(.photoLive) {
                    return .livePhoto
                }
            }
            return .image
        default:
            return .unknown
        }
    }
    
    private func transformDuration(for asset: PHAsset) -> String {
        let dur = Int(round(asset.duration))
        
        switch dur {
        case 0..<60:
            return String(format: "00:%02d", dur)
        case 60..<3600:
            let m = dur / 60
            let s = dur % 60
            return String(format: "%02d:%02d", m, s)
        case 3600...:
            let h = dur / 3600
            let m = (dur % 3600) / 60
            let s = dur % 60
            return String(format: "%02d:%02d:%02d", h, m, s)
        default:
            return ""
        }
    }
    
    var previewSize: CGSize {
        let scale: CGFloat = 2 // UIScreen.main.scale
        if self.whRatio.isNaN {
            let w = min(UIScreen.main.bounds.width, 600) * scale
            return CGSize(width: w, height: w)
        } else {
            if self.whRatio > 1 {
                let h = min(UIScreen.main.bounds.height, 600) * scale
                let w = h * self.whRatio
                return CGSize(width: w, height: h)
            } else {
                let w = min(UIScreen.main.bounds.width, 600) * scale
                let h = w / self.whRatio
                return CGSize(width: w, height: h)
            }
        }
    }
}
extension PhotoModel {
    enum MediaType: Int {
        case unknown = 0
        case image
        case gif
        case livePhoto // 目前没有处理该类型的展示动画
        case video
    }
}

func == (lhs: PhotoModel, rhs: PhotoModel) -> Bool {
    return lhs.ident == rhs.ident
}
