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
  public var searchResultComics = BehaviorRelay<[ComicInfoSection]>(value: [])
  public var isLoadingSearchResultComics = PublishRelay<Bool>()
  public var failToLoadSearchResult = BehaviorRelay<Bool>(value: false)
  public var presentComicDetailVC = PublishRelay<ComicInfo>()
}

extension SearchResultViewModel {
  public func updateSearchResult(_ title: String) {
    searchKeyword = title
    let fakeItems = ComicInfo.fakeItems(count: 15)
    let fakeSection = ComicInfoSection(identity: UUID().uuidString, items: fakeItems)
    searchResultComics.accept([fakeSection])
    
    failToLoadSearchResult.accept(false)
    isLoadingSearchResultComics.accept(true)
    
    MarumaruApiService.shared
      .getSearchResult(title: title)
      .subscribe(on: ConcurrentDispatchQueueScheduler.init(qos: .background))
      .observe(on: MainScheduler.instance)
      .subscribe(with: self, onSuccess: { strongSelf, comics in
        let section = ComicInfoSection(identity: UUID().uuidString, items: comics)
        strongSelf.searchResultComics.accept([section])
        strongSelf.isLoadingSearchResultComics.accept(false)
      }, onFailure: { strongSelf, _ in
        strongSelf.searchResultComics.accept([])
        strongSelf.isLoadingSearchResultComics.accept(false)
        strongSelf.failToLoadSearchResult.accept(true)
      }).disposed(by: self.disposeBag)
  }
  
  public func selectComicItem(_ indexPath: IndexPath) {
    var selectedComic = searchResultComics.value[indexPath.section].items[indexPath.row]
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
