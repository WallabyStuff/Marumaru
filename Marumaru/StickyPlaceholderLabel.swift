//
//  StickyPlaceholderLabel.swift
//  Marumaru
//
//  Created by 이승기 on 2022/02/06.
//

import UIKit

class StickyPlaceholderLabel: UILabel {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        setupDefaultAppearances()
    }
    
    private func setupDefaultAppearances() {
        textColor = R.color.textBlackLightest()
        font = UIFont.systemFont(ofSize: 17)
        textAlignment = .center
    }
}

extension StickyPlaceholderLabel {
    public func attatchLabel(text: String, to parentView: UIView) {
        self.text = text
        parentView.addSubview(self)
        self.translatesAutoresizingMaskIntoConstraints = false
        self.centerYAnchor.constraint(equalTo: parentView.centerYAnchor).isActive = true
        self.centerXAnchor.constraint(equalTo: parentView.centerXAnchor).isActive = true
    }
    
    public func detatchLabel() {
        self.removeFromSuperview()
    }
}
