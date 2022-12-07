//
//  UIScrollView+ScrollToTop.swift
//  Marumaru
//
//  Created by 이승기 on 2022/05/28.
//

import UIKit

extension UIScrollView {
  func scrollToTop(topInset: CGFloat = 0, animated: Bool = true) {
    let desiredOffset = CGPoint(x: 0, y: -topInset)
    setContentOffset(desiredOffset, animated: animated)
  }
  
  func scrollToLeft(leftInset: CGFloat = 0, animated: Bool) {
    let desiredOffset = CGPoint(x: -leftInset, y: 0)
    setContentOffset(desiredOffset, animated: animated)
  }
}
