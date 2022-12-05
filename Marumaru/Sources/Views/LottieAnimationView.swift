//
//  LottieAnimationView.swift
//  Marumaru
//
//  Created by 이승기 on 2022/12/03.
//

import UIKit

import Lottie

class LottieAnimationView: UIView {
    
    // MARK: - Properties
  
    private var _animationName: String = ""
    public var animationView = AnimationView()
    private var _insets: CGFloat = 0
    private var isPlaying = false
    
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
    
    @IBInspectable
    var insets: CGFloat {
        get {
            return _insets
        }
        set {
            _insets = newValue
            configureAnimationViewSize()
        }
    }
    
    
    // MARK: - Initializers
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    
    // MARK: - Update sizes
    
    override func updateConstraints() {
        super.updateConstraints()
        configureAnimationViewSize()
    }
    
    private func configureAnimationViewSize() {
        animationView.frame = .init(x: insets, y: insets,
                                    width: frame.width + -insets * 2,
                                    height: frame.height + -insets * 2)
    }
    
    
    // MARK: - Methods
    
    private func configureAnimationView() {
        animationView = AnimationView(name: animationName)
        animationView.loopMode = .loop
        animationView.sizeToFit()
        
        self.addSubview(animationView)
        configureAnimationViewSize()
        
        play()
    }
    
    public func play() {
        animationView.play()
        isPlaying = true
    }
    
    public func stop() {
        animationView.stop()
        isPlaying = false
    }
}
