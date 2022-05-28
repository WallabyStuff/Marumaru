//
//  UIView+NoticeLabel.swift
//  Marumaru
//
//  Created by 이승기 on 2022/05/27.
//

import UIKit

extension UIView {
    private struct NoticeLabelKey {
        static var label = "com.marumaru.noticeLabel"
    }
    
    func makeNoticeLabel(_ message: String,
                         contentInsets: UIEdgeInsets = .zero) {
        removeNoticeLabels()
        
        let containerView = UIView()
        addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: -contentInsets.left),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.heightAnchor.constraint(equalTo: heightAnchor),
            containerView.widthAnchor.constraint(equalTo: widthAnchor)
        ])
        
        let noticeLabel = UILabel()
        noticeLabel.text = message
        noticeLabel.numberOfLines = 3
        noticeLabel.textAlignment = .center
        noticeLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        noticeLabel.textColor = .systemGray2
        containerView.addSubview(noticeLabel)
        noticeLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            noticeLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            noticeLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            noticeLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])
        
        activeNoticeLabels.add(containerView)
    }
    
    func removeNoticeLabels() {
        for element in activeNoticeLabels {
            if let activeNoticeLabel = element as? UIView {
                activeNoticeLabel.removeFromSuperview()
            } else {
                continue
            }
        }
    }
    
    private var activeNoticeLabels: NSMutableArray {
        if let activeNoticeLabels = objc_getAssociatedObject(self, &NoticeLabelKey.label) as? NSMutableArray {
            return activeNoticeLabels
        } else {
            let activeNoticeLabels = NSMutableArray()
            objc_setAssociatedObject(self, &NoticeLabelKey.label, activeNoticeLabels, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return activeNoticeLabels
        }
    }
}
