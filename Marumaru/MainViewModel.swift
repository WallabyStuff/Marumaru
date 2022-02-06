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
    
    private var updatedContents = [Manga]() {
        didSet {
            self.reloadUpdatedContentCollectionView?()
        }
    }
    private var watchHistories = [WatchHistory]() {
        didSet {
            self.reloadWatchHistoryCollectionView?()
        }
    }
    private var topRankedMangas = [TopRankedManga]() {
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
            self.updatedContents.removeAll()
            
            self.marumaruApiService
                .getUpdatedMangas()
                .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .background))
                .observe(on: MainScheduler.instance)
                .subscribe(with: self, onNext: { strongSelf, updatedContents in
                    strongSelf.updatedContents = updatedContents
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
    
    public func getTopRankedMangas() -> Completable {
        return Completable.create { [weak self] observer in
            guard let self = self else { return Disposables.create() }
            self.topRankedMangas.removeAll()
            
            self.marumaruApiService
                .getTopRankedMangas()
                .subscribe(on: ConcurrentDispatchQueueScheduler.init(qos: .background))
                .observe(on: MainScheduler.instance)
                .subscribe(with: self, onNext: { strongSelf, topRankedMangas in
                    strongSelf.topRankedMangas = topRankedMangas
                    observer(.completed)
                }).disposed(by: self.disposeBag)
            
            return Disposables.create()
        }
    }
}

// MARK: - CollectionView
extension MainViewModel {
    var updatedContentsNumberOfItem: Int {
        return updatedContents.count
    }
    
    func updatedContentCellItemForRow(at indexPath: IndexPath) -> MangaInfoViewModel {
        let updatedManga = updatedContents[indexPath.row]
        return MangaInfoViewModel(title: updatedManga.title, link: updatedManga.link, thumbnailImageUrl: updatedManga.thumbnailImageUrl)
    }
}

extension MainViewModel {
    var watchHistoriesNumberOfItem: Int {
        return min(15, watchHistories.count)
    }
    
    func watchHistoryCellItemForRow(at indexPath: IndexPath) -> MangaInfoViewModel {
        let watchHistory = watchHistories[indexPath.row]
        let thumbnailImageUrl = watchHistory.thumbnailImageUrl.isEmpty ? nil : watchHistory.thumbnailImageUrl
        return MangaInfoViewModel(title: watchHistory.mangaTitle, link: watchHistory.mangaUrl, thumbnailImageUrl: thumbnailImageUrl)
    }
}

extension MainViewModel {
    struct MangaInfoViewModel {
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
        return topRankedMangas.count
    }
    
    func topRankCellItemForRow(at: IndexPath) -> TopRankedManga {
        return topRankedMangas[at.row]
    }
    
    func topRankCellRank(indexPath: IndexPath) -> Int {
        return indexPath.row + 1
    }
}
