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
    private let marumaruApiService = MarumaruApiService()
    private let watchHistoryManager = WatchHistoryManager()

    private var newUpdateComics = [Comic]()
    public var newUpdateComicsObservable = BehaviorRelay<[Comic]>(value: [])
    public var isLoadingNewUpdateComic = BehaviorRelay<Bool>(value: true)
    public var failToGetNewUPdateComic = BehaviorRelay<Bool>(value: false)
    
    private var watchHistories = [WatchHistory]()
    public var watchHistoriesObservable = PublishRelay<[WatchHistory]>()
    
    private var comicRank = [ComicRank]()
    public var comicRankObservable = BehaviorRelay<[ComicRank]>(value: [])
    public var isLoadingComicRank = BehaviorRelay<Bool>(value: false)
    public var failToGetComicRank = BehaviorRelay<Bool>(value: false)
    
    public var presentComicStripVCObservable = PublishRelay<Comic>()
}

extension MainViewModel {
    public func updateNewUpdatedComics() {
        newUpdateComicsObservable.accept(fakeComicItems(10))
        isLoadingNewUpdateComic.accept(true)
        failToGetNewUPdateComic.accept(false)
        
        marumaruApiService
            .getNewUpdateComic()
            .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .background))
            .observe(on: MainScheduler.instance)
            .subscribe(with: self, onNext: { strongSelf, comics in
                strongSelf.newUpdateComics = comics
                strongSelf.newUpdateComicsObservable.accept(comics)
                strongSelf.isLoadingNewUpdateComic.accept(false)
            }, onError: { strongSelf, error in
                print(error.localizedDescription)
                strongSelf.failToGetNewUPdateComic.accept(true)
            })
            .disposed(by: self.disposeBag)
    }
    
    public func updateWatchHistories() {
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
    
    public func updateComicRank() {
        comicRankObservable.accept(fakeComicRankItems(10))
        isLoadingComicRank.accept(true)
        failToGetComicRank.accept(false)
        
        marumaruApiService
            .getTopRankComic()
            .subscribe(on: ConcurrentDispatchQueueScheduler.init(qos: .background))
            .observe(on: MainScheduler.instance)
            .subscribe(with: self, onNext: { strongSelf, comics in
                strongSelf.comicRank = comics
                strongSelf.comicRankObservable.accept(comics)
                strongSelf.isLoadingComicRank.accept(false)
            }, onError: { strongSelf, _ in
                strongSelf.failToGetComicRank.accept(true)
            }).disposed(by: self.disposeBag)
    }
    
    public func newUpdateComicItemSelected(_ indexPath: IndexPath) {
        let selectedComic = newUpdateComics[indexPath.row]
        presentComicStripVCObservable.accept(selectedComic)
    }
    
    public func watchHistoryItemSelected(_ indexPath: IndexPath) {
        let selectedComic = watchHistories[indexPath.row]
        let comic = Comic(title: selectedComic.episodeTitle,
                          link: selectedComic.episodeURL)
        presentComicStripVCObservable.accept(comic)
    }
    
    public func comicRankItemSelected(_ indexPath: IndexPath) {
        let selectedComic = comicRank[indexPath.row]
        let comic = Comic(title: selectedComic.title,
                          link: selectedComic.episodeURL)
        presentComicStripVCObservable.accept(comic)
    }
}

extension MainViewModel {
    public func fakeComicItems(_ count: Int) -> [Comic] {
        return [Comic](repeating: fakeComicItem, count: count)
    }
    
    public var fakeComicItem: Comic {
        return .init(title: "", link: "")
    }
    
    public func fakeComicRankItems(_ count: Int) -> [ComicRank] {
        return [ComicRank](repeating: fakeComicRankItem, count: count)
    }
    
    public var fakeComicRankItem: ComicRank {
        return .init(title: "", episodeURL: "")
    }
}
