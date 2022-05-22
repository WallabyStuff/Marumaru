//
//  MarumaruApiServiceViewModel.swift
//  Marumaru
//
//  Created by 이승기 on 2022/02/04.
//

import UIKit
import RxSwift
import RxCocoa

class MarumaruApiServiceViewModel {
    private let marumaruApiService = MarumaruApiService()
}

extension MarumaruApiServiceViewModel {
    public func requestImage(_ url: String, _ completion: @escaping (Result<ImageResult, Error>) -> Void) -> UUID? {
        let token = marumaruApiService.requestImage(url) { result in
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
        marumaruApiService.cancelImageRequest(token)
    }
}
