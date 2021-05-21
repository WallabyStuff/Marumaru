//
//  NetworkHandelr.swift
//  Marumaru
//
//  Created by 이승기 on 2021/04/22.
//

import UIKit

class NetworkHandler{
    
    var loadedImages = [URL: UIImage]()
    var runningRequest = [UUID: URLSessionDataTask]()
    
    @discardableResult
    func getImage(_ url: URL, _ completion: @escaping (Result<UIImage, Error>) -> Void) -> UUID?{
        
        if let image = loadedImages[url]{
            completion(.success(image))
            return nil
        }
        
        let uuid = UUID()
        
        let task = URLSession.shared.dataTask(with: url){ data, response, error in
            defer{self.runningRequest.removeValue(forKey: uuid)}
            
            if let data = data, let image = UIImage(data: data){
                self.loadedImages[url] = image
                completion(.success(image))
                return
            }
            
            guard let error = error else{
                return
            }
            
            guard (error as NSError).code == NSURLErrorCancelled else{
                completion(.failure(error))
                return
            }
            
        }
        
        task.resume()
        
        runningRequest[uuid] = task
        return uuid
    }
    
    func cancelLoadImage(_ uuid: UUID){
        runningRequest[uuid]?.cancel()
        runningRequest.removeValue(forKey: uuid)
    }
}
