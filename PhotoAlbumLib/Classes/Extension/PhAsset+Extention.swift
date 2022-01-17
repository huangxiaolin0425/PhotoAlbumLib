//
//  PhAsset+Extention.swift
//  wutong
//
//  Created by Jeejio on 2021/12/28.
//

import Foundation
import Photos

extension PHAsset {
    // 此方法比较耗性能 不推荐批量获取判断
    var isInCloud: Bool {
        guard let resource = PHAssetResource.assetResources(for: self).first else {
            return false
        }
        return !(resource.value(forKey: "locallyAvailable") as? Bool ?? true)
    }
    
    var assetResources: PHAssetResource? {
        return PHAssetResource.assetResources(for: self).first
    }
}
