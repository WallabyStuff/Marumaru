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
  
  
  // MARK: - Properties
  
  public var currentEpisodeSN: String
  public var episodes = BehaviorRelay<[EpisodeItem]>(value: [])
  
  
  // MARK: - Initializers
  
  init(_ serialNumber: String, _ episodes: [EpisodeItem]) {
    self.currentEpisodeSN = serialNumber
    self.episodes.accept(episodes.reversed())
  }
}

extension PopOverComicEpisodeViewModel {
  public func numberOfRowsInSection(_ section: Int) -> Int {
    if section == 0 {
      return episodes.value.count
    } else {
      return 0
    }
  }
  
  public func cellItemForRow(at indexPath: IndexPath) -> EpisodeItem {
    return episodes.value[indexPath.row]
  }
}

extension PopOverComicEpisodeViewModel {
  public var currentEpisodeIndex: Int? {
    for (index, episode) in episodes.value.enumerated() where episode.episodeSN == currentEpisodeSN {
      return index
    }
    
    return nil
  }
}
