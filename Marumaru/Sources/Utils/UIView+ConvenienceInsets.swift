//
//  UIView+ConvenienceInsets.swift
//  Marumaru
//
//  Created by 이승기 on 2022/06/08.
//

import UIKit

extension UIEdgeInsets {
  
  /// Convenience inset initializer. Default inset values are 0
  static func inset(top: CGFloat = 0,
                    left: CGFloat = 0,
                    bottom: CGFloat = 0,
                    right: CGFloat = 0) -> UIEdgeInsets {
    return .init(top: top, left: left, bottom: bottom, right: right)
  }
  
  /// Insets for TOP and BOTTOM
  static func topAndBottom(_ inset: CGFloat) -> UIEdgeInsets {
    return Self.inset(top: inset, bottom: inset)
  }
  
  /// Insets for LEFt and RIGHT
  static func leftAndRight(_ inset: CGFloat) -> UIEdgeInsets {
    return Self.inset(left: inset, right: inset)
  }
  
  /// Inset for TOP only
  static func top(_ inset: CGFloat) -> UIEdgeInsets {
    return Self.inset(top: inset)
  }
  
  /// Inset for LEFT only
  static func left(_ inset: CGFloat) -> UIEdgeInsets {
    return Self.inset(left: inset)
  }
  
  /// Inset for BOTTOM only
  static func bottom(_ inset: CGFloat) -> UIEdgeInsets {
    return Self.inset(bottom: inset)
  }
  
  /// Insets for RIGHT only
  static func right(_ inset: CGFloat) -> UIEdgeInsets {
    return Self.inset(right: inset)
  }
}
