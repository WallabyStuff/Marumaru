//
//  SearchHistoryViewModel.swift
//  Marumaru
//
//  Created by 이승기 on 2022/05/29.
//

import Foundation

import RxSwift
import RxCocoa

class SearchHistoryViewModel {
    
    
    // MARK: - Properties
    
    private var disposeBag = DisposeBag()
    private let searchHistoryManager = SearchHistoryManager()
    public var searchHistories = [SearchHistory]()
    public var searchHistoriesObservable = BehaviorRelay<[SearchHistorySection]>(value: [])
    public var didSelectedHistoryItem = PublishRelay<SearchHistory>()
}

extension SearchHistoryViewModel {
    public func updateSearchHistory() {
        searchHistoriesObservable.accept([])
        
        searchHistoryManager.fetchData()
            .subscribe(with: self, onSuccess: { strongSelf, histories in
                let reversedHistories: [SearchHistory] = histories.sorted(by: { $0.date > $1.date })
                strongSelf.searchHistories = reversedHistories
                
                let section = SearchHistorySection(items: reversedHistories)
                strongSelf.searchHistoriesObservable.accept([section])
            })
            .disposed(by: disposeBag)
    }
    
    public func deleteSearchHistoryItem(_ index: Int) {
        let selectedItem = searchHistories[index]
        searchHistoryManager.deleteData(selectedItem)
            .subscribe(with: self, onCompleted: { strongSelf in
                strongSelf.searchHistories.remove(at: index)
                
                let newSection = SearchHistorySection(items: strongSelf.searchHistories)
                strongSelf.searchHistoriesObservable.accept([newSection])
            })
            .disposed(by: disposeBag)
    }
    
    public func deleteAllSearchHistory() {
        searchHistoryManager.deleteAll()
            .subscribe(with: self, onCompleted: { strongSelf in
                strongSelf.updateSearchHistory()
            })
            .disposed(by: disposeBag)
    }
    
    public func selectHistoryItem(_ indexPath: IndexPath) {
        let selectedItem = searchHistories[indexPath.row]
        didSelectedHistoryItem.accept(selectedItem)
    }
}
