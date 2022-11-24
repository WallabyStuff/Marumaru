//
//  BookmarkViewModel.swift
//  Marumaru
//
//  Created by 이승기 on 2022/06/06.
//

import Foundation

import RxSwift
import RxCocoa

class BookmarkViewModel {
  
  // MARK: - Properties
  
  private var disposeBag = DisposeBag()
  private let comicBookmarkManager = ComicBookmarkManager()
  public var bookmarks = BehaviorRelay<[ComicBookmark]>(value: [])
  public var presentComicDetailVC = PublishRelay<ComicInfo>()
}

extension BookmarkViewModel {
  public func updateBookmarks() {
    comicBookmarkManager.fetchData()
      .subscribe(with: self, onSuccess: { strongSelf, bookmarks in
        let reversedItems: [ComicBookmark] = bookmarks.reversed()
        strongSelf.bookmarks.accept(reversedItems)
      }, onFailure: { strongSelf, _ in
        strongSelf.bookmarks.accept([])
      })
      .disposed(by: disposeBag)
  }
  
  public func getImageURL(_ imagePath: String) -> URL? {
    return MarumaruApiService.shared.getImageURL(imagePath)
  }
  
  public func bookmarkItemSelected(_ indexPath: IndexPath) {
    let bookmark = bookmarks.value[indexPath.row]
    let comicInfo = ComicInfo(comicSN: bookmark.comicSN,
                              title: bookmark.title,
                              author: bookmark.author,
                              updateCycle: bookmark.updateCycle,
                              thumbnailImagePath: bookmark.thumbnailImagePath)
    presentComicDetailVC.accept(comicInfo)
  }
}
