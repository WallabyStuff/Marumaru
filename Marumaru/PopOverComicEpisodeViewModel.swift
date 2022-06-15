//
//  ComicEpisodePopOverViewModel.swift
//  Marumaru
//
//  Created by 이승기 on 2022/02/05.
//

import Foundation
import RxSwift
import RxCocoa

class PopOverComicEpisodeViewModel {
    
    public var currentEpisodeSN: String
    public var episodes: [EpisodeItem]
    public var episodesObservable = BehaviorRelay<[EpisodeItem]>(value: [])
    
    init(_ serialNumber: String, _ episodes: [EpisodeItem]) {
        self.currentEpisodeSN = serialNumber
        self.episodes = episodes.reversed()
        self.episodesObservable.accept(self.episodes)
    }
}

extension PopOverComicEpisodeViewModel {
    public func numberOfRowsInSection(_ section: Int) -> Int {
        if section == 0 {
            return episodes.count
        } else {
            return 0
        }
    }
    
    public func cellItemForRow(at indexPath: IndexPath) -> EpisodeItem {
        return episodes[indexPath.row]
    }
}

extension PopOverComicEpisodeViewModel {
    public var currentEpisodeIndex: Int? {
        for (index, episode) in episodes.enumerated() where episode.episodeSN == currentEpisodeSN {
            return index
        }
        
        return nil
    }
}
