//
//  PhotoPickerTool.swift
//  wutong
//
//  Created by Jeejio on 2021/12/24.
//

import Foundation
import UIKit

typealias PhotoCompletionHandler = (() -> Void)
typealias PhotoCompletionObjectHandler<R> = ((R) -> Void)

let kScreenWidth: CGFloat = UIScreen.main.bounds.size.width
let kScreenHeight: CGFloat = UIScreen.main.bounds.size.height
let kScreenScale: CGFloat = UIScreen.main.scale
func kIs_iphoneX() -> Bool {
  return kScreenWidth >= 375 && kScreenHeight >= 812
}

let kStatusBarHeight: CGFloat = kIs_iphoneX() ? 44.0 : 20
let kNavHeight = kStatusBarHeight + 44.0
let kSafeBottomHeight: CGFloat = kIs_iphoneX() ? 34.0 : 0
let kTabBarHeight: CGFloat = kSafeBottomHeight + 49

struct PhotoLayout {
    static let thumbCollectionViewItemSpacing: CGFloat = 10
    static let thumbCollectionViewLineSpacing: CGFloat = 10
    static let thumbCollectionViewFlowLayoutSectionInset: CGFloat = 10
    
    static let previewCollectionViewHeight: CGFloat = 100
    static let previcewCollectionItemSpacing: CGFloat = 40
}

func RGB(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat) -> UIColor {
    return UIColor(red: red / 255, green: green / 255, blue: blue / 255, alpha: 1)
}

func checkSelected(source: inout [PhotoModel], selected: inout [PhotoModel]) {
    guard selected.count > 0 else {
        return
    }
    
    var selIds: [String: Bool] = [:]
    var selIdAndIndex: [String: Int] = [:]
    
    for (index, m) in selected.enumerated() {
        selIds[m.ident] = true
        selIdAndIndex[m.ident] = index
    }
    
    source.forEach { (m) in
        if selIds[m.ident] == true {
            m.isSelected = true
            selected[selIdAndIndex[m.ident]!] = m
        } else {
            m.isSelected = false
        }
    }
}

func getSpringAnimation() -> CAKeyframeAnimation {
    let animate = CAKeyframeAnimation(keyPath: "transform")
    animate.duration = 0.5
    animate.isRemovedOnCompletion = true
    animate.fillMode = .forwards
    
    animate.values = [
        CATransform3DMakeScale(0.7, 0.7, 1),
        CATransform3DMakeScale(1.2, 1.2, 1),
        CATransform3DMakeScale(0.8, 0.8, 1),
        CATransform3DMakeScale(1, 1, 1)
    ]
    return animate
}

func showAlertView(_ message: String, _ sender: UIViewController?) {
    let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
    let action = UIAlertAction(title: "确定", style: .default, handler: nil)
    alert.addAction(action)
    (sender ?? UIViewController.currentViewController())?.present(alert, animated: true, completion: nil)
//    ?.showDetailViewController(alert, sender: nil)
}

func canAddModel(_ model: PhotoModel, photoConfig: PhotoConfiguration, currentSelectCount: Int, sender: UIViewController?, showAlert: Bool = true) -> Bool {
    if currentSelectCount >= photoConfig.maxImagesCount {
        if showAlert {
            let message = String(format: "你最多只能选择 %zd 个文件", arguments: [photoConfig.maxImagesCount])
            showAlertView(message, sender)
        }
        return false
    }
    if currentSelectCount > 0 {
        if !photoConfig.allowPickingMultipleVideo, model.type == .video {
            return false
        }
    }
    if model.type == .video {
        if model.second > photoConfig.maxSelectVideoDuration {
            if showAlert {
                let message = String(format: "视频时长超过最大限制 %zd秒", arguments: [photoConfig.maxSelectVideoDuration])
                showAlertView(message, sender)
            }
            return false
        }
        if model.second < photoConfig.minSelectVideoDuration {
            if showAlert {
                let message = String(format: "视频时长小于最小限制 %zd秒", arguments: [photoConfig.minSelectVideoDuration])
                showAlertView(message, sender)
            }
            return false
        }
    }
    return true
}

func jumpToAppSettingPage() {
    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
    if UIApplication.shared.canOpenURL(url) {
        UIApplication.shared.open(url, completionHandler: nil)
    }
}
func getImage(_ named: String) -> UIImage? {
    return UIImage(named: named, in: Bundle.normal_module, compatibleWith: nil)
}
