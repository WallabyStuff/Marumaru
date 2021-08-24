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

class WatchHistoryHandler {
    
    var disposeBag = DisposeBag()
    
    func addData(mangaUrl: String,
                 mangaTitle: String,
                 thumbnailImageUrl: String) -> Observable<Bool> {
        
        return Observable.create { observable in
            do {
                let realmInstance = try Realm()
                let watchHistory = WatchHistory(mangaUrl: mangaUrl,
                                                     mangaTitle: mangaTitle,
                                                     thumbnailImageUrl: thumbnailImageUrl)
                try realmInstance.write {
                    realmInstance.add(watchHistory, update: .modified)
                    observable.onNext(true)
                    observable.onCompleted()
                    return
                }
                return Disposables.create()
            } catch {
                observable.onError(error)
                return Disposables.create()
            }
        }
    }
    
    func addData(watchHistory: WatchHistory) -> Observable<Bool> {
        
        return Observable.create { observable in
            self.isExists(url: watchHistory.mangaUrl)
                .subscribe(onNext: { isExists in
                    if !isExists {
                        do {
                            let realmInstance = try Realm()
                            
                            try realmInstance.write {
                                realmInstance.add(watchHistory)
                                observable.onNext(true)
                                return
                            }
                            return
                        } catch {
                            observable.onError(error)
                            return
                        }
                    }
                }).disposed(by: self.disposeBag)
            return Disposables.create()
        }
    }
    
    func fetchData() -> Observable<[WatchHistory]> {
        
        return Observable.create { observable in
            do {
                let realmInstance = try Realm()
                var watchHistories = Array(realmInstance.objects(WatchHistory.self))
                watchHistories.sort { $0.timeStamp > $1.timeStamp }
                
                observable.onNext(watchHistories)
                observable.onCompleted()
                return Disposables.create()
            } catch {
                observable.onError(error)
                return Disposables.create()
            }
        }
    }
    
    func deleteAll() -> Observable<Bool> {
        
        return Observable.create { observable in
            do {
                let realmInstance = try Realm()
                
                let objects = realmInstance.objects(WatchHistory.self)
                try realmInstance.write {
                    realmInstance.delete(objects)
                    observable.onNext(true)
                    observable.onCompleted()
                }
                return Disposables.create()
            } catch {
                observable.onError(error)
                return Disposables.create()
            }
        }
    }
    
    func isExists(url: String) -> Observable<Bool> {
        
        return Observable.create { observable in
            
            var isExsits = false
            
            self.fetchData()
                .subscribe(onNext: { watchHistories in
                    watchHistories.forEach { watchHistory in
                        if watchHistory.mangaUrl == url {
                            isExsits = true
                        }
                    }
                    observable.onNext(isExsits)
                    return
                }).disposed(by: self.disposeBag)
            
            return Disposables.create()
        }
    }
}
