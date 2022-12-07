//
//  TagLabel.swift
//  Marumaru
//
//  Created by 이승기 on 2022/02/03.
//

import UIKit

class TagLabel: UILabel {
  
  @IBInspectable var topInset: CGFloat = 5.0
  @IBInspectable var bottomInset: CGFloat = 5.0
  @IBInspectable var leftInset: CGFloat = 8.0
  @IBInspectable var rightInset: CGFloat = 8.0
  
  override func drawText(in rect: CGRect) {
    let insets = UIEdgeInsets.init(top: topInset, left: leftInset, bottom: bottomInset, right: rightInset)
    super.drawText(in: rect.inset(by: insets))
  }
  
  override var intrinsicContentSize: CGSize {
    let size = super.intrinsicContentSize
    return CGSize(width: size.width + leftInset + rightInset, height: size.height + topInset + bottomInset)
  }
}

extension TagLabel {
  func makeRoundedBackground(cornerRadius: CGFloat,
                             backgroundColor: UIColor?,
                             foregroundColor: UIColor?) {
    self.clipsToBounds = true
    self.backgroundColor = backgroundColor
    self.textColor = foregroundColor
    self.layer.cornerRadius = cornerRadius
    self.text = "\(self.text!)"
  }
  
  func removeRoundedBackground(foregroundColor: UIColor) {
    self.backgroundColor = .clear
    self.textColor = foregroundColor
  }
}
