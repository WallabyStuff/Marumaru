//
//  BaseViewController.swift
//  Marumaru
//
//  Created by 이승기 on 2022/05/23.
//

import UIKit

import RxSwift
import RxCocoa

class BaseViewController: UIViewController {
    
    var disposeBag = DisposeBag()
    let regularAppbarHeight: CGFloat = 72
    let compactAppbarHeight: CGFloat = 52
    
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
    func makeHapticFeedback() {
        let selectionFeedbackGenerator = UISelectionFeedbackGenerator()
        selectionFeedbackGenerator.selectionChanged()
    }
}
