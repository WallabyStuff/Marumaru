//
//  MainViewModel.swift
//  Marumaru
//
//  Created by 이승기 on 2022/02/02.
//

import UIKit
import RxSwift
import RxCocoa

enum MainViewError: Error {
    case emptyHistory
    
    var message: String {
        switch self {
        case .emptyHistory:
            return "아직 시청 기록이 없습니다"
        }
    }
}

class MainViewModel: MarumaruApiServiceViewModel {
    private var disposeBag = DisposeBag()
    private let imageCacheManager = ImageCacheManager()
    private let marumaruApiService = MarumaruApiService()
    private let watchHistoryManager = WatchHistoryManager()
    public var reloadUpdatedContentCollectionView: (() -> Void)?
    public var reloadWatchHistoryCollectionView: (() -> Void)?
    public var reloadTopRankTableView: (() -> Void)?
    
    private var newUpdateComics = [Comic]() {
        didSet {
            self.reloadUpdatedContentCollectionView?()
        }
    }
    private var watchHistories = [WatchHistory]() {
        didSet {
            self.reloadWatchHistoryCollectionView?()
        }
    }
    private var topRankedComics = [TopRankedComic]() {
        didSet {
            self.reloadTopRankTableView?()
        }
    }
}

extension MainViewModel {
    public func cleanCacheIfNeeded() {
        ImageCacheManager.cleanChacheIfNeeded()
    }
}

extension MainViewModel {
    public func getUpdatedContents() -> Completable {
        return Completable.create { [weak self] observer in
            guard let self = self else { return Disposables.create() }
            self.newUpdateComics.removeAll()
            
            self.marumaruApiService
                .getNewUpdateComic()
                .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .background))
                .observe(on: MainScheduler.instance)
                .subscribe(with: self, onNext: { strongSelf, updatedContents in
                    strongSelf.newUpdateComics = updatedContents
                    observer(.completed)
                }, onError: { _, error  in
                    observer(.error(error))
                }).disposed(by: self.disposeBag)
            
            return Disposables.create()
        }
    }
    
    public func getWatchHistories() -> Completable {
        return Completable.create { [weak self] observer in
            guard let self = self else { return Disposables.create() }
            self.watchHistories.removeAll()
            
            self.watchHistoryManager
                .fetchData()
                .observe(on: MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] watchHistoires in
                    if watchHistoires.count == 0 {
                        observer(.error(MainViewError.emptyHistory))
                    } else {
                        self?.watchHistories = watchHistoires.sorted { $0.timeStamp > $1.timeStamp }
                        observer(.completed)
                    }
                }, onFailure: { error in
                    observer(.error(error))
                }).disposed(by: self.disposeBag)
            
            return Disposables.create()
        }
    }
    
    public func getTopRankedComics() -> Completable {
        return Completable.create { [weak self] observer in
            guard let self = self else { return Disposables.create() }
            self.topRankedComics.removeAll()
            
            self.marumaruApiService
                .getTopRankComic()
                .subscribe(on: ConcurrentDispatchQueueScheduler.init(qos: .background))
                .observe(on: MainScheduler.instance)
                .subscribe(with: self, onNext: { strongSelf, comics in
                    strongSelf.topRankedComics = comics
                    observer(.completed)
                }).disposed(by: self.disposeBag)
            
            return Disposables.create()
        }
    }
}

// MARK: - CollectionView
extension MainViewModel {
    var updatedContentsNumberOfItem: Int {
        return newUpdateComics.count
    }
    
    func updatedContentCellItemForRow(at indexPath: IndexPath) -> ComicInfoViewModel {
        let updatedComics = newUpdateComics[indexPath.row]
        return ComicInfoViewModel(title: updatedComics.title,
                                  link: updatedComics.link,
                                  thumbnailImageUrl: updatedComics.thumbnailImageUrl)
    }
}

extension MainViewModel {
    var watchHistoriesNumberOfItem: Int {
        return min(15, watchHistories.count)
    }
    
    func watchHistoryCellItemForRow(at indexPath: IndexPath) -> ComicInfoViewModel {
        let watchHistory = watchHistories[indexPath.row]
        let thumbnailImageUrl = watchHistory.thumbnailImageURL.isEmpty ? nil : watchHistory.thumbnailImageURL
        return ComicInfoViewModel(title: watchHistory.comicTitle,
                                  link: watchHistory.comicURL,
                                  thumbnailImageUrl: thumbnailImageUrl)
    }
}

extension MainViewModel {
    struct ComicInfoViewModel {
        var title: String
        var link: String
        var thumbnailImageUrl: String?
    }
}

// MARK: - TableView
extension MainViewModel {
    var topRankSectionCount: Int {
        return 1
    }
    
    func topRankNumberOfItemsInSection(section: Int) -> Int {
        return topRankedComics.count
    }
    
    func topRankCellItemForRow(at: IndexPath) -> TopRankedComic {
        return topRankedComics[at.row]
    }
    
    func topRankCellRank(indexPath: IndexPath) -> Int {
        return indexPath.row + 1
    }
}
