//
//  SearchResultViewModel.swift
//  Marumaru
//
//  Created by 이승기 on 2022/05/29.
//

import Foundation

import RxSwift
import RxCocoa

class SearchResultViewModel {
    
    
    // MARK: - Properties
    
    private var disposeBag = DisposeBag()
    private var marumaruApiService = MarumaruApiService()
    
    public var searchKeyword = ""
    private var searchResultComics = [ComicInfo]()
    public var searchResultComicsObservable = BehaviorRelay<[SearchResultSection]>(value: [])
    public var isLoadingSearchResultComics = PublishRelay<Bool>()
    public var failToLoadSearchResult = BehaviorRelay<Bool>(value: false)
    
    public var presentComicDetailVC = PublishRelay<ComicInfo>()
}

extension SearchResultViewModel {
    public func updateSearchResult(_ title: String) {
        searchKeyword = title
        searchResultComics = fakeSearchResultComics(10)
        
        let fakeSection = SearchResultSection(items: searchResultComics)
        searchResultComicsObservable.accept([fakeSection])
        
        failToLoadSearchResult.accept(false)
        isLoadingSearchResultComics.accept(true)
        
        self.marumaruApiService.getSearchResult(title: title)
            .subscribe(on: ConcurrentDispatchQueueScheduler.init(qos: .background))
            .observe(on: MainScheduler.instance)
            .subscribe(with: self, onNext: { strongSelf, comics in
                strongSelf.searchResultComics = comics
                
                let section = SearchResultSection(items: comics)
                strongSelf.searchResultComicsObservable.accept([section])
                strongSelf.isLoadingSearchResultComics.accept(false)
            }, onError: { strongSelf, _ in
                strongSelf.isLoadingSearchResultComics.accept(false)
                strongSelf.failToLoadSearchResult.accept(true)
            }).disposed(by: self.disposeBag)
    }
    
    public func selectComicItem(_ indexPath: IndexPath) {
        let selectedComic = searchResultComics[indexPath.row]
        presentComicDetailVC.accept(selectedComic)
    }
}

extension SearchResultViewModel {
    private func fakeSearchResultComics(_ count: Int) -> [ComicInfo] {
        return [ComicInfo](repeating: fakeSearchResultComic, count: count)
    }
    
    private var fakeSearchResultComic: ComicInfo {
        return .init(title: "", author: "", updateCycle: "미분류", serialNumber: "")
    }
}
