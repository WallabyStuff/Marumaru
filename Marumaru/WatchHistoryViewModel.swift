//
//  HistoryViewModel.swift
//  Marumaru
//
//  Created by 이승기 on 2022/02/04.
//

import UIKit
import RxSwift
import RxCocoa

enum WatchHistoryViewError: Error {
    case emptyHistory
    
    var message: String {
        switch self {
        case .emptyHistory:
            return "아직 시청 기록이 없습니다"
        }
    }
}

class WatchHistoryViewModel: MarumaruApiServiceViewModel {
    
    private var disposeBag = DisposeBag()
    private let watchHistoryManager = WatchHistoryManager()
    
    public var reloadWatchHistoryCollectionView: (() -> Void)?
    private var groupedWatchHistories = [(String, [WatchHistory])]() {
        didSet {
            self.reloadWatchHistoryCollectionView?()
        }
    }
}

extension WatchHistoryViewModel {
    public func getWatchHistories() -> Completable {
        return Completable.create { [weak self] observer in
            guard let self = self else { return Disposables.create() }
            self.groupedWatchHistories.removeAll()
            
            self.watchHistoryManager.fetchData()
                .subscribe(onSuccess: { [weak self] watchHistories in
                    if watchHistories.count == 0 {
                        observer(.error(WatchHistoryViewError.emptyHistory))
                    } else {
                        self?.groupWatchHistoryByDate(watchHistories)
                        observer(.completed)
                    }
                }, onFailure: { error in
                    observer(.error(error))
                }).disposed(by: self.disposeBag)
            
            return Disposables.create()
        }
    }
    
    public func clearHistories() -> Completable {
        return Completable.create { [weak self] observer in
            guard let self = self else { return Disposables.create() }
            
            self.watchHistoryManager.deleteAll()
                .subscribe(with: self, onCompleted: { vc in
                    vc.getWatchHistories()
                        .subscribe(onCompleted: {
                            observer(.completed)
                        }, onError: { error in
                            observer(.error(error))
                        }).disposed(by: vc.disposeBag)
                }, onError: { _, error in
                    observer(.error(error))
                }).disposed(by: self.disposeBag)
            
            return Disposables.create()
        }
    }
    
    private func groupWatchHistoryByDate(_ watchHistories: [WatchHistory]) {
        var groupedWatchHistories = Dictionary<String, [WatchHistory]>()
        let watchHistories = watchHistories.sorted { $0.timeStamp > $1.timeStamp }
        
        watchHistories.forEach { watchHistory in
            if groupedWatchHistories[watchHistory.watchDateFormattedString] == nil {
                groupedWatchHistories[watchHistory.watchDateFormattedString] = [watchHistory]
            } else {
                groupedWatchHistories[watchHistory.watchDateFormattedString]?.append(watchHistory)
            }
        }
        
        self.groupedWatchHistories = groupedWatchHistories.sorted { $0.key > $1.key }
    }
}

extension WatchHistoryViewModel {
    public var numberOfSection: Int {
        return groupedWatchHistories.count
    }
    
    public func numberOfItemsIn(section: Int) -> Int {
        return groupedWatchHistories[section].1.count
    }
    
    public func watchHistoryCellItemForRow(at indexPath: IndexPath) -> WatchHistory {
        return groupedWatchHistories[indexPath.section].1[indexPath.row]
    }
}

extension Dictionary {
    func index(_ of: Int) -> Index {
        return index(startIndex, offsetBy: of)
    }
}
