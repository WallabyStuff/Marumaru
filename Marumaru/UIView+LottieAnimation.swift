//
//  UIView+LottieAnimation.swift
//  Marumaru
//
//  Created by 이승기 on 2022/05/26.
//

import UIKit
import Lottie

enum AnimationType {
    case general(GeneralType)
    case cat(CatType)
    
    enum GeneralType: String, CaseIterable {
        case comming_soon
        case eyes_blinking
        case fire_burning
        case trophy
    }
    
    enum CatType: String, CaseIterable {
        case loading_cat_radial
        case rainbow_cat
        case acrobatic_cat
        case bubble_tea_cat
        case lying_cat
        case sleeping_cat
    }
    
    var name: String {
        switch self {
        case .general(let generalType):
            return generalType.rawValue
        case .cat(let catType):
            return catType.rawValue
        }
    }
}

extension UIView {
    private struct LottieAnimationKeys {
        static var lottie = "com.marumaru.lottie"
        static var queue = "com.marumaru.queue"
    }
    
    func playRandomCatLottie(size: CGSize = .init(width: 120, height: 120)) {
        playLottie(animation: AnimationType.cat(.allCases.randomElement()!), size: size)
    }
    
    func playLottie(animation: AnimationType, size: CGSize = .init(width: 120, height: 120)) {
        let animationView = AnimationView(name: animation.name)
        animationView.loopMode = .loop
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
