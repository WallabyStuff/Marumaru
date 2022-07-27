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
    private let basePathManager = BasePathManager()
    
    public var isFinishStartAnimation = BehaviorRelay<Bool>(value: false)
    public var isFinishPreProccess = BehaviorRelay<Bool>(value: false)
}

extension SplashViewModel {
    public func replaceBasePath() {
        basePathManager.replaceToValidBasePath()
            .subscribe(on: ConcurrentDispatchQueueScheduler.init(qos: .background))
            .observe(on: MainScheduler.instance)
            .subscribe(onCompleted: { [weak self] in
                self?.isFinishPreProccess.accept(true)
            })
            .disposed(by: self.disposeBag)
    }
    
    public func finishStartAnimation() {
        isFinishStartAnimation.accept(true)
    }
}
