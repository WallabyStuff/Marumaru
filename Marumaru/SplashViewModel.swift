//
//  SplashViewModel.swift
//  Marumaru
//
//  Created by 이승기 on 2022/07/10.
//

import UIKit

import RxSwift
import RxCocoa

class SplashViewModel {
    
    
    // MARK: - Properties
    
    private var disposeBag = DisposeBag()
    public var isFinishStartAnimation = PublishRelay<Bool>()
    public var isFinishPreProccess = BehaviorRelay<Bool>(value: false)
}

extension SplashViewModel {
    public func replaceBasePath() {
        let basePathManager = BasePathManager()
        basePathManager.replaceToValidBasePath()
            .subscribe(onCompleted: { [weak self] in
                self?.isFinishPreProccess.accept(true)
            })
            .disposed(by: disposeBag)
    }
    
    public func finishStartAnimation() {
        isFinishStartAnimation.accept(true)
    }
}
