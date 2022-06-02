//
//  MainViewModel.swift
//  Marumaru
//
//  Created by 이승기 on 2022/02/02.
//

import UIKit
import RxSwift
import RxCocoa

class MainViewModel: MarumaruApiServiceViewModel {
    
    
    // MARK: - Properteis
    
    private var disposeBag = DisposeBag()
    private let watchHistoryManager = WatchHistoryManager()

    private var newComicEpisodes = [ComicEpisode]()
    public var newComicEpisodesObservable = BehaviorRelay<[ComicEpisode]>(value: [])
    public var isLoadingNewComicEpisode = BehaviorRelay<Bool>(value: true)
    public var failToGetNewComicEpisode = BehaviorRelay<Bool>(value: false)
    
    private var watchHistories = [WatchHistory]()
    public var watchHistoriesObservable = PublishRelay<[WatchHistory]>()
    
    private var comicRank = [ComicEpisode]()
    public var comicRankObservable = BehaviorRelay<[ComicEpisode]>(value: [])
    public var isLoadingComicRank = BehaviorRelay<Bool>(value: false)
    public var failToGetComicRank = BehaviorRelay<Bool>(value: false)
    
    public var presentComicStripVCObservable = PublishRelay<ComicEpisode>()
}


// MARK: - NewComicEpisode

extension MainViewModel {
    public func updateNewComicEpisodes() {
        newComicEpisodes = fakeComicItems(15)
        newComicEpisodesObservable.accept(newComicEpisodes)
        isLoadingNewComicEpisode.accept(true)
        failToGetNewComicEpisode.accept(false)
        
        MarumaruApiService.shared
            .getNewComicEpisodes()
            .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .background))
            .observe(on: MainScheduler.instance)
            .subscribe(with: self, onSuccess: { strongSelf, comics in
                strongSelf.newComicEpisodes = comics
                strongSelf.newComicEpisodesObservable.accept(comics)
                strongSelf.isLoadingNewComicEpisode.accept(false)
            }, onFailure: { strongSelf, _ in
                strongSelf.newComicEpisodesObservable.accept([])
                strongSelf.failToGetNewComicEpisode.accept(true)
            })
            .disposed(by: self.disposeBag)
    }
    
    public func newComicEpisodeItemSelected(_ indexPath: IndexPath) {
        let selectedComic = newComicEpisodes[indexPath.row]
        presentComicStripVCObservable.accept(selectedComic)
    }
}


// MARK: - WatchHistory

extension MainViewModel {
    public func updateWatchHistories() {
        watchHistories.removeAll()
        watchHistoriesObservable.accept([])
        
        self.watchHistoryManager
            .fetchData()
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] comics in
                let reversedComics: [WatchHistory] = comics.reversed()
                self?.watchHistories = reversedComics
                self?.watchHistoriesObservable.accept(reversedComics)
            })
            .disposed(by: self.disposeBag)
    }
    
    public func watchHistoryItemSelected(_ indexPath: IndexPath) {
        let selectedComicEpisode = watchHistories[indexPath.row]
        let comicEpisode = ComicEpisode(comicSN: selectedComicEpisode.comicSN,
                                        episodeSN: selectedComicEpisode.episodeSN,
                                        title: selectedComicEpisode.title,
                                        description: nil,
                                        thumbnailImagePath: selectedComicEpisode.thumbnailImagePath)
        
        presentComicStripVCObservable.accept(comicEpisode)
    }
    
}


// MARK: - Comic rank

extension MainViewModel {
    public func updateComicRank() {
        comicRank = fakeComicItems(15)
        comicRankObservable.accept(comicRank)
        isLoadingComicRank.accept(true)
        failToGetComicRank.accept(false)
        
        MarumaruApiService.shared
            .getComicRank()
            .subscribe(on: ConcurrentDispatchQueueScheduler.init(qos: .background))
            .observe(on: MainScheduler.instance)
            .subscribe(with: self, onSuccess: { strongSelf, comics in
                strongSelf.comicRank = comics
                strongSelf.comicRankObservable.accept(comics)
                strongSelf.isLoadingComicRank.accept(false)
            }, onFailure: { strongSelf, _ in
                strongSelf.comicRankObservable.accept([])
                strongSelf.failToGetComicRank.accept(true)
            }).disposed(by: self.disposeBag)
    }
    
    public func comicRankItemSelected(_ indexPath: IndexPath) {
        let selectedComicEpisode = comicRank[indexPath.row]
        let comicEpisode = ComicEpisode(comicSN: selectedComicEpisode.comicSN,
                                        episodeSN: selectedComicEpisode.episodeSN,
                                        title: selectedComicEpisode.title,
                                        description: nil,
                                        thumbnailImagePath: nil)
        
        presentComicStripVCObservable.accept(comicEpisode)
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

extension MainViewModel {
    public func fakeComicItems(_ count: Int) -> [ComicEpisode] {
        return [ComicEpisode](repeating: fakeComicItem, count: count)
    }
    
    public var fakeComicItem: ComicEpisode {
        return .init(comicSN: "", title: "")
    }
}
