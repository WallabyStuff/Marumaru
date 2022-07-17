//
//  UIView+Animation.swift
//  Marumaru
//
//  Created by 이승기 on 2022/02/06.
//

import UIKit

extension UIView {
    func startFadeInAnimation(duration: Double, _ completion: ((Bool) -> Void)? = nil) {
        UIView.animate(withDuration: duration,
                       delay: 0,
                       options: [.curveEaseIn]) {
            self.alpha = 1
        } completion: { bool in
            completion?(bool)
        }
    }

    func startFadeOutAnimation(duration: Double, _ completion: ((Bool) -> Void)? = nil) {
        UIView.animate(withDuration: duration,
                       delay: 0,
                       options: [.curveEaseIn]) {
            self.alpha = 0
        } completion: { bool in
            completion?(bool)
        }
    }
}
