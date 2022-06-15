//
//  BaseViewController.swift
//  Marumaru
//
//  Created by 이승기 on 2022/05/23.
//

import UIKit

import RxSwift
import RxCocoa

enum AppbarHeight: CGFloat {
    case regularAppbarHeight = 72
    case compactAppbarHeight = 52
}

class BaseViewController: UIViewController {
    
    var disposeBag = DisposeBag()
    let regularAppbarHeight = AppbarHeight.regularAppbarHeight.rawValue
    let compactAppbarHeight = AppbarHeight.compactAppbarHeight.rawValue
    
    var previousBaseFrameSize: CGRect = .zero
    let baseFrameSizeViewSizeDidChange = BehaviorRelay<CGRect>(value: .zero)
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let currentBaseViewSize = view.frame
        if previousBaseFrameSize != currentBaseViewSize {
            baseFrameSizeViewSizeDidChange.accept(currentBaseViewSize)
            previousBaseFrameSize = currentBaseViewSize
        }
    }
}

extension BaseViewController {
    func makeSelectionFeedback() {
        let selectionFeedbackGenerator = UISelectionFeedbackGenerator()
        selectionFeedbackGenerator.selectionChanged()
    }
    
    func makeImpactFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let impactFeedback = UIImpactFeedbackGenerator(style: style)
        impactFeedback.impactOccurred()
    }
}
