//
//  SearchComicViewModel.swift
//  Marumaru
//
//  Created by 이승기 on 2022/02/02.
//

import Foundation

import RxSwift
import RxCocoa

class SearchComicViewModel {
  
  // MARK: - Properties
  
  private var disposeBag = DisposeBag()
  private var searchHistoryManager = SearchHistoryManager()
}

extension SearchComicViewModel {
  public func addSearchHistory(_ title: String) {
    let searchHistory = SearchHistory(title: title)
    searchHistoryManager.addData(searchHistory)
      .subscribe()
      .dispose()
  }
}
