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
  public var searchHistories = BehaviorRelay<[SearchHistorySection]>(value: [])
  public var didSelectedHistoryItem = PublishRelay<SearchHistory>()
}

extension SearchHistoryViewModel {
  public func updateSearchHistory() {
    searchHistories.accept([])
    
    searchHistoryManager.fetchData()
      .subscribe(with: self, onSuccess: { strongSelf, histories in
        let reversedHistories: [SearchHistory] = histories.sorted(by: { $0.date > $1.date })
        let section = SearchHistorySection(items: reversedHistories)
        strongSelf.searchHistories.accept([section])
      })
      .disposed(by: disposeBag)
  }
  
  public func deleteSearchHistoryItem(_ indexPath: IndexPath) {
    let selectedItem = searchHistories.value[indexPath.section].items[indexPath.row]
    searchHistoryManager.deleteData(selectedItem)
      .subscribe(with: self, onCompleted: { strongSelf in
        var newSections = strongSelf.searchHistories.value
        newSections[indexPath.section].items.remove(at: indexPath.row)
        strongSelf.searchHistories.accept(newSections)
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
    let selectedItem = searchHistories.value[indexPath.section].items[indexPath.row]
    didSelectedHistoryItem.accept(selectedItem)
  }
}

extension SearchHistoryViewModel {
  public var isHistoryEmpty: Bool {
    return searchHistories.value.first?.items.isEmpty ?? true
  }
}
