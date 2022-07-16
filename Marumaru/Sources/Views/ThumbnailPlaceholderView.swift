//
//  ThumbnailView.swift
//  Marumaru
//
//  Created by 이승기 on 2022/02/06.
//

import UIKit

class ThumbnailPlaceholderView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

extension ThumbnailPlaceholderView {
    func makeThubmailShadow() {
        self.layer.shadowColor = R.color.shadowBlack()!.cgColor
        self.layer.shadowOffset = CGSize(width: 0, height: 4)
        self.layer.shadowRadius = 12
        self.layer.shadowOpacity = 0.3
        self.layer.masksToBounds = false
        self.layer.shouldRasterize = true
    }
    
    func makeThumbnailShadow(with color: UIColor?) {
        self.layer.shadowColor = color == nil ? R.color.shadowBlack()!.cgColor : color!.cgColor
        self.layer.shadowOffset = CGSize(width: 0, height: 4)
        self.layer.shadowRadius = 12
        self.layer.shadowOpacity = 0
        self.layer.masksToBounds = false
        self.layer.shouldRasterize = true
        
        UIView.animate(withDuration: 0.5) {
            self.layer.shadowOpacity = 0.3
        }
    }
    
    func removeThumbnailShadow() {
        self.layer.shadowColor = nil
        self.layer.shadowRadius = 0
        self.layer.shadowOpacity = 0
        self.layer.borderWidth = 0
    }
}
