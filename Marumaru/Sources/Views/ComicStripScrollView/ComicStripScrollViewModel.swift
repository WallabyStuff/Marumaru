//
//  ComicStripSceneScrollViewModel.swift
//  Marumaru
//
//  Created by 이승기 on 2022/06/03.
//

import Foundation

import RxSwift
import RxCocoa

class ComicStripScrollViewModel {
  
  
  // MARK: - Properties
  
  private var disposeBag = DisposeBag()
  
  public var scenes = BehaviorRelay<[ComicStripScene]>(value: [])
}

extension ComicStripScrollViewModel {
  public func updateScenes(_ newScenes: [ComicStripScene]) {
    scenes.accept(newScenes)
  }
}
