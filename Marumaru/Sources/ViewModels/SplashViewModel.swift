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
  public var isFinishPreProcess = BehaviorRelay<Bool>(value: false)
  public var showMessageAlert = PublishRelay<Void>()
}

extension SplashViewModel {
  public func replaceBasePath() {
    basePathManager.replaceWithValidBasePath()
      .subscribe(on: ConcurrentDispatchQueueScheduler.init(qos: .background))
      .observe(on: MainScheduler.instance)
      .subscribe(onCompleted: { [weak self] in
        self?.isFinishPreProcess.accept(true)
      }, onError: { [weak self] error in
        if error is BasePathManagerError {
          self?.showMessageAlert.accept(())
        }
      })
      .disposed(by: self.disposeBag)
  }
  
  public func finishStartAnimation() {
    isFinishStartAnimation.accept(true)
  }
}
