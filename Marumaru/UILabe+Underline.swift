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
        
        let attributedText = NSMutableAttributedString(string: text)
        attributedText.addAttribute(NSAttributedString.Key.underlineStyle,
                                    value: NSUnderlineStyle.single.rawValue,
                                    range: self.fullRange)
        self.attributedText = attributedText
    }
    
    var fullRange: NSRange {
        if let text = self.text {
            return text.fullRange
        } else {
            return NSRange(location: 0, length: 0)
        }
    }
}

extension String {
    var fullRange: NSRange {
        return NSRange(location: 0, length: self.count)
    }
}
