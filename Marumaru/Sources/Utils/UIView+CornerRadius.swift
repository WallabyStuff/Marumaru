//
//  UIView+CornerRadius.swift
//  Marumaru
//
//  Created by 이승기 on 2022/07/23.
//

import UIKit

@IBDesignable
extension UIView {
  @IBInspectable
  var cornerRadius: CGFloat {
    get { return layer.cornerRadius }
    set { layer.cornerRadius = newValue }
  }
}
