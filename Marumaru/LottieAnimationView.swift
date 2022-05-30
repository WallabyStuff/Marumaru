//
//  LottieAnimationView.swift
//  Marumaru
//
//  Created by 이승기 on 2022/05/30.
//

import UIKit
import Lottie

class LottieAnimationView: UIView {
    
    
    // MARK: - Properties
    private var _animationName: String = ""
    public var animationView = AnimationView()
    
    @IBInspectable
    var animationName: String {
        get {
            return _animationName
        }
        set {
            _animationName = newValue
            configureAnimationView()
        }
    }
    
    
    // MARK: - Initializers
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    
    // MARK: - Methods
    
    private func configureAnimationView() {
        animationView = AnimationView(name: animationName)
        animationView.loopMode = .loop
        animationView.sizeToFit()
        
        self.addSubview(animationView)
        animationView.translatesAutoresizingMaskIntoConstraints = false
        animationView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        animationView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        animationView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        animationView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        
        animationView.play()
    }
    
    public func play() {
        animationView.play()
    }
    
    public func stop() {
        animationView.stop()
    }
}
