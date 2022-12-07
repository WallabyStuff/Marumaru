//
//  UIScrollView+ContentInset.swift
//  Marumaru
//
//  Created by 이승기 on 2022/07/23.
//

import UIKit

@IBDesignable
extension UIScrollView {
  @IBInspectable
  var topInset: CGFloat {
    get { return self.contentInset.top }
    set { self.contentInset.top = newValue }
  }
  
  @IBInspectable
  var leftInset: CGFloat {
    get { return self.contentInset.left }
    set { self.contentInset.left = newValue }
  }
  
  @IBInspectable
  var rightInset: CGFloat {
    get { return self.contentInset.right }
    set { self.contentInset.right = newValue }
  }
  
  @IBInspectable
  var bottomInset: CGFloat {
    get { return self.contentInset.bottom }
    set { self.contentInset.bottom = newValue }
  }
}
