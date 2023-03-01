//
//  BasePathModifier.swift
//  Marumaru
//
//  Created by 이승기 on 2022/07/06.
//

import RxSwift
import SwiftSoup

enum BasePathManagerError: Error {
  case failToGetURL
  case emptyDocument
  case basePathNotFound
}

class BasePathManager {
  
  // MARK: - Properties
  
  private var localBasePath = UserDefaultsManager.basePath
  static let TEST_IMAGE_PATH = "/img/logo2.png"
  static let REMOTE_BASE_PATH = "https://raw.githubusercontent.com/WallabyStuff/Marumaru/develop/Marumaru/Sources/SupportingFiles/basePath.rtf"
  static let MAX_RETRY_COUNT = 256
  
  private var disposeBag = DisposeBag()
  
  
  // MARK: - Methods
  
  public func replaceWithValidBasePath() -> Completable {
    Completable.create { [weak self] observer in
      guard let self = self else { return Disposables.create() }
      
      self.startBasePathUpdatingProcess()
        .andThen(self.startFinalBasePathValidationCheck())
        .subscribe(onDisposed: {
          observer(.completed)
        })
        .disposed(by: self.disposeBag)
      
      return Disposables.create()
    }
  }
  
  private func startBasePathUpdatingProcess() -> Completable {
    return Completable.create { [weak self] observer in
      guard let self = self else { return Disposables.create() }
      
      self.compareAndReplaceWithRemoteBasePath()
      
      self.checkBasePathValidationAndUpdate()
        .retry(Self.MAX_RETRY_COUNT)
        .subscribe(onCompleted: {
          observer(.completed)
        }, onError: { error in
          observer(.error(error))
        })
        .disposed(by: self.disposeBag)
      
      return Disposables.create()
    }
  }
  
  /// This is a necessary process to check whether legacy basePath is available or not.
  /// Cuz new basePath and legacy basePath are both valid when basePath just updated.
  private func startFinalBasePathValidationCheck() -> Completable {
    return Completable.create { [weak self] observer in
      guard let self = self else { return Disposables.create() }
      
      self.increaseBasePathNumber()
      self.checkBasePathValidationAndUpdate()
        .subscribe(onCompleted: {
          observer(.completed)
        }, onError: { error in
          observer(.error(error))
        })
        .disposed(by: self.disposeBag)
      
      return Disposables.create()
    }
  }
  
  private func compareAndReplaceWithRemoteBasePath() {
    guard let remoteBasePath = self.fetchRemoteBasePath(),
          let remoteBasePathNumber = self.getBasePathNumber(remoteBasePath),
          let localBasePathNumber = self.getBasePathNumber(self.localBasePath) else {
      return
    }
    
    /// Compare remote base path number with local base path number and replace with it
    if remoteBasePathNumber < localBasePathNumber {
      /// Update base path with remote base path
      self.updateBasePath(remoteBasePath)
    }
  }
  
  private func checkBasePathValidationAndUpdate() -> Completable {
    return Completable.create { [weak self] observer in
      guard let self = self else { return Disposables.create() }
      
      let testImagePath = self.localBasePath.appending(Self.TEST_IMAGE_PATH)
      if let url = URL(string: testImagePath) {
        do {
          /// Base path is available
          let data = try Data(contentsOf: url)
          self.updateBasePath(self.localBasePath)
          observer(.completed)
          print("Log.i ✅ The basePath is valid - \(testImagePath), \(data)")
        } catch {
          /// Base path in not available
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
      let pattern = "[0-9]{3}"
      let expression = try NSRegularExpression(pattern: pattern)
      let match = expression.firstMatch(in: localBasePath, range: localBasePath.fullRange)
      
      if let nsRange = match?.range,
         let range = Range(nsRange, in: localBasePath) {
        guard let pathNumber = Int(localBasePath[range]) else {
          return
        }
        
        let newBasePath = "https://marumaru\(pathNumber + 1).com"
        self.localBasePath = newBasePath
      } else {
        return
      }
    } catch {
      print(error.localizedDescription)
      return
    }
  }
  
  private func fetchRemoteBasePath() -> String? {
    do {
      if let url = URL(string: Self.REMOTE_BASE_PATH) {
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
    localBasePath = basePath
    UserDefaultsManager.basePath = basePath
  }
}
