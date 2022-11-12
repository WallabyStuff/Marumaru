//
//  UITextView+Padding.swift
//  Marumaru
//
//  Created by 이승기 on 2022/07/23.
//

import UIKit

@IBDesignable
extension UITextField {
  @IBInspectable
  var leftPadding: CGFloat {
    get { return self.leftView?.frame.width ?? 0 }
    set {
      let paddingView = UIView(frame: CGRect(x: 0, y: 0,
                                             width: newValue,
                                             height: self.frame.height))
      self.leftView = paddingView
      self.leftViewMode = .always
    }
    
  }
  
  @IBInspectable
  var rightPadding: CGFloat {
    get { return self.rightView?.frame.width ?? 0 }
    set {
      let paddingView = UIView(frame: CGRect(x: 0, y: 0,
                                             width: newValue, height: self.frame.height))
      self.rightView = paddingView
      self.rightViewMode = .always
    }
  }
}
