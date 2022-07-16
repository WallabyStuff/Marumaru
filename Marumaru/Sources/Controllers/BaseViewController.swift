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
    
    
    // MARK: - LifeCycles
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNavigationBarStatic()
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


// MARK: - NavigationBar STYLE

extension BaseViewController {
    private func setNavigationBarStatic() {
        if #available(iOS 15, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithDefaultBackground()
            appearance.shadowColor = .clear
            appearance.backgroundColor = R.color.backgroundWhite()!
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
        }
        
        navigationController?.navigationBar.isTranslucent = false
    }
}
