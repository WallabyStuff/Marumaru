//
//  UIString+Localizable.swift
//  Marumaru
//
//  Created by 이승기 on 2022/05/29.
//

import UIKit

extension String {
    func localized(_ comment: String = "") -> String {
        return NSLocalizedString(self, comment: comment)
    }
}
