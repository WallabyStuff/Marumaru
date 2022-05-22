//
//  ComicStripViewModel.swift
//  Marumaru
//
//  Created by 이승기 on 2022/02/03.
//

import UIKit
import RxSwift
import RxCocoa

enum ComicStripViewError: Error {
    case endOfEpisode
    case firstEpisode
    
    var message: String {
        switch self {
        case .endOfEpisode:
            return "마지막 화 입니다."
        case .firstEpisode:
            return "첫 화 입니다."
        }
    }
}

class ComicStripViewModel: MarumaruApiServiceViewModel {
    private var disposeBag = DisposeBag()
    private var comicURL: String = ""
    private var currentComicSN: String = ""
    private var marumaruApiService = MarumaruApiService()
    private var watchHistoryHandler = WatchHistoryManager()
    
    public var updateComicTitleLabel: (() -> Void)?
    public var reloadSceneScrollView: (() -> Void)?
    public var prepareForReloadSceneScrollview: (() -> Void)?
    public var reloadEpisodeTableView: (() -> Void)?
    
    private var comicTitle: String = "" {
        didSet {
            self.updateComicTitleLabel?()
        }
    }
    
    private var comicStripScenes = [ComicStripScene]() {
        didSet {
            self.reloadSceneScrollView?()
        }
    }
    
    private var comicEpisodes = [Episode]() {
        didSet {
            self.reloadEpisodeTableView?()
        }
    }
    
    init(comicTitle: String, comicURL: String) {
        super.init()
        self.comicTitle = comicTitle
        self.comicURL = comicURL
        
        setupData()
    }
    
    private func setupData() {
        currentComicSN = getSerialNumberFromUrl()
    }
}

extension ComicStripViewModel {
    public func renderComicStripScene(_ serialNumber: String) -> Completable {
        return Completable.create { [weak self] observer in
            guard let self = self else { return Disposables.create() }
            
            self.currentComicSN = serialNumber
            self.comicTitle = ""
            self.comicStripScenes.removeAll()
            self.prepareForReloadSceneScrollview?()
            
            let endPoint = self.getEndPoint(with: serialNumber)
            self.marumaruApiService.getComicStripScenes(endPoint)
                .subscribe(on: ConcurrentDispatchQueueScheduler.init(qos: .background))
                .observe(on: MainScheduler.instance)
                .subscribe(with: self, onNext: { strongSelf, scenes in
                    strongSelf.getComicEpisodes()
                        .subscribe(onCompleted: { [weak self] in
                            self?.comicStripScenes = scenes
                            self?.updateComicTitle()
                            self?.saveToWatchHistory()
                            observer(.completed)
                        }).disposed(by: self.disposeBag)
                }).disposed(by: self.disposeBag)
            return Disposables.create()
        }
    }
    
    public func renderCurrentEpisodeScene() -> Completable {
        return Completable.create { [weak self] observer in
            guard let self = self else { return Disposables.create() }
         
            self.renderComicStripScene(self.currentComicSN)
                .subscribe(onCompleted: {
                    observer(.completed)
                }, onError: { error in
                    observer(.error(error))
                }).disposed(by: self.disposeBag)
            return Disposables.create()
        }
    }
    
    public func renderNextEpisodeScene() -> Completable {
        return Completable.create { [weak self] observer in
            guard let self = self else { return Disposables.create() }
            
            if let index = self.currentEpisodeIndex {
                if index + 1 < self.comicEpisodes.count {
                    let nextEpisodeIndex = self.comicEpisodes.index(index, offsetBy: +1)
                    let nextEpisodeSN = self.comicEpisodes[nextEpisodeIndex].serialNumber
                    
                    self.renderComicStripScene(nextEpisodeSN)
                        .subscribe(onCompleted: {
                            observer(.completed)
                        }, onError: { error in
                            observer(.error(error))
                        }).disposed(by: self.disposeBag)
                } else {
                    observer(.error(ComicStripViewError.endOfEpisode))
                }
            } else {
                observer(.error(ComicStripViewError.endOfEpisode))
            }
            
            return Disposables.create()
        }
    }
    
    public func renderPreviousEpisodeScene() -> Completable {
        return Completable.create { [weak self] observer in
            guard let self = self else { return Disposables.create() }
            
            if let index = self.currentEpisodeIndex {
                if index - 1 >= 0 {
                    let prevEpisodeIndex = self.comicEpisodes.index(index, offsetBy: -1)
                    let prevEpisodeSN = self.comicEpisodes[prevEpisodeIndex].serialNumber
                    
                    self.renderComicStripScene(prevEpisodeSN)
                        .subscribe(onCompleted: {
                            observer(.completed)
                        }, onError: { error in
                            observer(.error(error))
                        }).disposed(by: self.disposeBag)
                } else {
                    observer(.error(ComicStripViewError.firstEpisode))
                }
            } else {
                observer(.error(ComicStripViewError.firstEpisode))
            }
            
            return Disposables.create()
        }
    }
    
    public func updateComicTitle() {
        for episode in comicEpisodes where episode.serialNumber == currentComicSN {
            return comicTitle = episode.title
        }
    }
}

extension ComicStripViewModel {
    public var firstSceneImageUrl: String? {
        return comicStripScenes.first?.sceneImageUrl
    }
    
    public func saveToWatchHistory() {
        let currentComic = WatchHistory(comicURL: comicURL,
                                        comicTitle: comicTitle,
                                        thumbnailImageUrl: firstSceneImageUrl ?? "")
        
        watchHistoryHandler.addData(watchHistory: currentComic)
            .subscribe().disposed(by: disposeBag)
    }
}

extension ComicStripViewModel {
    private func getComicEpisodes() -> Completable {
        return Completable.create { [weak self] observer in
            guard let self = self else { return Disposables.create() }
            
            self.marumaruApiService.getEpisodesInPlay()
                .subscribe(on: ConcurrentDispatchQueueScheduler.init(qos: .background))
                .observe(on: MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] episodes in
                    self?.comicEpisodes = episodes.reversed()
                    observer(.completed)
                }, onFailure: { error in
                    observer(.error(error))
                }).disposed(by: self.disposeBag)
            
            return Disposables.create()
        }
    }
}

extension ComicStripViewModel {
    private func getEndPoint(with newSerialNumber: String) -> String {
        if let serialNumberStartIndex = comicURL.lastIndex(of: "/") {
            let serialNumberRange = comicURL.index(serialNumberStartIndex, offsetBy: 1)..<comicURL.endIndex
            
            comicURL.replaceSubrange(serialNumberRange, with: newSerialNumber)
            currentComicSN = newSerialNumber
        }
        
        return comicURL
    }
    
    public func getSerialNumberFromUrl() -> String {
        if let serialNumberStartIndex = comicURL.lastIndex(of: "/") {
            let serialNumberRange = comicURL.index(serialNumberStartIndex, offsetBy: 1)..<comicURL.endIndex
            return comicURL[serialNumberRange].description
        }
        
        return ""
    }
}

extension ComicStripViewModel {
    public var currentEpisodeTitle: String {
        return comicTitle
    }
    
    public var currentEpisodeScenes: [ComicStripScene] {
        return comicStripScenes
    }
    
    public var currentComicEpisode: [Episode] {
        return comicEpisodes
    }
    
    private var currentEpisodeIndex: Int? {
        for (index, episode) in comicEpisodes.enumerated() where episode.serialNumber == currentComicSN {
            return index
        }
        
        return nil
    }
}
