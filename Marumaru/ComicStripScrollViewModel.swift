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
    
    private var scenes = [ComicStripScene]()
    public var scenesObservable = BehaviorRelay<[ComicStripScene]>(value: [])
}

extension ComicStripScrollViewModel {
    public func updateScenes(_ newScenes: [ComicStripScene]) {
        scenes = newScenes
        scenesObservable.accept(newScenes)
    }
}

extension ComicStripScrollViewModel {
    
    public func getImageURL(_ imagePath: String) -> URL? {
        return MarumaruApiService.shared.getImageURL(imagePath)
    }
}
