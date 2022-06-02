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
    
    public var comicInfo: ComicInfo
    
    private var disposeBag = DisposeBag()
    private let watchHistoryHandler = WatchHistoryManager()
    
    private var comicEpisodes = [ComicEpisode]()
    public var comicEpisodesObservable = BehaviorRelay<[ComicEpisode]>(value: [])
    public var isLoadingComicEpisodes = BehaviorRelay<Bool>(value: false)
    public var failedToLoadingComicEpisodes = BehaviorRelay<Bool>(value: false)
    
    private var watchHistories = [String: String]()
    public var watchHistoriesObservable = PublishRelay<[WatchHistory]>()
    
    public var presentComicStripVCObservable = PublishRelay<ComicEpisode>()
    
    public var recentWatchingEpisodeSN: String?
    public var recentWatchingEpisodeUpdated = PublishRelay<IndexPath>()
    
    init(comicInfo: ComicInfo) {
        self.comicInfo = comicInfo
    }
    
    convenience init() {
        fatalError("ComicInfo has not been implemented")
    }
}

extension ComicDetailViewModel {
    public func updateComicEpisodes() {
        comicEpisodes = fakeEpisodeCells(15)
        comicEpisodesObservable.accept(comicEpisodes)
        isLoadingComicEpisodes.accept(true)
        failedToLoadingComicEpisodes.accept(false)
        
        MarumaruApiService.shared.getEpisodes(comicInfo.comicSN)
            .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .background))
            .observe(on: MainScheduler.instance)
            .subscribe(with: self, onSuccess: { strongSelf, comics in
                strongSelf.comicEpisodes = comics
                strongSelf.isLoadingComicEpisodes.accept(false)
                strongSelf.comicEpisodesObservable.accept(comics)
            }, onFailure: { strongSelf, _ in
                strongSelf.comicEpisodesObservable.accept([])
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
    public func updateWatchHistories() {
        watchHistories.removeAll()
        watchHistoriesObservable.accept([])
        
        watchHistoryHandler.fetchData()
            .subscribe(with: self, onSuccess: { strongSelf, comics in
                strongSelf.watchHistories =  Dictionary(uniqueKeysWithValues: comics.map { ($0.episodeSN, $0.episodeSN) })
            }, onFailure: { strongSelf, _ in
                strongSelf.watchHistoriesObservable.accept([])
            }).disposed(by: self.disposeBag)
    }
    
    public func ifAlreadyWatched(_ index: Int) -> Bool {
        return watchHistories[comicEpisodes[index].episodeSN] == nil ? false : true
    }
    
    public func comicEpisodeIndex(_ index: Int) -> Int {
        return comicEpisodes.count - index
    }
    
    public var comicEpisodeAmount: Int {
        return comicEpisodes.count
    }
}

extension ComicDetailViewModel {
    public func getThumbnailImageURL() -> URL? {
        return getImageURL(comicInfo.thumbnailImagePath)
    }
    
    public func getImageURL(_ imagePath: String?) -> URL? {
        guard let imagePath = imagePath else {
            return nil
        }
        
        return MarumaruApiService.shared.getImageURL(imagePath)
    }
}

extension ComicDetailViewModel {
    private func fakeEpisodeCells(_ count: Int) -> [ComicEpisode] {
        return [ComicEpisode](repeating: fakeEpisodeCell, count: count)
    }
    
    private var fakeEpisodeCell: ComicEpisode {
        return .init(comicSN: "", title: "")
    }
}

extension ComicDetailViewModel {
    public func updateRecentWatchingEpisode(_ episodeSN: String) {
        recentWatchingEpisodeSN = episodeSN
        
        if let index = comicEpisodes.firstIndex(where: { $0.episodeSN == episodeSN }) {
            let indexPath = IndexPath(row: index, section: 0)
            recentWatchingEpisodeUpdated.accept(indexPath)
        }
    }
}
