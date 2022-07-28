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
    
    static var defaultBasePath = "https://marumaru291.com"
    private let testImagePath = "/img/logo2.png"
    private let remoteBasePath = "https://raw.githubusercontent.com/WallabyStuff/Marumaru/develop/Marumaru/Sources/SupportingFiles/basePath.rtf"
    private var disposeBag = DisposeBag()
    private let maxRetryCount = 512
    
    
    // MARK: - Methods
    
    public func replaceToValidBasePath() -> Completable {
        Completable.create { [weak self] observer in
            guard let self = self else {
                return Disposables.create()
            }
            
            self.compareAndReplaceWithRemoteBasePath()
                .subscribe(with: self, onCompleted: { strongSelf in
                    strongSelf.checkIsBasePathValid()
                        .retry(strongSelf.maxRetryCount)
                        .subscribe(with: strongSelf, onCompleted: { strongSelf in
                            // This is a necessary proccess to check wheter legacy basePath is available or not.
                            // Cuz new basePath and legacy basePath are both valid when basePath just updated.
                            strongSelf.increaseBasePathNumber()
                            strongSelf.checkIsBasePathValid()
                                .subscribe(onDisposed: {
                                    observer(.completed)
                                })
                                .disposed(by: strongSelf.disposeBag)
                        })
                        .disposed(by: strongSelf.disposeBag)
                })
                .disposed(by: self.disposeBag)
            
            return Disposables.create()
        }
    }
    
    private func compareAndReplaceWithRemoteBasePath() -> Completable {
        return Completable.create { [weak self] observer in
            guard let self = self else {
                return Disposables.create()
            }
            
            var basePath = Self.defaultBasePath
            if let localBasePath = MyUserDefault.basePath.getValue() as? String {
                basePath = localBasePath
                self.updateBasePath(localBasePath)
            }
            
            if let finalBasePathNumber = self.getBasePathNumber(basePath),
               let remoteBasePath = self.getRemoteBasePath(),
               let remoteBasePathNumber = self.getBasePathNumber(remoteBasePath) {
                if finalBasePathNumber < remoteBasePathNumber {
                    // BasePath is replaced with remote basePath
                    self.replaceWithRemoteBasePath()
                        .subscribe(onCompleted: {
                            observer(.completed)
                        }, onError: { error in
                            observer(.error(error))
                        })
                        .disposed(by: self.disposeBag)
                } else {
                    // BasePath is not replaced
                    observer(.completed)
                }
            } else {
                observer(.error(BasePathManagerError.failToGetURL))
            }
            
            return Disposables.create()
        }
    }
    
    private func checkIsBasePathValid() -> Completable {
        return Completable.create { [weak self] observer in
            guard let self = self else {
                return Disposables.create()
            }
            
            let basePath = Self.defaultBasePath
            let testImagePath = basePath.appending(self.testImagePath)
            
            if let url = URL(string: testImagePath) {
                do {
                    let data = try Data(contentsOf: url)
                    self.updateBasePath(basePath)
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
    
    private func replaceWithRemoteBasePath() -> Completable {
        return Completable.create { [weak self] observer in
            guard let self = self else {
                return Disposables.create()
            }
            
            if let remoteBasePath = self.getRemoteBasePath() {
                self.updateBasePath(remoteBasePath)
                observer(.completed)
            } else {
                observer(.error(BasePathManagerError.emptyDocuemnt))
            }
            
            return Disposables.create()
        }
    }
    
    private func getRemoteBasePath() -> String? {
        do {
            if let url = URL(string: self.remoteBasePath) {
                let html = try String(contentsOf: url, encoding: .utf8)
                let doc = try SwiftSoup.parse(html)
                let basePath = try doc.text()
                return basePath
            } else {
                return nil
            }
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
    
    private func getBasePathNumber(_ basePath: String) -> Int? {
        do {
            let pattern = "[0-9]{3}"
            let expression = try NSRegularExpression(pattern: pattern)
            let match = expression.firstMatch(in: basePath, range: basePath.fullRange)
            
            if let nsRange = match?.range,
               let range = Range(nsRange, in: basePath) {
                guard let pathNumber = Int(basePath[range]) else {
                    return nil
                }
                
                return pathNumber
            } else {
                return nil
            }
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
    
    private func updateBasePath(_ basePath: String) {
        Self.defaultBasePath = basePath
        MyUserDefault.basePath.setValue(basePath)
    }
}
