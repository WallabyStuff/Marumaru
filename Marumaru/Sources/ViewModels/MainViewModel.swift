//
//  MainViewModel.swift
//  Marumaru
//
//  Created by 이승기 on 2022/02/02.
//

import UIKit
import RxSwift
import RxCocoa

class MainViewModel {
  
  
  // MARK: - Properteis
  
  private var disposeBag = DisposeBag()
  private let watchHistoryManager = WatchHistoryManager()
  
  public var newComicEpisodes = BehaviorRelay<[ComicEpisode]>(value: [])
  public var isLoadingNewComicEpisode = BehaviorRelay<Bool>(value: true)
  public var failToGetNewComicEpisode = BehaviorRelay<Bool>(value: false)
  public var watchHistories = BehaviorRelay<[WatchHistory]>(value: [])
  public var comicRank = BehaviorRelay<[ComicEpisode]>(value: [])
  public var isLoadingComicRank = BehaviorRelay<Bool>(value: false)
  public var failToGetComicRank = BehaviorRelay<Bool>(value: false)
  
  public var presentComicStripVC = PublishRelay<ComicEpisode>()
  public var presentComicDetailVC = PublishRelay<ComicEpisode>()
}


// MARK: - NewComicEpisode

extension MainViewModel {
  public func updateNewComicEpisodes() {
    let fakeEpisodes = ComicEpisode.fakeItems(count: 15)
    newComicEpisodes.accept(fakeEpisodes)
    isLoadingNewComicEpisode.accept(true)
    failToGetNewComicEpisode.accept(false)
    
    MarumaruApiService.shared
      .getNewComicEpisodes()
      .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .background))
      .observe(on: MainScheduler.instance)
      .subscribe(with: self, onSuccess: { strongSelf, comics in
        strongSelf.newComicEpisodes.accept(comics)
        strongSelf.isLoadingNewComicEpisode.accept(false)
      }, onFailure: { strongSelf, _ in
        strongSelf.newComicEpisodes.accept([])
        strongSelf.failToGetNewComicEpisode.accept(true)
      })
      .disposed(by: self.disposeBag)
  }
  
  public func newComicEpisodeItemSelected(_ indexPath: IndexPath) {
    let selectedItem = newComicEpisodes.value[indexPath.row]
    let comicEpisode = ComicEpisode(comicSN: selectedItem.comicSN,
                                    episodeSN: selectedItem.episodeSN,
                                    title: selectedItem.title,
                                    description: selectedItem.description,
                                    thumbnailImagePath: selectedItem.thumbnailImagePath)
    
    presentComicStripVC.accept(comicEpisode)
  }
}


// MARK: - WatchHistory

extension MainViewModel {
  public func updateWatchHistories() {
    watchHistories.accept([])
    
    self.watchHistoryManager
      .fetchData()
      .observe(on: MainScheduler.instance)
      .subscribe(onSuccess: { [weak self] comics in
        let reversedComics = Array(comics.reversed().prefix(20))
        self?.watchHistories.accept(reversedComics)
      })
      .disposed(by: self.disposeBag)
  }
  
  public func watchHistoryItemSelected(_ indexPath: IndexPath) {
    let selectedItem = watchHistories.value[indexPath.row]
    let comicEpisode = ComicEpisode(comicSN: selectedItem.comicSN,
                                    episodeSN: selectedItem.episodeSN,
                                    title: selectedItem.title,
                                    description: selectedItem.description,
                                    thumbnailImagePath: selectedItem.thumbnailImagePath)
    
    presentComicDetailVC.accept(comicEpisode)
  }
  
}


// MARK: - Comic rank

extension MainViewModel {
  public func updateComicRank() {
    let fakeEpisodes = ComicEpisode.fakeItems(count: 15)
    comicRank.accept(fakeEpisodes)
    isLoadingComicRank.accept(true)
    failToGetComicRank.accept(false)
    
    MarumaruApiService.shared
      .getComicRank()
      .subscribe(on: ConcurrentDispatchQueueScheduler.init(qos: .background))
      .observe(on: MainScheduler.instance)
      .subscribe(with: self, onSuccess: { strongSelf, comics in
        strongSelf.comicRank.accept(comics)
        strongSelf.isLoadingComicRank.accept(false)
      }, onFailure: { strongSelf, _ in
        strongSelf.comicRank.accept([])
        strongSelf.failToGetComicRank.accept(true)
      }).disposed(by: self.disposeBag)
  }
  
  public func comicRankItemSelected(_ indexPath: IndexPath) {
    let selectedItem = comicRank.value[indexPath.row]
    let comicEpisode = ComicEpisode(comicSN: selectedItem.comicSN,
                                    episodeSN: selectedItem.episodeSN,
                                    title: selectedItem.title,
                                    description: nil,
                                    thumbnailImagePath: nil)
    
    presentComicStripVC.accept(comicEpisode)
  }
}

extension MainViewModel {
  public func getImageURL(_ imageName: String?) -> URL? {
    guard let imageName = imageName else {
      return nil
    }
    
    return MarumaruApiService.shared.getImageURL(imageName)
  }
}
