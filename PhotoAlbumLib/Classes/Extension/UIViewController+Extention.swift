//
//  UIViewController.swift
//  PhotoPickerTest
//
//  Created by chenfeng on 2022/1/16.
//

import Foundation
import UIKit

extension UIViewController {
    class func currentViewController(base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return currentViewController(base: nav.visibleViewController)
        }

        if let tab = base as? UITabBarController {
            return currentViewController(base: tab.selectedViewController)
        }

        if let presented = base?.presentedViewController {
            return currentViewController(base: presented)
        }
        return base
    }
}

