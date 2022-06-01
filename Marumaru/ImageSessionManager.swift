//
//  ImageManager.swift
//  Marumaru
//
//  Created by 이승기 on 2022/06/01.
//

import UIKit

class ImageSessionManager {
    
    
    // MARK: - Properties
    
    private var runningRequest = [UUID: URLSessionDataTask]()
}

extension ImageSessionManager {
    @discardableResult
    public func requestImage(_ url: String, _ completion: @escaping (Result<ImageResult, Error>) -> Void) -> UUID? {
        guard let url = URL(string: url) else { return nil }
        let uuid = UUID()
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self else { return }
            
            defer {
                self.runningRequest.removeValue(forKey: uuid)
            }
            
            if let data = data, let image = UIImage(data: data) {
                let imageCache = ImageCache(url: url.path,
                                            image: image,
                                            imageAvgColor: image.averageColor ?? UIColor.gray)
                
                // Image load from url & save to Cache
                let result = ImageResult(imageCache: imageCache, animate: true)
                completion(.success(result))
                
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
    
    public func cancelImageRequest(_ uuid: UUID) {
        runningRequest[uuid]?.cancel()
        runningRequest.removeValue(forKey: uuid)
    }
}
