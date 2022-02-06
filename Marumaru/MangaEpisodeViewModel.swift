//
//  MangaEpisodeViewModel.swift
//  Marumaru
//
//  Created by 이승기 on 2022/02/03.
//

import UIKit
import RxSwift
import RxCocoa

class MangaEpisodeViewModel: MarumaruApiServiceViewModel {
    private var disposeBag = DisposeBag()
    private let marumaruApiService = MarumaruApiService()
    private let watchHistoryHandler = WatchHistoryManager()
    private var watchHistories = [String: String]()
    public var reloadMangaEpisodeTableView: (() -> Void)?
    
    private var mangaEpisodes = [MangaEpisode]() {
        didSet {
            getWatchHistories()
                .subscribe(onCompleted: { [weak self] in
                    self?.reloadMangaEpisodeTableView?()
                }, onError: { error in
                    print(error.localizedDescription)
                }).disposed(by: disposeBag)
        }
    }
}

extension MangaEpisodeViewModel {
    public func getMangaEpisodes(_ serialNumber: String) -> Completable {
        return Completable.create { [weak self] observer in
            guard let self = self else { return Disposables.create()}
            
            self.marumaruApiService.getEpisodes(serialNumber)
                .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .background))
                .observe(on: MainScheduler.instance)
                .subscribe(with: self, onNext: { strongSelf, episodes in
                    strongSelf.mangaEpisodes = episodes
                    observer(.completed)
                }, onError: { _, error in
                    observer(.error(error))
                }).disposed(by: self.disposeBag)
            
            return Disposables.create()
        }
    }
    
    public var totalEpisodeCountText: String {
        return "총 \(mangaEpisodes.count)화"
    }
    
    public var totalEpisodeCount: Int {
        return mangaEpisodes.count
    }
}

extension MangaEpisodeViewModel {
    public func getWatchHistories() -> Completable {
        return Completable.create { [weak self] observer in
            guard let self = self else { return Disposables.create() }
            
            self.watchHistoryHandler.fetchData()
                .subscribe(onSuccess: { [weak self] watchHistories in
                    self?.watchHistories =  Dictionary(uniqueKeysWithValues: watchHistories.map { ($0.mangaUrl, $0.mangaUrl) })
                    observer(.completed)
                }, onFailure: { error in
                    observer(.error(error))
                }).disposed(by: self.disposeBag)
            
            return Disposables.create()
        }
    }
    
    public func ifAlreadyWatched(at indexPath: IndexPath) -> Bool {
        
        return watchHistories[mangaEpisodes[indexPath.row].mangaURL] == nil ? false : true
    }
}

extension MangaEpisodeViewModel {
    public func numberOfRowsIn(section: Int) -> Int {
        if section == 0 {
            return mangaEpisodes.count
        } else {
            return 0
        }
    }
    
    public func cellItemForRow(at indexPath: IndexPath) -> MangaEpisode {
        return mangaEpisodes[indexPath.row]
    }
}
