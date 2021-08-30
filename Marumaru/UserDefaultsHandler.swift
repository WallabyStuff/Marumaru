//
//  UserDefaultsHandler.swift
//  Marumaru
//
//  Created by 이승기 on 2021/08/31.
//

import UIKit
import RxSwift

class UserDefaultsHandler {
    
    private var disposeBag = DisposeBag()
    private let daySec: Int64 = 86400
    
    private func updateLaunchDate() {
        UserDefaults.standard.set(Date.timeStamp, forKey: "launchDate")
    }
    
    func checkCacheNeedsCleanUp() {
        let lastLaunchDate = UserDefaults.standard.double(forKey: "launchDate")
        
        if (Double(Date.timeStamp) - lastLaunchDate) > Double(daySec) * 3 {
            let imageCacheHandler = ImageCacheHandler()
            imageCacheHandler.deleteAll()
                .subscribe()
                .disposed(by: disposeBag)
            
            updateLaunchDate()
        }
    }
}
