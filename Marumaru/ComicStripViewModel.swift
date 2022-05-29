//
//  ComicStripViewModel.swift
//  Marumaru
//
//  Created by 이승기 on 2022/02/03.
//

import Foundation

import RxSwift
import RxCocoa

class ComicStripViewModel: MarumaruApiServiceViewModel {
    private var disposeBag = DisposeBag()
    private var episodeURL: String = ""
    private var currentEpisode: Episode
    private var marumaruApiService = MarumaruApiService()
    private var watchHistoryHandler = WatchHistoryManager()
    
    public var episodeTitle = BehaviorRelay<String>(value: "")
    public var makeToast = PublishRelay<String>()
    public var comicEpisodes = [Episode]()

    private var comicStripScenes = [ComicStripScene]()
    public var comicStripScenesObservable = PublishRelay<[ComicStripScene]>()
    public var isLoadingScenes = BehaviorRelay<Bool>(value: false)
    public var failToLoadingScenes = BehaviorRelay<Bool>(value: false)
    
    init(episode: Episode, episodeURL: String) {
        self.currentEpisode = episode
        super.init()
        
        self.episodeTitle.accept(episode.title)
        self.episodeURL = episodeURL
        setupData()
    }
    
    private func setupData() {
        if currentEpisode.serialNumber == "" {
            currentEpisode.serialNumber = getSerialNumberFromUrl()
        }
        
        updateComicEpisodes()
    }
}

extension ComicStripViewModel {
    public func renderComicStripScenes(_ episode: Episode) {
        currentEpisode = episode
        episodeTitle.accept(episode.title)
        comicStripScenesObservable.accept([])
        failToLoadingScenes.accept(false)
        isLoadingScenes.accept(true)
        episodeURL = getEndPoint(with: episode.serialNumber)
        
        marumaruApiService.getComicStripScenes(episodeURL)
            .subscribe(on: ConcurrentDispatchQueueScheduler.init(qos: .background))
            .observe(on: MainScheduler.instance)
            .subscribe(with: self, onNext: { strongSelf, scenes in
                strongSelf.isLoadingScenes.accept(false)
                strongSelf.comicStripScenes = scenes
                strongSelf.comicStripScenesObservable.accept(scenes)
            }, onError: { strongSelf, _ in
                strongSelf.failToLoadingScenes.accept(true)
                strongSelf.isLoadingScenes.accept(false)
            }).disposed(by: self.disposeBag)
    }
    
    public func renderCurrentEpisodeScenes() {
        renderComicStripScenes(currentEpisode)
    }
    
    public func renderNextEpisodeScenes() {
        guard let currentEpisodeIndex = currentEpisodeIndex else {
            return
        }
        
        let targetIndex = currentEpisodeIndex + 1
        if comicEpisodes.isInBound(targetIndex) {
            let nextEpisode = comicEpisodes[targetIndex]
            renderComicStripScenes(nextEpisode)
        } else {
            makeToast.accept("message.lastEpisode".localized())
        }
    }
    
    public func renderPreviousEpisodeScenes() {
        guard let currentEpisodeIndex = currentEpisodeIndex else {
            return
        }

        let targetIndex = currentEpisodeIndex - 1
        if comicEpisodes.isInBound(targetIndex) {
            let previousEpisode = comicEpisodes[targetIndex]
            renderComicStripScenes(previousEpisode)
        } else {
            makeToast.accept("message.firstEpisode".localized())
        }
    }
    
    public var currentEpisodeIndex: Int? {
        for (i, episode) in comicEpisodes.enumerated()
        where episode.serialNumber == currentEpisode.serialNumber {
            return i
        }
        
        return nil
    }
}

extension ComicStripViewModel {
    private var firstSceneImageUrl: String? {
        return comicStripScenes.first?.sceneImageUrl
    }
    
    public func saveToWatchHistory() {
        let currentEpisode = WatchHistory(episodeTitle: currentEpisode.title,
                                          episodeURL: episodeURL,
                                          thumbnailImageUrl: firstSceneImageUrl ?? "")
        watchHistoryHandler
            .addData(watchHistory: currentEpisode)
            .subscribe()
            .disposed(by: disposeBag)
    }
}

extension ComicStripViewModel {
    private func updateComicEpisodes() {
        marumaruApiService.getEpisodesInStrip(episodeURL)
            .subscribe(on: ConcurrentDispatchQueueScheduler.init(qos: .background))
            .observe(on: MainScheduler.instance)
            .subscribe(with: self, onSuccess: { strongSelf, episodes in
                strongSelf.comicEpisodes = episodes.reversed()
            }).disposed(by: self.disposeBag)
    }
}


// TODO: - Move to MarumaruAPIService

extension ComicStripViewModel {
    private func getEndPoint(with newSerialNumber: String) -> String {
        if let serialNumberStartIndex = episodeURL.lastIndex(of: "/") {
            let serialNumberRange = episodeURL.index(serialNumberStartIndex, offsetBy: 1)..<episodeURL.endIndex
            
            episodeURL.replaceSubrange(serialNumberRange, with: newSerialNumber)
            currentEpisode.serialNumber = newSerialNumber
        }
        
        return episodeURL
    }
    
    public func getSerialNumberFromUrl() -> String {
        if let serialNumberStartIndex = episodeURL.lastIndex(of: "/") {
            let serialNumberRange = episodeURL.index(serialNumberStartIndex, offsetBy: 1)..<episodeURL.endIndex
            return episodeURL[serialNumberRange].description
        }
        
        return ""
    }
}
