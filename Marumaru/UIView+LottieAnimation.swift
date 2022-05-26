//
//  UIView+LottieAnimation.swift
//  Marumaru
//
//  Created by 이승기 on 2022/05/26.
//

import UIKit
import Lottie

enum AnimationType: String, CaseIterable {
    case loading_cat_black
    case rainbow_cat
    case loading_cat_radial
    case loading_cat
}

extension UIView {
    private struct LottieAnimationKeys {
        static var lottie = "com.marumaru.lottie"
        static var queue = "com.marumaru.queue"
    }
    
    func playLottie(animation: AnimationType = AnimationType.allCases.randomElement()!,
                    size: CGSize = .init(width: 120, height: 120)) {
        let animationView = AnimationView(name: animation.rawValue)
        self.addSubview(animationView)
        
        animationView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            animationView.centerXAnchor.constraint(equalTo: centerXAnchor),
            animationView.centerYAnchor.constraint(equalTo: centerYAnchor),
            animationView.widthAnchor.constraint(equalToConstant: size.width),
            animationView.heightAnchor.constraint(equalToConstant: size.height)
        ])
        
        animationView.play()
        activeLotties.add(animationView)
    }
    
    func stopLottie() {
        for element in activeLotties {
            if let activeLottie = element as? AnimationView {
                activeLottie.removeFromSuperview()
            } else {
                continue
            }
        }
    }
    
    private var activeLotties: NSMutableArray {
        if let activeLotties = objc_getAssociatedObject(self, &LottieAnimationKeys.lottie) as? NSMutableArray {
            return activeLotties
        } else {
            let activeLotties = NSMutableArray()
            objc_setAssociatedObject(self, &LottieAnimationKeys.lottie, activeLotties, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return activeLotties
        }
    }
}
