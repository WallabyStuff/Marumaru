//
//  PlayMangaViewModel.swift
//  Marumaru
//
//  Created by 이승기 on 2022/02/03.
//

import UIKit
import RxSwift
import RxCocoa

enum PlayMangaViewError: Error {
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

class PlayMangaViewModel: MarumaruApiServiceViewModel {
    private var disposeBag = DisposeBag()
    private var mangaUrl: String = ""
    private var currentMangaSerialNumber: String = ""
    private var marumaruApiService = MarumaruApiService()
    private var watchHistoryHandler = WatchHistoryManager()
    
    public var updateMangaTitleLabel: (() -> Void)?
    public var reloadSceneScrollView: (() -> Void)?
    public var prepareForReloadSceneScrollview: (() -> Void)?
    public var reloadEpisodeTableView: (() -> Void)?
    
    private var mangaTitle: String = "" {
        didSet {
            self.updateMangaTitleLabel?()
        }
    }
    
    private var mangaScenes = [MangaScene]() {
        didSet {
            self.reloadSceneScrollView?()
        }
    }
    
    private var mangaEpisodes = [Episode]() {
        didSet {
            self.reloadEpisodeTableView?()
        }
    }
    
    init(mangaTitle: String, link: String) {
        super.init()
        self.mangaTitle = mangaTitle
        self.mangaUrl = link
        
        setupData()
    }
    
    private func setupData() {
        currentMangaSerialNumber = getSerialNumberFromUrl()
    }
}

extension PlayMangaViewModel {
    public func playManga(_ serialNumber: String) -> Completable {
        return Completable.create { [weak self] observer in
            guard let self = self else { return Disposables.create() }
            
            self.currentMangaSerialNumber = serialNumber
            self.mangaTitle = ""
            self.mangaScenes.removeAll()
            self.prepareForReloadSceneScrollview?()
            
            let endPoint = self.getEndPoint(with: serialNumber)
            self.marumaruApiService.getMangaScenes(endPoint)
                .subscribe(on: ConcurrentDispatchQueueScheduler.init(qos: .background))
                .observe(on: MainScheduler.instance)
                .subscribe(with: self, onNext: { strongSelf, scenes in
                    strongSelf.getMangaEpisodes()
                        .subscribe(onCompleted: { [weak self] in
                            self?.mangaScenes = scenes
                            self?.updateMangaTitle()
                            self?.saveToWatchHistory()
                            observer(.completed)
                        }).disposed(by: self.disposeBag)
                }).disposed(by: self.disposeBag)
            return Disposables.create()
        }
    }
    
    public func playCurrentManga() -> Completable {
        return Completable.create { [weak self] observer in
            guard let self = self else { return Disposables.create() }
         
            self.playManga(self.currentMangaSerialNumber)
                .subscribe(onCompleted: {
                    observer(.completed)
                }, onError: { error in
                    observer(.error(error))
                }).disposed(by: self.disposeBag)
            return Disposables.create()
        }
    }
    
    public func playNextManga() -> Completable {
        return Completable.create { [weak self] observer in
            guard let self = self else { return Disposables.create() }
            
            if let index = self.currentEpisodeIndex {
                if index + 1 < self.mangaEpisodes.count {
                    let nextMangaIndex = self.mangaEpisodes.index(index, offsetBy: +1)
                    let nextMangaSerialNumber = self.mangaEpisodes[nextMangaIndex].serialNumber
                    
                    self.playManga(nextMangaSerialNumber)
                        .subscribe(onCompleted: {
                            observer(.completed)
                        }, onError: { error in
                            observer(.error(error))
                        }).disposed(by: self.disposeBag)
                } else {
                    observer(.error(PlayMangaViewError.endOfEpisode))
                }
            } else {
                observer(.error(PlayMangaViewError.endOfEpisode))
            }
            
            return Disposables.create()
        }
    }
    
    public func playPreviousManga() -> Completable {
        return Completable.create { [weak self] observer in
            guard let self = self else { return Disposables.create() }
            
            if let index = self.currentEpisodeIndex {
                if index - 1 >= 0 {
                    let nextMangaIndex = self.mangaEpisodes.index(index, offsetBy: -1)
                    let nextMangaSerialNumber = self.mangaEpisodes[nextMangaIndex].serialNumber
                    
                    self.playManga(nextMangaSerialNumber)
                        .subscribe(onCompleted: {
                            observer(.completed)
                        }, onError: { error in
                            observer(.error(error))
                        }).disposed(by: self.disposeBag)
                } else {
                    observer(.error(PlayMangaViewError.firstEpisode))
                }
            } else {
                observer(.error(PlayMangaViewError.firstEpisode))
            }
            
            return Disposables.create()
        }
    }
    
    public func updateMangaTitle() {
        for episode in mangaEpisodes where episode.serialNumber == currentMangaSerialNumber {
            return mangaTitle = episode.title
        }
    }
}

extension PlayMangaViewModel {
    public var firstSceneImageUrl: String? {
        return mangaScenes.first?.sceneImageUrl
    }
    
    public func saveToWatchHistory() {
        let currentManga = WatchHistory(mangaUrl: mangaUrl,
                                        mangaTitle: mangaTitle,
                                        thumbnailImageUrl: firstSceneImageUrl ?? "")
        
        watchHistoryHandler.addData(watchHistory: currentManga)
            .subscribe().disposed(by: disposeBag)
    }
}

extension PlayMangaViewModel {
    private func getMangaEpisodes() -> Completable {
        return Completable.create { [weak self] observer in
            guard let self = self else { return Disposables.create() }
            
            self.marumaruApiService.getEpisodesInPlay()
                .subscribe(on: ConcurrentDispatchQueueScheduler.init(qos: .background))
                .observe(on: MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] episodes in
                    self?.mangaEpisodes = episodes.reversed()
                    observer(.completed)
                }, onFailure: { error in
                    observer(.error(error))
                }).disposed(by: self.disposeBag)
            
            return Disposables.create()
        }
    }
}

extension PlayMangaViewModel {
    private func getEndPoint(with newSerialNumber: String) -> String {
        if let serialNumberStartIndex = mangaUrl.lastIndex(of: "/") {
            let serialNumberRange = mangaUrl.index(serialNumberStartIndex, offsetBy: 1)..<mangaUrl.endIndex
            
            mangaUrl.replaceSubrange(serialNumberRange, with: newSerialNumber)
            currentMangaSerialNumber = newSerialNumber
        }
        
        return mangaUrl
    }
    
    public func getSerialNumberFromUrl() -> String {
        if let serialNumberStartIndex = mangaUrl.lastIndex(of: "/") {
            let serialNumberRange = mangaUrl.index(serialNumberStartIndex, offsetBy: 1)..<mangaUrl.endIndex
            return mangaUrl[serialNumberRange].description
        }
        
        return ""
    }
}

extension PlayMangaViewModel {
    public var currentEpisodeTitle: String {
        return mangaTitle
    }
    
    public var currentEpisodeScenes: [MangaScene] {
        return mangaScenes
    }
    
    public var currentMangaEpisoeds: [Episode] {
        return mangaEpisodes
    }
    
    private var currentEpisodeIndex: Int? {
        for (index, episode) in mangaEpisodes.enumerated() where episode.serialNumber == currentMangaSerialNumber {
            return index
        }
        
        return nil
    }
}
