//
//  UIView+ConvenienceInsets.swift
//  Marumaru
//
//  Created by 이승기 on 2022/06/08.
//

import UIKit

extension UIEdgeInsets {
    static func topAndBottom(_ inset: CGFloat) -> UIEdgeInsets {
        return Self.inset(top: inset, bottom: inset)
    }
    
    static func leftAndRight(_ inset: CGFloat) -> UIEdgeInsets {
        return Self.inset(left: inset, right: inset)
    }
    
    static func top(_ inset: CGFloat) -> UIEdgeInsets {
        return Self.inset(top: inset)
    }
    
    static func left(_ inset: CGFloat) -> UIEdgeInsets {
        return Self.inset(left: inset)
    }
    
    static func bottom(_ inset: CGFloat) -> UIEdgeInsets {
        return Self.inset(bottom: inset)
    }
    
    static func right(_ inset: CGFloat) -> UIEdgeInsets {
        return Self.inset(right: inset)
    }
    
    static func inset(top: CGFloat = 0,
                      left: CGFloat = 0,
                      bottom: CGFloat = 0,
                      right: CGFloat = 0) -> UIEdgeInsets {
        return .init(top: top, left: left, bottom: bottom, right: right)
    }
}
