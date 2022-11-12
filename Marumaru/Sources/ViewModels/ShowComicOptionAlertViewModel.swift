//
//  ShowComicOptionAlertViewModel.swift
//  Marumaru
//
//  Created by 이승기 on 2022/06/09.
//

import UIKit

import RxSwift
import RxCocoa

class ShowComicOptionAlertViewModel {
  
  
  // MARK: - Properties
  
  private var currentEpisode: ComicEpisode
  public var presentComicStripVC = PublishRelay<ComicEpisode>()
  public var presentComicDetailVC = PublishRelay<ComicInfo>()
  
  
  // MARK: - Initializers
  
  init(currentEpisode: ComicEpisode) {
    self.currentEpisode = currentEpisode
  }
}

extension ShowComicOptionAlertViewModel {
  public func showComicStripAction() {
    presentComicStripVC.accept(currentEpisode)
  }
}

extension ShowComicOptionAlertViewModel {
  public func showComicDetailAction() {
    let comicInfo = ComicInfo(comicSN: currentEpisode.comicSN,
                              title: "",
                              author: "",
                              updateCycle: "")
    
    presentComicDetailVC.accept(comicInfo)
  }
}

extension ShowComicOptionAlertViewModel {
  public var episodeTitle: String {
    return  currentEpisode.title
  }
}
