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

extension ComicEpisode: Equatable {
    static func == (lhs: ComicEpisode, rhs: ComicEpisode) -> Bool {
        if lhs.comicSN == rhs.comicSN {
            return true
        } else {
            return false
        }
    }
}

extension ComicEpisode: ItemPlaceHoldable {
    static func fakeItems(count: Int) -> [ComicEpisode] {
        var items = [ComicEpisode]()
        
        for _ in 0..<count {
            items.append(Self.fakeItem)
        }
        
        return items
    }
    
    static var fakeItem: ComicEpisode {
        return .init(comicSN: UUID().uuidString, title: "")
    }
}
