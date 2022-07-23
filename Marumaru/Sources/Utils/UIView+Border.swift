//
//  UIView+Border.swift
//  Marumaru
//
//  Created by 이승기 on 2022/07/23.
//

import UIKit

@IBDesignable
extension UIView {
    @IBInspectable
    var borderWidth: CGFloat {
        get { return self.layer.borderWidth }
        set { self.layer.borderWidth = newValue }
    }
    
    @IBInspectable
    var borderColor: UIColor {
        get { return UIColor(cgColor: self.layer.borderColor ?? UIColor.clear.cgColor) }
        set { self.layer.borderColor = newValue.cgColor }
    }
}
