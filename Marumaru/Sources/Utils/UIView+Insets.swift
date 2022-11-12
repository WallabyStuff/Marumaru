//
//  UIView+EdgeInsets.swift
//  Marumaru
//
//  Created by 이승기 on 2022/02/08.
//

import UIKit

extension UIButton {
  func imageEdgeInsets(with inset: CGFloat) {
    self.imageEdgeInsets = UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)
  }
}

extension UIView {
  var csSafeAreaInsets: UIEdgeInsets {
    if #available(iOS 11.0, *) {
      return self.safeAreaInsets
    } else {
      return .zero
    }
  }
}
