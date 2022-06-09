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
    
    public var searchKeyword = ""
    private var searchResultComics = [ComicInfo]()
    public var searchResultComicsObservable = BehaviorRelay<[ComicInfoSection]>(value: [])
    public var isLoadingSearchResultComics = PublishRelay<Bool>()
    public var failToLoadSearchResult = BehaviorRelay<Bool>(value: false)
    
    public var presentComicDetailVC = PublishRelay<ComicInfo>()
}

extension SearchResultViewModel {
    public func updateSearchResult(_ title: String) {
        searchKeyword = title
        searchResultComics = fakeSearchResultComics(15)
        
        let fakeSection = ComicInfoSection(items: searchResultComics)
        searchResultComicsObservable.accept([fakeSection])
        
        failToLoadSearchResult.accept(false)
        isLoadingSearchResultComics.accept(true)
        
        MarumaruApiService.shared
            .getSearchResult(title: title)
            .subscribe(on: ConcurrentDispatchQueueScheduler.init(qos: .background))
            .observe(on: MainScheduler.instance)
            .subscribe(with: self, onSuccess: { strongSelf, comics in
                strongSelf.searchResultComics = comics
                
                let section = ComicInfoSection(items: comics)
                strongSelf.searchResultComicsObservable.accept([section])
                strongSelf.isLoadingSearchResultComics.accept(false)
            }, onFailure: { strongSelf, _ in
                strongSelf.searchResultComicsObservable.accept([])
                strongSelf.isLoadingSearchResultComics.accept(false)
                strongSelf.failToLoadSearchResult.accept(true)
            }).disposed(by: self.disposeBag)
    }
    
    public func selectComicItem(_ indexPath: IndexPath) {
        var selectedComic = searchResultComics[indexPath.row]
        if selectedComic.author != "작가정보 없음" {
            selectedComic.author = "작가 : \(selectedComic.author)"
        }
        presentComicDetailVC.accept(selectedComic)
    }
}

extension SearchResultViewModel {
    public func getImageURL(_ imagePath: String?) -> URL? {
        guard let imagePath = imagePath else {
            return nil
        }

        return MarumaruApiService.shared.getImageURL(imagePath)
    }
}

extension SearchResultViewModel {
    private func fakeSearchResultComics(_ count: Int) -> [ComicInfo] {
        return [ComicInfo](repeating: fakeSearchResultComic, count: count)
    }
    
    private var fakeSearchResultComic: ComicInfo {
        return .init(comicSN: "", title: "")
    }
}
