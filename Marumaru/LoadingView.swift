//
//  LoadingView.swift
//  Marumaru
//
//  Created by 이승기 on 2021/08/22.
//

import UIKit
import Lottie

class LoadingView: UIView {
    
    var animationView = AnimationView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    convenience init() {
            self.init(frame: CGRect.zero)
    }
    
    init(name: String, loopMode: LottieLoopMode = .loop, frame: CGRect) {
        super.init(frame: frame)
        
        self.isUserInteractionEnabled = false
        animationView.isUserInteractionEnabled = false
        
        animationView = AnimationView(name: name)
        animationView.frame = self.frame
        animationView.loopMode = loopMode
        animationView.contentMode = .scaleAspectFit
        animationView.center = self.center
        animationView.alpha = 0
        self.addSubview(animationView)
        animationView.translatesAutoresizingMaskIntoConstraints = false
        animationView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        animationView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        animationView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        animationView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        stop()
    }
    
    func setConstraint(width: CGFloat, targetView: UIView) {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.widthAnchor.constraint(equalToConstant: width).isActive = true
        self.heightAnchor.constraint(equalToConstant: width).isActive = true
        self.centerXAnchor.constraint(equalTo: targetView.centerXAnchor).isActive = true
        self.centerYAnchor.constraint(equalTo: targetView.centerYAnchor).isActive = true
    }
    
    func setWidthConstraint(width: CGFloat) {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.widthAnchor.constraint(equalToConstant: width).isActive = true
        self.heightAnchor.constraint(equalToConstant: width).isActive = true
    }
    
    func play() {
        animationView.startFadeInAnim(duration: 0.3)
        animationView.play()
    }
    
    func play(_ completion: @escaping (Bool) -> Void) {
        UIView.animate(withDuration: 0.3) {
            self.animationView.alpha = 1
        } completion: { isDone in
            completion(isDone)
        }
    }
    
    func stop() {
        animationView.startFadeOutAnim(duration: 0.3)
        animationView.stop()
    }
    
    func stop(_ completion: @escaping (Bool) -> Void) {
        UIView.animate(withDuration: 0.3) {
            self.animationView.alpha = 0
        } completion: { isDone in
            completion(isDone)
        }
    }
}
