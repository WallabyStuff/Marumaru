//
//  ComicDetailViewModel.swift
//  Marumaru
//
//  Created by 이승기 on 2022/02/03.
//

import UIKit
import RxSwift
import RxCocoa

class ComicDetailViewModel {
  
  
  // MARK: - Properties
  
  private var disposeBag = DisposeBag()
  private let watchHistoryManager = WatchHistoryManager()
  private let comicBookmarkManager = ComicBookmarkManager()
  
  public var comicInfo = BehaviorRelay<ComicInfo>(value: .init(comicSN: "", title: ""))
  public var comicEpisodes = BehaviorRelay<[ComicEpisode]>(value: [])
  public var isLoadingComicEpisodes = BehaviorRelay<Bool>(value: false)
  public var failedToLoadingComicEpisodes = BehaviorRelay<Bool>(value: false)
  
  private var watchHistoryDictionary = [String: String]()
  public var watchHistories = PublishRelay<[WatchHistory]>()
  
  public var presentComicStripVC = PublishRelay<ComicEpisode>()
  
  public var recentWatchingEpisodeSN: String?
  public var recentWatchingEpisodeUpdated = PublishRelay<IndexPath>()
  
  public var bookmarkState = BehaviorRelay<Bool>(value: false)
  
  
  // MARK: - Initializers
  
  init(comicInfo: ComicInfo) {
    self.comicInfo.accept(comicInfo)
  }
  
  convenience init() {
    fatalError("ComicInfo has not been implemented")
  }
}

extension ComicDetailViewModel {
  public func updateComicInfoAndEpisodes() {
    let fakeItems = ComicEpisode.fakeItems(count: 15)
    comicEpisodes.accept(fakeItems)
    isLoadingComicEpisodes.accept(true)
    failedToLoadingComicEpisodes.accept(false)
    
    MarumaruApiService.shared.getEpisodes(comicInfo.value.comicSN)
      .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .background))
      .observe(on: MainScheduler.instance)
      .subscribe(with: self, onSuccess: { strongSelf, result in
        let comicInfo = strongSelf.replaceComicInfoProperties(result.comicInfo)
        strongSelf.comicInfo.accept(comicInfo)
        strongSelf.comicEpisodes.accept(result.episodes)
        strongSelf.isLoadingComicEpisodes.accept(false)
      }, onFailure: { strongSelf, _ in
        strongSelf.comicEpisodes.accept([])
        strongSelf.failedToLoadingComicEpisodes.accept(true)
        strongSelf.isLoadingComicEpisodes.accept(false)
      }).disposed(by: self.disposeBag)
  }
  
  public func comicItemSelected(_ indexPath: IndexPath) {
    let selectedComic = comicEpisodes.value[indexPath.row]
    presentComicStripVC.accept(selectedComic)
  }
}

extension ComicDetailViewModel {
  public func setInitailComicInfo() {
    comicInfo.accept(comicInfo.value)
  }
  
  // To leave out updating update cycle
  // ComicInfo from getEpisodes() can't parse updateCycle data
  private func replaceComicInfoProperties(_ newComicInfo: ComicInfo) -> ComicInfo {
    var comicInfo = self.comicInfo.value
    comicInfo.title = newComicInfo.title
    comicInfo.author = newComicInfo.author
    comicInfo.thumbnailImagePath = newComicInfo.thumbnailImagePath
    
    return comicInfo
  }
}

extension ComicDetailViewModel {
  public func updateWatchHistories() {
    watchHistoryDictionary.removeAll()
    watchHistories.accept([])
    
    watchHistoryManager.fetchData()
      .subscribe(with: self, onSuccess: { strongSelf, comics in
        strongSelf.watchHistoryDictionary =  Dictionary(uniqueKeysWithValues: comics.map { ($0.episodeSN, $0.episodeSN) })
      }, onFailure: { strongSelf, _ in
        strongSelf.watchHistories.accept([])
      }).disposed(by: self.disposeBag)
  }
  
  public func ifAlreadyWatched(_ index: Int) -> Bool {
    let comic = comicEpisodes.value[index]
    return watchHistoryDictionary[comic.episodeSN] == nil ? false : true
  }
  
  public func comicEpisodeIndex(_ index: Int) -> Int {
    return comicEpisodes.value.count - index
  }
  
  public var comicEpisodeAmount: Int {
    return comicEpisodes.value.count
  }
}

extension ComicDetailViewModel {
  public func getImageURL(_ imagePath: String?) -> URL? {
    guard let imagePath = imagePath else {
      return nil
    }
    
    return MarumaruApiService.shared.getImageURL(imagePath)
  }
}

extension ComicDetailViewModel {
  public func updateRecentWatchingEpisode(_ episodeSN: String) {
    recentWatchingEpisodeSN = episodeSN
    
    if let index = comicEpisodes.value.firstIndex(where: { $0.episodeSN == episodeSN }) {
      let indexPath = IndexPath(row: index, section: 0)
      recentWatchingEpisodeUpdated.accept(indexPath)
    }
  }
}

extension ComicDetailViewModel {
  public func tapBookmarkButton() {
    toggleBookmarkState()
  }
  
  private func toggleBookmarkState() {
    if comicInfo.value.title.isEmpty {
      // Block bookmark while
      return
    }
    
    comicBookmarkManager
      .fetchData(comicInfo.value.comicSN)
      .subscribe(with: self, onSuccess: { strongSelf, item in
        strongSelf.deleteBookmark(item)
      }, onFailure: { strongSelf, _ in
        strongSelf.addBookmark()
      })
      .disposed(by: disposeBag)
  }
  
  public func setBookmarkState() {
    comicBookmarkManager
      .fetchData(comicInfo.value.comicSN)
      .subscribe(with: self, onSuccess: { strongSelf, _ in
        strongSelf.bookmarkState.accept(true)
      }, onFailure: { strongSelf, _ in
        strongSelf.bookmarkState.accept(false)
      })
      .disposed(by: disposeBag)
  }
  
  public func addBookmark() {
    let comicInfo = comicInfo.value
    let item = ComicBookmark(comicSN: comicInfo.comicSN,
                             title: comicInfo.title,
                             author: comicInfo.author,
                             updateCycle: comicInfo.updateCycle,
                             thumbnailImagePath: comicInfo.thumbnailImagePath ?? "")
    comicBookmarkManager.addData(item)
      .subscribe(with: self, onCompleted: { strongSelf in
        strongSelf.bookmarkState.accept(true)
      })
      .dispose()
  }
  
  public func deleteBookmark(_ item: ComicBookmark) {
    comicBookmarkManager.deleteData(item)
      .subscribe(with: self, onCompleted: { strongSelf in
        strongSelf.bookmarkState.accept(false)
      })
      .dispose()
  }
}

extension ComicDetailViewModel {
  public var firstEpisode: ComicEpisode? {
    return comicEpisodes.value.last
  }
  
  public func playFirstComic() {
    if let firstEpisode = firstEpisode {
      if !firstEpisode.comicSN.isEmpty {
        presentComicStripVC.accept(firstEpisode)
      }
    }
  }
}
