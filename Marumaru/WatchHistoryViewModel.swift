//
//  WatchHistoryViewModel.swift
//  Marumaru
//
//  Created by 이승기 on 2022/02/04.
//

import UIKit
import RxSwift
import RxCocoa

class WatchHistoryViewModel {
    
    private var disposeBag = DisposeBag()
    private let watchHistoryManager = WatchHistoryManager()
    
    private var watchHistories = [WatchHistorySection]()
    public var watchHistoriesObservable = PublishRelay<[WatchHistorySection]>()
    public var failToLoadWatchHistories = PublishRelay<Bool>()
    
    public var presentComicDetailVC = PublishRelay<ComicEpisode>()
}

extension WatchHistoryViewModel {
    public func updateWatchHistories() {
        failToLoadWatchHistories.accept(false)
        
        watchHistoryManager.fetchData()
            .subscribe(with: self, onSuccess: { strongSelf, comics in
                strongSelf.watchHistories = strongSelf.configureSections(comics)
                strongSelf.watchHistoriesObservable.accept(strongSelf.watchHistories)
            }, onFailure: { strongSelf, _ in
                strongSelf.failToLoadWatchHistories.accept(true)
            }).disposed(by: self.disposeBag)
    }
    
    public func clearHistories() {
        watchHistoryManager.deleteAll()
            .subscribe(with: self, onCompleted: { strongSelf in
                strongSelf.watchHistoriesObservable.accept([])
            }, onError: { strongSelf, _ in
                strongSelf.failToLoadWatchHistories.accept(true)
            }).disposed(by: self.disposeBag)
    }
}

extension WatchHistoryViewModel {
    private func configureSections(_ watchHistories: [WatchHistory]) -> [WatchHistorySection] {
        var groupedWatchHistories = Dictionary<String, [WatchHistory]>()
        var sections = [WatchHistorySection]()
        
        watchHistories.forEach { watchHistory in
            if groupedWatchHistories[watchHistory.watchDateFormattedString] == nil {
                groupedWatchHistories[watchHistory.watchDateFormattedString] = [watchHistory]
            } else {
                groupedWatchHistories[watchHistory.watchDateFormattedString]?.insert(watchHistory, at: 0)
            }
        }
        
        groupedWatchHistories.sorted { $0.key > $1.key }.forEach { watchHistories in
            let section = WatchHistorySection(header: watchHistories.key,
                                              items: watchHistories.value)
            sections.append(section)
        }
        
        return sections
    }
}

extension WatchHistoryViewModel {
    public func comicItemSelected(_ indexPath: IndexPath) {
        let selectedItem = watchHistories[indexPath.section].items[indexPath.row]
        let comicEpisode = ComicEpisode(comicSN: selectedItem.comicSN,
                                        episodeSN: selectedItem.episodeSN,
                                        title: selectedItem.title,
                                        description: selectedItem.description,
                                        thumbnailImagePath: selectedItem.thumbnailImagePath)
        presentComicDetailVC.accept(comicEpisode)
    }
    
    public func sectionHeader(_ indexPath: IndexPath) -> String {
        return watchHistories[indexPath.section].header
    }
}

extension WatchHistoryViewModel {
    public func getImageURL(_ imagePath: String?) -> URL? {
        guard let imagePath = imagePath else {
            return nil
        }

        return MarumaruApiService.shared.getImageURL(imagePath)
    }
}
