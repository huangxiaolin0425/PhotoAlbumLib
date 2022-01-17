//
//  String+Extention.swift
//  PhotoPickerTest
//
//  Created by hxl on 2022/1/14.
//

import Foundation
import UIKit

extension String {
    // 字符串截取，传入需要截取的字符串开始位置(不按索引算)、结束位置(包含)
    func sub(from: Int = 0, to: Int? = nil) -> String {
        let end = to ?? count
        if count < end { return self } // 避免下标越界

        let start = self.startIndex
        let startIndex = self.index(start, offsetBy: from)
        let endIndex = self.index(start, offsetBy: end)
        return String(self[startIndex ..< endIndex])
    }
    
    func boundingRect(for font: UIFont, constrained size: CGSize) -> CGRect {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byWordWrapping
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: paragraph
        ]

        return self.boundingRect(with: size, options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine], attributes: attributes, context: nil)
    }
}
