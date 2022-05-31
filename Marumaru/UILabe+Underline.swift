//
//  UILabe+Underline.swift
//  Marumaru
//
//  Created by 이승기 on 2022/06/01.
//

import UIKit

extension UILabel {
    func makeUnderline() {
        guard let text = text else {
            return
        }
        
        let fullRange = NSRange(location: 0, length: text.count)
        let attributedText = NSMutableAttributedString(string: text)
        attributedText.addAttribute(NSAttributedString.Key.underlineStyle,
                                      value: NSUnderlineStyle.single.rawValue,
                                      range: fullRange)
        self.attributedText = attributedText
    }
}
