//
//  AppbarView.swift
//  Marumaru
//
//  Created by 이승기 on 2021/08/13.
//

import UIKit
import Hero

class AppbarView: UIView {
    
    var _roundCorners: UIRectCorner = []
    var _cornerRadius: CGFloat = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure(frame: frame, cornerRadius: _cornerRadius, roundCorners: _roundCorners)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure(frame: frame, cornerRadius: _cornerRadius, roundCorners: _roundCorners)
    }
    
    func configure(frame: CGRect, cornerRadius: CGFloat = 0, roundCorners: UIRectCorner = []) {
        self.hero.id = "appbar"
        
        _cornerRadius = cornerRadius
        _roundCorners = roundCorners
        
        let path = UIBezierPath(roundedRect: frame,
                                byRoundingCorners: _roundCorners,
                                cornerRadii: CGSize(width: _cornerRadius, height: _cornerRadius))
        let maskLayer = CAShapeLayer()
        maskLayer.frame = self.bounds
        maskLayer.path = path.cgPath
        
        self.layer.mask = maskLayer
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        configure(frame: frame, cornerRadius: _cornerRadius, roundCorners: _roundCorners)
    }
}
