//
//  SearchComicViewModel.swift
//  Marumaru
//
//  Created by 이승기 on 2022/02/02.
//

import UIKit
import RxSwift
import RxCocoa

enum SearchViewError: Error {
    case emptySearchResult
    
    var message: String {
        switch self {
        case .emptySearchResult:
            return "검색 결과가 없습니다."
        }
    }
}

class SearchComicViewModel: MarumaruApiServiceViewModel {
    
    private var disposeBag = DisposeBag()
    private var marumaruApiService = MarumaruApiService()
    public var reloadSearchResultTableView: (() -> Void)?
    
    private var searchResultComics: [ComicInfo] = [] {
        didSet {
            self.reloadSearchResultTableView?()
        }
    }
}

extension SearchComicViewModel {
    public func getSearchResult(_ title: String) -> Completable {
        return Completable.create { [weak self] observer in
            guard let self = self else { return Disposables.create() }
            
            self.searchResultComics.removeAll()
            
            self.marumaruApiService.getSearchResult(title: title)
                .subscribe(on: ConcurrentDispatchQueueScheduler.init(qos: .background))
                .observe(on: MainScheduler.instance)
                .subscribe(with: self, onNext: { strongSelf, comics in
                    if comics.count == 0 {
                        observer(.error(SearchViewError.emptySearchResult))
                    } else {
                        strongSelf.searchResultComics = comics
                        observer(.completed)
                    }
                }, onError: { _, error in
                    observer(.error(error))
                }).disposed(by: self.disposeBag)
            
            return Disposables.create()
        }
    }
}

extension SearchComicViewModel {
    public var numberOfSection: Int {
        return 1
    }
    
    public func numberOfRowsIn(section: Int) -> Int {
        if section == 0 {
            return searchResultComics.count
        } else {
            return 0
        }
    }
    
    public func cellItemForRow(at indexPath: IndexPath) -> ComicInfo {
        return searchResultComics[indexPath.row]
    }
}
