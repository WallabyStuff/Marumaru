//
//  ComicBookmarkManager.swift
//  Marumaru
//
//  Created by 이승기 on 2022/06/06.
//

import Foundation

import RealmSwift
import RxSwift

enum ComicBookmarkError: Error {
    case itemDoesNotExists
}

class ComicBookmarkManager: CRUDable {

    
    // MARK: - Properties
    
    typealias Item = ComicBookmark
    
    
    // MARK: - Methods
    
    func addData(_ item: ComicBookmark) -> Completable {
        return Completable.create { observer in
            do {
                let realmInstance = try Realm()
                try realmInstance.write {
                    realmInstance.add(item)
                }
                observer(.completed)
            } catch {
                observer(.error(error))
            }
            
            return Disposables.create()
        }
    }
    
    func fetchData(_ comicSN: String) -> Single<ComicBookmark> {
        return Single.create { observer in
            do {
                let realmInstance = try Realm()
                let items = Array(realmInstance.objects(ComicBookmark.self))
                
                for item in items where item.comicSN == comicSN {
                    observer(.success(item))
                }
                
                observer(.failure(ComicBookmarkError.itemDoesNotExists))
            } catch {
                observer(.failure(error))
            }
            
            return Disposables.create()
        }
    }
    
    func fetchData() -> Single<[ComicBookmark]> {
        return Single.create { observer in
            do {
                let realmInstance = try Realm()
                let items = Array(realmInstance.objects(ComicBookmark.self))
                observer(.success(items))
            } catch {
                observer(.failure(error))
            }
            
            return Disposables.create()
        }
    }
    
    func deleteData(_ item: ComicBookmark) -> Completable {
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
    
    func deleteAll() -> Completable {
        return Completable.create { observer in
            do {
                let realmInstance = try Realm()
                try realmInstance.write {
                    realmInstance.deleteAll()
                }
                observer(.completed)
            } catch {
                observer(.error(error))
            }
            
            return Disposables.create()
        }
    }
}
