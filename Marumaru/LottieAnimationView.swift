//
//  LoadingView.swift
//  Marumaru
//
//  Created by 이승기 on 2021/08/22.
//

import UIKit
import Lottie

class LottieAnimationView {
    
    private var targetView = UIView()
    private var animationView = AnimationView()
    
    private func setupAnimationView(_ name: String, _ targetView: UIView) {
        animationView.isUserInteractionEnabled = false
        animationView = AnimationView(name: name)
        animationView.loopMode = .loop
        animationView.contentMode = .scaleAspectFit
        animationView.alpha = 0
        
        self.targetView = targetView
        targetView.addSubview(animationView)
    }
    
    private func configureAnimationViewConstraints(_ size: CGSize) {
        animationView.translatesAutoresizingMaskIntoConstraints = false
        animationView.centerXAnchor.constraint(equalTo: targetView.centerXAnchor).isActive = true
        animationView.centerYAnchor.constraint(equalTo: targetView.centerYAnchor).isActive = true
        animationView.widthAnchor.constraint(equalToConstant: size.width).isActive = true
        animationView.heightAnchor.constraint(equalToConstant: size.height).isActive = true
    }
    
    private func prepareForPlay(name: String, size: CGSize, targetView: UIView) {
        setupAnimationView(name, targetView)
        configureAnimationViewConstraints(size)
    }
}

extension LottieAnimationView {
    public func play(name: String, size: CGSize, to targetView: UIView) {
        prepareForPlay(name: name, size: size, targetView: targetView)
        
        animationView.startFadeInAnimation(duration: 0.3, nil)
        animationView.play()
    }
}

extension LottieAnimationView {
    func stop() {
        animationView.stop()
        animationView.removeFromSuperview()
    }
    
    func stop(_ completion: @escaping (Bool) -> Void) {
        UIView.animate(withDuration: 0.3) {
            self.animationView.alpha = 0
        } completion: { isDone in
            completion(isDone)
        }
    }
}
