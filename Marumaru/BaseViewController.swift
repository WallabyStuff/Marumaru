//
//  BaseViewController.swift
//  Marumaru
//
//  Created by 이승기 on 2022/05/23.
//

import UIKit
import RxSwift

class BaseViewController: UIViewController {
    
    var disposeBag = DisposeBag()
    let regularAppbarHeight: CGFloat = 80
    let compactAppbarHeight: CGFloat = 52
    
    var isStatusBarHidden: Bool = false {
        didSet {
            setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    override var prefersStatusBarHidden: Bool {
           return isStatusBarHidden
    }
    
    func makeHapticFeedback() {
        let selectionFeedbackGenerator = UISelectionFeedbackGenerator()
        selectionFeedbackGenerator.selectionChanged()
    }
}
