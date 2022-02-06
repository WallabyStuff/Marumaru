//
//  SaveToWatchHistory.swift
//  Marumaru
//
//  Created by 이승기 on 2021/04/26.
//

import UIKit

import RxSwift
import RxCocoa
import RealmSwift

class WatchHistoryManager {
    private var disposeBag = DisposeBag()
}

extension WatchHistoryManager {
    public func addData(mangaUrl: String, mangaTitle: String, thumbnailImageUrl: String) -> Completable {
        return Completable.create { [weak self] observer in
            guard let self = self else { return Disposables.create() }
            let watchHistory = WatchHistory(mangaUrl: mangaUrl, mangaTitle: mangaTitle, thumbnailImageUrl: thumbnailImageUrl)
            
            self.addData(watchHistory: watchHistory)
                .subscribe(onCompleted: {
                    observer(.completed)
                }, onError: { error in
                    observer(.error(error))
                }).disposed(by: self.disposeBag)
            
            return Disposables.create()
        }
    }
    
    func addData(watchHistory: WatchHistory) -> Completable {
        return Completable.create { observer in
            do {
                let realmInstance = try Realm()
                try realmInstance.safeWrite {
                    realmInstance.add(watchHistory, update: .modified)
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