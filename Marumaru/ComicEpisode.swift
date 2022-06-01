//
//  Comic.swift
//  Marumaru
//
//  Created by 이승기 on 2021/08/20.
//

import UIKit

class ComicEpisode {
    var comicSN: String
    var episodeSN: String
    var title: String
    var description: String?
    var thumbnailImagePath: String?
    
    init(comicSN: String,
         episodeSN: String = "",
         title: String,
         description: String? = nil,
         thumbnailImagePath: String? = nil) {
        self.comicSN = comicSN
        self.episodeSN = episodeSN
        self.title = title
        self.description = description
        self.thumbnailImagePath = thumbnailImagePath
    }
}

extension ComicEpisode {
    func replaceEpisode(_ newEpisode: EpisodeItem) {
        self.title = newEpisode.title
        self.episodeSN = newEpisode.episodeSN
    }
}
