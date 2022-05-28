//
//  SearchComicViewModel.swift
//  Marumaru
//
//  Created by 이승기 on 2022/02/02.
//

import UIKit
import RxSwift
import RxCocoa

class SearchComicViewModel: MarumaruApiServiceViewModel {
    
    
    // MARK: - Properties
    
    private var disposeBag = DisposeBag()
    private var marumaruApiService = MarumaruApiService()
    
    private var searchResultComics = [ComicInfo]()
    public var searchResultComicsObservable = PublishRelay<[ComicInfo]>()
    public var isLoadingSearchResultComics = PublishRelay<Bool>()
    public var failToLoadSearchResult = BehaviorRelay<Bool>(value: false)
    
    public var presentComicDetailVC = PublishRelay<ComicInfo>()
}

extension SearchComicViewModel {
    public func updateSearchResult(_ title: String) {
        searchResultComicsObservable.accept([])
        failToLoadSearchResult.accept(false)
        isLoadingSearchResultComics.accept(true)
        
        self.marumaruApiService.getSearchResult(title: title)
            .subscribe(on: ConcurrentDispatchQueueScheduler.init(qos: .background))
            .observe(on: MainScheduler.instance)
            .subscribe(with: self, onNext: { strongSelf, comics in
                strongSelf.searchResultComics = comics
                strongSelf.searchResultComicsObservable.accept(comics)
                strongSelf.isLoadingSearchResultComics.accept(false)
            }, onError: { strongSelf, _ in
                strongSelf.isLoadingSearchResultComics.accept(false)
                strongSelf.failToLoadSearchResult.accept(true)
            }).disposed(by: self.disposeBag)
    }
    
    public func comicItemSelected(_ indexPath: IndexPath) {
        let selectedComic = searchResultComics[indexPath.row]
        presentComicDetailVC.accept(selectedComic)
    }
}
