//
//  SearchHistoryManager.swift
//  Marumaru
//
//  Created by 이승기 on 2022/05/29.
//

import Foundation

import RealmSwift
import RxSwift

class SearchHistoryManager: CRUDable {
    
    
    // MARK: - Properties
    
    typealias Item = SearchHistory
    
    
    // MARK: - Methods
    
    func addData(_ item: SearchHistory) -> Completable {
        return Completable.create { observer  in
            do {
                let realmInstance = try Realm()
                try realmInstance.write {
                    realmInstance.add(item, update: .modified)
                }
                
                observer(.completed)
            } catch {
                observer(.error(error))
            }
            
            return Disposables.create()
        }
    }
    
    func fetchData() -> Single<[SearchHistory]> {
        return Single.create { observer in
            do {
                let realmInstance = try Realm()
                let searchHistories = Array(realmInstance.objects(SearchHistory.self))
                observer(.success(searchHistories))
            } catch {
                observer(.failure(error))
            }
            
            return Disposables.create()
        }
    }
    
    func deleteData(_ item: SearchHistory) -> Completable {
        return Completable.create { observer  in
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
        return Completable.create { observer  in
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
