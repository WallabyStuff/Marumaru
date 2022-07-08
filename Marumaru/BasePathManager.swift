//
//  BasePathModifier.swift
//  Marumaru
//
//  Created by 이승기 on 2022/07/06.
//

import Foundation

import RxSwift
import SwiftSoup

enum BasePathManagerError: Error {
    case failToGetURL
    case emptyDocuemnt
}

class BasePathManager {
    
    
    // MARK: - Properties
    
    static var defaultBasePath = "https://marumaru266.com"
    private let testImagePath = "/img/logo2.png"
    private var disposeBag = DisposeBag()
    private let maxRetryCount = 20
    
    
    // MARK: - Methods
    
    public func replaceToValidBasePath() {
        if let basePath = MyUserDefault.basePath.getValue() as? String {
            Self.defaultBasePath = basePath
        } else {
            MyUserDefault.basePath.setValue(Self.defaultBasePath)
        }
        
        checkIsBasePathValid()
            .retry(maxRetryCount)
            .observe(on: MainScheduler.instance)
            .subscribe(with: self, onCompleted: { strongSelf in
                // This is a necessary proccess to check wheter legacy basePath is available or not.
                // Cuz new basePath and legacy basePath are both valid when basePath just updated.
                strongSelf.increaseBasePathNumber()
                strongSelf.checkIsBasePathValid()
                    .subscribe()
                    .disposed(by: strongSelf.disposeBag)
            })
            .disposed(by: disposeBag)
    }
    
    private func checkIsBasePathValid() -> Completable {
        return Completable.create { [weak self] observer in
            guard let self = self
                   else {
                return Disposables.create()
            }
            
            let basePath = Self.defaultBasePath
            let testImagePath = basePath.appending(self.testImagePath)
            
            if let url = URL(string: testImagePath) {
                do {
                    let data = try Data(contentsOf: url)
                    MyUserDefault.basePath.setValue(basePath)
                    observer(.completed)
                    print("Log.i ✅ The basePath is valid - \(testImagePath) \(data)")
                } catch {
                    self.increaseBasePathNumber()
                    observer(.error(error))
                    print("Log.i ❌ The basePath is invalid - \(testImagePath)")
                }
            } else {
                self.increaseBasePathNumber()
                observer(.error(BasePathManagerError.failToGetURL))
            }
            
            return Disposables.create()
        }
    }
    
    private func increaseBasePathNumber() {
        do {
            let basePath = Self.defaultBasePath
            let pattern = "[0-9]{3}"
            let expression = try NSRegularExpression(pattern: pattern)
            let match = expression.firstMatch(in: basePath, range: basePath.fullRange)
            
            if let nsRange = match?.range,
               let range = Range(nsRange, in: basePath) {
                guard let pathNumber = Int(basePath[range]) else {
                    return
                }
                
                let newBasePath = "https://marumaru\(pathNumber + 1).com"
                Self.defaultBasePath = newBasePath
            } else {
                return
            }
        } catch {
            print(error.localizedDescription)
            return
        }
    }
}
