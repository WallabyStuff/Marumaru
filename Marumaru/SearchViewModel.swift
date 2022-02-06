//
//  SearchViewModel.swift
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

class SearchViewModel: MarumaruApiServiceViewModel {
    
    private var disposeBag = DisposeBag()
    private var marumaruApiService = MarumaruApiService()
    public var reloadSearchResultTableView: (() -> Void)?
    
    private var searchResultMangas: [MangaInfo] = [] {
        didSet {
            self.reloadSearchResultTableView?()
        }
    }
}

extension SearchViewModel {
    public func getSearchResult(_ title: String) -> Completable {
        return Completable.create { [weak self] observer in
            guard let self = self else { return Disposables.create() }
            
            self.searchResultMangas.removeAll()
            
            self.marumaruApiService.getSearchResult(title: title)
                .subscribe(on: ConcurrentDispatchQueueScheduler.init(qos: .background))
                .observe(on: MainScheduler.instance)
                .subscribe(with: self, onNext: { strongSelf, searchResultMangas in
                    if searchResultMangas.count == 0 {
                        observer(.error(SearchViewError.emptySearchResult))
                    } else {
                        strongSelf.searchResultMangas = searchResultMangas
                        observer(.completed)
                    }
                }, onError: { _, error in
                    observer(.error(error))
                }).disposed(by: self.disposeBag)
            
            return Disposables.create()
        }
    }
}

extension SearchViewModel {
    public func numberOfRowsIn(section: Int) -> Int {
        if section == 0 {
            return searchResultMangas.count
        } else {
            return 0
        }
    }
    
    public func cellItemForRow(at indexPath: IndexPath) -> MangaInfo {
        return searchResultMangas[indexPath.row]
    }
}
