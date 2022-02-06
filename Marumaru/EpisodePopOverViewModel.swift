//
//  EpisodePopoverViewModle.swift
//  Marumaru
//
//  Created by 이승기 on 2022/02/05.
//

import Foundation

class EpisodePopOverViewModel {
    private var currentSerialNumber: String
    private var episodes: [Episode]
    private var currentEpisode: Episode?
    
    init(_ serialNumber: String, _ episodes: [Episode]) {
        self.currentSerialNumber = serialNumber
        self.episodes = episodes.reversed()
    }
}

extension EpisodePopOverViewModel {
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

extension EpisodePopOverViewModel {
    public var currentEpisodeIndex: Int? {
        for (index, episode) in episodes.enumerated() where episode.serialNumber == currentSerialNumber {
            return index
        }
        
        return nil
    }
    
    public var serialNumber: String {
        return currentSerialNumber
    }
}
