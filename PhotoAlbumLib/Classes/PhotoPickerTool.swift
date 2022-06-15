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

struct PhotoEnvironment {
    static let layout = PhotoLayout()
    static let device = Phone()
    
    struct PhotoLayout {
         let thumbCollectionViewItemSpacing: CGFloat = 10
         let thumbCollectionViewLineSpacing: CGFloat = 10
         let thumbCollectionViewFlowLayoutSectionInset: CGFloat = 10
        
         let previewCollectionViewHeight: CGFloat = 100
         let previcewCollectionItemSpacing: CGFloat = 40
    }
    
    struct Phone {
        private static let screen = UIScreen.main

        let kScreenWidth: CGFloat = screen.bounds.size.width
        let kScreenHeight: CGFloat = screen.bounds.size.height
        let kScreenScale: CGFloat = screen.scale
    }
}

func kIs_iphoneX() -> Bool {
    return PhotoEnvironment.device.kScreenWidth >= 375 && PhotoEnvironment.device.kScreenHeight >= 812
}

let kStatusBarHeight: CGFloat = kIs_iphoneX() ? 44.0 : 20
let kNavHeight = kStatusBarHeight + 44.0
let kSafeBottomHeight: CGFloat = kIs_iphoneX() ? 34.0 : 0
let kTabBarHeight: CGFloat = kSafeBottomHeight + 49


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

func showAlertView(_ message: String, _ sender: UIViewController?) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "确定", style: .default, handler: nil)
        alert.addAction(action)
        (sender ?? UIViewController.currentViewController())?.present(alert, animated: true, completion: nil)
    
//    AlertViewController.showAlert(message: message.localString,
//                                  showCheckout: false,
//                                  firstButtonTitle: nil,
//                                  secondButtonTitle: "确定".localString,
//                                  actionButtonColor: .COLOR_5A90FB,
//                                  opacity: 0.3 ) {(_, _) in
//    }
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
