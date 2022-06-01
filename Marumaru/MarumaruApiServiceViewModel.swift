//
//  MarumaruApiServiceViewModel.swift
//  Marumaru
//
//  Created by 이승기 on 2022/02/04.
//

import Foundation
import RxSwift
import RxCocoa

class MarumaruApiServiceViewModel {
    private let imageSessionManager = ImageSessionManager()
}

extension MarumaruApiServiceViewModel {
    public func requestImage(_ url: String, _ completion: @escaping (Result<ImageResult, Error>) -> Void) -> UUID? {
        let token = imageSessionManager.requestImage(url) { result in
            do {
                let result =  try result.get()
                completion(.success(result))
            } catch {
                print(error.localizedDescription)
            }
        }
        
        return token
    }
    
    public func cancelImageRequest(_ token: UUID) {
        imageSessionManager.cancelImageRequest(token)
    }
}
