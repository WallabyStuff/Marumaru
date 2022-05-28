//
//  ComicEpisodePopOverViewModel.swift
//  Marumaru
//
//  Created by 이승기 on 2022/02/05.
//

import Foundation
import RxSwift
import RxCocoa

class ComicEpisodePopOverViewModel {
    
    public var currentEpisodeSN: String
    private var episodes: [Episode]
    public var episodesObservable = BehaviorRelay<[Episode]>(value: [])
    
    init(_ serialNumber: String, _ episodes: [Episode]) {
        self.currentEpisodeSN = serialNumber
        self.episodes = episodes.reversed()
        self.episodesObservable.accept(self.episodes)
    }
}

extension ComicEpisodePopOverViewModel {
    public func numberOfRowsInSection(_ section: Int) -> Int {
        if section == 0 {
            return episodes.count
        } else {
            return 0
        }
    }
    
    public func cellItemForRow(at indexPath: IndexPath) -> Episode {
        return episodes[indexPath.row]
    }
}

extension ComicEpisodePopOverViewModel {
    public var currentEpisodeIndex: Int? {
        for (index, episode) in episodes.enumerated() where episode.serialNumber == currentEpisodeSN {
            return index
        }
        
        return nil
    }
}
