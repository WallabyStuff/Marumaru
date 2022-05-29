//
//  ThumbnailView.swift
//  Marumaru
//
//  Created by 이승기 on 2022/02/06.
//

import UIKit

class ThumbnailView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

extension ThumbnailView {
    func setThubmailShadow() {
        self.layer.shadowColor = R.color.shadowBlack()!.cgColor
        self.layer.shadowOffset = CGSize(width: 0, height: 4)
        self.layer.shadowRadius = 12
        self.layer.shadowOpacity = 0.3
        self.layer.masksToBounds = false
        self.layer.shouldRasterize = true
    }
    
    func setThumbnailShadow(with color: UIColor?) {
        self.layer.shadowColor = color == nil ? R.color.shadowBlack()!.cgColor : color!.cgColor
        self.layer.shadowOffset = CGSize(width: 0, height: 4)
        self.layer.shadowRadius = 12
        self.layer.shadowOpacity = 0.3
        self.layer.masksToBounds = false
        self.layer.shouldRasterize = true
    }
    
    func removeThumbnailShadow() {
        self.layer.shadowColor = nil
        self.layer.shadowRadius = 0
        self.layer.shadowOpacity = 0
        self.layer.borderWidth = 0
    }
}
