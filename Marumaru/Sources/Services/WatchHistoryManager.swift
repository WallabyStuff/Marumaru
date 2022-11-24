//
//  WatchHistoryManager.swift
//  Marumaru
//
//  Created by 이승기 on 2021/04/26.
//

import UIKit

import RxSwift
import RxCocoa
import RealmSwift

class WatchHistoryManager: CRUDable {
  
  
  // MARK: - Properties
  typealias Item = WatchHistory
  
  
  // MARK: - Methods
  
  public func addData(_ comicEpisode: ComicEpisode) -> Completable {
    return Completable.create { [weak self] observer in
      guard let self = self else { return Disposables.create() }
      
      let item = WatchHistory(comicSN: comicEpisode.comicSN,
                              episodeSN: comicEpisode.episodeSN,
                              title: comicEpisode.title,
                              thumbnailImagePath: comicEpisode.thumbnailImagePath ?? "")
      
      self.addData(item)
        .subscribe(onCompleted: {
          observer(.completed)
        }, onError: { error in
          observer(.error(error))
        }).dispose()
      
      return Disposables.create()
    }
  }
  
  public func addData(_ item: WatchHistory) -> Completable {
    return Completable.create { observer in
      do {
        let realmInstance = try Realm()
        try realmInstance.safeWrite {
          realmInstance.add(item, update: .modified)
        }
        observer(.completed)
      } catch {
        observer(.error(error))
      }
      
      return Disposables.create()
    }
  }
  
  public func fetchData() -> Single<[WatchHistory]> {
    return Single.create { observer in
      do {
        let realmInstance = try Realm()
        let watchHistories = Array(realmInstance.objects(WatchHistory.self))
        observer(.success(watchHistories))
      } catch {
        observer(.failure(error))
      }
      
      return Disposables.create()
    }
  }
  
  public func deleteData(_ item: WatchHistory) -> Completable {
    return Completable.create { observer in
      do {
        let realmInstance = try Realm()
        try realmInstance.write {
          realmInstance.delete(item)
        }
        observer(.completed)
      } catch {
        observer(.error(error))
      }
      
      return Disposables.create()
    }
  }
  
  public func deleteAll() -> Completable {
    return Completable.create { observer in
      do {
        let realmInstance = try Realm()
        let objects = realmInstance.objects(WatchHistory.self)
        try realmInstance.safeWrite {
          realmInstance.delete(objects)
        }
        observer(.completed)
      } catch {
        observer(.error(error))
      }
      
      return Disposables.create()
    }
  }
}

extension Realm {
  func safeWrite(_ block: (() throws -> Void)) throws {
    if isInWriteTransaction {
      try block()
    } else {
      try write(block)
    }
  }
}

extension Date {
  static var timeStamp: Int64 {
    Int64(Date().timeIntervalSince1970)
  }
  
  static var milliTimeStamp: Int64 {
    Int64(Date().timeIntervalSince1970 * 1000)
  }
}
