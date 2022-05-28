//
//  ComicDetailViewModel.swift
//  Marumaru
//
//  Created by 이승기 on 2022/02/03.
//

import UIKit
import RxSwift
import RxCocoa

class ComicDetailViewModel: MarumaruApiServiceViewModel {
    
    public var comicInfo: ComicInfo
    
    private var disposeBag = DisposeBag()
    private let marumaruApiService = MarumaruApiService()
    private let watchHistoryHandler = WatchHistoryManager()
    
    private var comicEpisodes = [ComicEpisode]()
    public var comicEpisodesObservable = PublishRelay<[ComicEpisode]>()
    public var isLoadingComicEpisodes = BehaviorRelay<Bool>(value: false)
    public var failedToLoadingComicEpisodes = BehaviorRelay<Bool>(value: false)
    
    private var watchHistories = [String: String]()
    public var watchHistoriesObservable = PublishRelay<[WatchHistory]>()
    
    public var presentComicStripVCObservable = PublishRelay<ComicEpisode>()
    
    init(comicInfo: ComicInfo) {
        self.comicInfo = comicInfo
    }
    
    override convenience init() {
        fatalError("ComicInfo has not been implemented")
    }
}

extension ComicDetailViewModel {
    public func updateComicEpisodes() {
        comicEpisodesObservable.accept([])
        isLoadingComicEpisodes.accept(true)
        failedToLoadingComicEpisodes.accept(false)
        
        self.marumaruApiService.getEpisodes(comicInfo.serialNumber)
            .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .background))
            .observe(on: MainScheduler.instance)
            .subscribe(with: self, onNext: { strongSelf, comics in
                strongSelf.comicEpisodes = comics
                strongSelf.isLoadingComicEpisodes.accept(false)
                strongSelf.comicEpisodesObservable.accept(comics)
            }, onError: { strongSelf, _ in
                strongSelf.isLoadingComicEpisodes.accept(false)
                strongSelf.failedToLoadingComicEpisodes.accept(true)
            }).disposed(by: self.disposeBag)
    }
    
    public func comicItemSelected(_ indexPath: IndexPath) {
        let selectedComic = comicEpisodes[indexPath.row]
        presentComicStripVCObservable.accept(selectedComic)
    }
}

extension ComicDetailViewModel {
    public func getWatchHistories() {
        watchHistoriesObservable.accept([])
        
        watchHistoryHandler.fetchData()
            .subscribe(with: self, onSuccess: { strongSelf, comics in
                strongSelf.watchHistories =  Dictionary(uniqueKeysWithValues: comics.map { ($0.episodeURL, $0.episodeURL) })
            }, onFailure: { strongSelf, _ in
                strongSelf.watchHistoriesObservable.accept([])
            }).disposed(by: self.disposeBag)
    }
    
    public func ifAlreadyWatched(_ index: Int) -> Bool {
        return watchHistories[comicEpisodes[index].episodeURL] == nil ? false : true
    }
    
    public func comicEpisodeIndex(_ index: Int) -> Int {
        return comicEpisodes.count - index
    }
    
    public var comicEpisodeAmount: Int {
        return comicEpisodes.count
    }
}
