//
//  NetworkHandelr.swift
//  Marumaru
//
//  Created by 이승기 on 2021/04/22.
//

import UIKit

import RxSwift
import RxCocoa

struct ImageResult {
    var imageCache: ImageCache
    var animate: Bool
}

class NetworkHandler {

    var disposeBag = DisposeBag()
    
    let imageCacheHandler = ImageCacheHandler()
    var runningRequest = [UUID: URLSessionDataTask]()
    var imageCaches: [ImageCache] = []
    
    init() {
        fetchImageCaches()
    }
    
    @discardableResult
    func getImage(_ url: URL, _ completion: @escaping (Result<ImageResult, Error>) -> Void) -> UUID? {
        
        // Check does image existing on Cache data
        var isExists = false
        
        imageCaches.forEach { imageCache in
            if imageCache.url == url.path {
                print("already exists")
                isExists = true
                let result = ImageResult(imageCache: imageCache, animate: false)
                completion(.success(result))
            }
        }

        if isExists { return nil }
        
        let uuid = UUID()
        
        // if image is not existing on Cache data download from url
        let task = URLSession.shared.dataTask(with: url) { data, _, error in
            defer {self.runningRequest.removeValue(forKey: uuid)}
            
            if let data = data, let image = UIImage(data: data) {
                let imageCache = ImageCache(url: url.path,
                                            image: image,
                                            imageAvgColor: image.averageColor ?? ColorSet.shadowColor!)
                
                print("Image load from url")
                // Image load from url & save to Cache
                let result = ImageResult(imageCache: imageCache, animate: true)
                completion(.success(result))
                
                // save image to CacheData
                self.imageCacheHandler.addData(imageCache)
                    .subscribe(on: MainScheduler.instance)
                    .subscribe { _ in
                        // Success saving image to cache data STATE
                        self.imageCaches.append(imageCache)
                    }
                    .disposed(by: self.disposeBag)

                return
            }
            
            guard let error = error else {
                return
            }
            
            guard (error as NSError).code == NSURLErrorCancelled else {
                completion(.failure(error))
                return
            }
        }
        
        // start loading image
        task.resume()
        
        self.runningRequest[uuid] = task
        return uuid
    }
    
    func cancelLoadImage(_ uuid: UUID) {
        runningRequest[uuid]?.cancel()
        runningRequest.removeValue(forKey: uuid)
    }
    
    private func fetchImageCaches() {
        imageCaches.removeAll()
        imageCacheHandler.fetchData()
            .subscribe { event in
                if let imageCaches = event.element {
                    self.imageCaches = imageCaches
                }
            }.disposed(by: disposeBag)
    }
}
