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
    private let serachHistoryManager = SearchHistoryManager()
    private var searchHistories = [SearchHistory]()
    public var searchHistoriesObservable = BehaviorRelay<[SearchHistory]>(value: [])
    public var didSelectedHistoryItem = PublishRelay<SearchHistory>()
}

extension SearchHistoryViewModel {
    public func updateSearchHistory() {
        searchHistoriesObservable.accept([])
        
        serachHistoryManager.fetchData()
            .subscribe(with: self, onSuccess: { strongSelf, histories in
                let reversedHistories: [SearchHistory] = histories.sorted(by: { $0.date > $1.date })
                strongSelf.searchHistories = reversedHistories
                strongSelf.searchHistoriesObservable.accept(reversedHistories)
            })
            .disposed(by: disposeBag)
    }
    
    public func deleteSearchHistoryItem(_ index: Int) {
        let selectedItem = searchHistories[index]
        serachHistoryManager.deleteData(selectedItem)
            .subscribe(with: self, onCompleted: { strongSelf in
                strongSelf.searchHistories.remove(at: index)
                strongSelf.searchHistoriesObservable.accept(strongSelf.searchHistories)
            })
            .disposed(by: disposeBag)
    }
    
    public func selectHistoryItem(_ indexPath: IndexPath) {
        let selectedItem = searchHistories[indexPath.row]
        didSelectedHistoryItem.accept(selectedItem)
    }
}
