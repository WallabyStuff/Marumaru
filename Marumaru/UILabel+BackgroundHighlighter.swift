//
//  UILabel+BackgroundHighlighter.swift
//  Marumaru
//
//  Created by 이승기 on 2022/05/24.
//

import UIKit

extension UILabel {
    func setBackgroundHighlight(with backgroundColor: UIColor?,
                                textColor: UIColor) {
        self.clipsToBounds = true
        self.layer.cornerRadius = 8
        self.backgroundColor = backgroundColor
        self.textColor = textColor
    }
}
