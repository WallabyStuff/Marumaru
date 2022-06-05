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
    public var imageSessionManager = ImageSessionManager()
    
    private var scenes = [ComicStripScene]()
    public var scenesObservable = BehaviorRelay<[ComicStripScene]>(value: [])
    
    public var imageRequestResults = [PublishRelay<UIImage>]()
    public var imageRequestUUIDs = [UUID?]()
}

extension ComicStripScrollViewModel {
    public func updateScenes(_ newScenes: [ComicStripScene]) {
        cancelAllRequests()
        imageRequestResults.removeAll()
        scenes = newScenes
        scenesObservable.accept(newScenes)
    }
}

extension ComicStripScrollViewModel {
    public func requestImage(_ index: Int, _ imagePath: String) {
        guard let urlString = getImageURLString(imagePath) else {
            return
        }
        
        let uuid = imageSessionManager.requestImage(urlString) { [weak self] result in
            do {
                let result = try result.get()
                let resultImage = result.imageCache.image
                
                if self?.imageRequestResults.isInBound(index) ?? false {
                    self?.imageRequestResults[index].accept(resultImage)
                }
            } catch {
                print(error.localizedDescription)
            }
        }
        
        imageRequestUUIDs.append(uuid)
    }
    
    public func prepareForRequestImage() {
        let task = PublishRelay<UIImage>()
        imageRequestResults.append(task)
    }
    
    public func getImageURLString(_ imagePath: String) -> String? {
        return MarumaruApiService.shared.getImageURL(imagePath)?.description
    }
    
    public func cancelAllRequests() {
        imageRequestUUIDs.forEach { uuid in
            if let uuid = uuid {
                imageSessionManager.cancelImageRequest(uuid)
            }
        }
    }
}
