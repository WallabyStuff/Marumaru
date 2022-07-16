//
//  ComicBookmark.swift
//  Marumaru
//
//  Created by 이승기 on 2022/06/06.
//

import Foundation

import RealmSwift
import RxDataSources

class ComicBookmark: Object {
    
    
    // MARK: - Properties
    
    @objc dynamic var comicSN = ""
    @objc dynamic var title = ""
    @objc dynamic var author = ""
    @objc dynamic var updateCycle = ""
    @objc dynamic var thumbnailImagePath = ""
    
    
    // MARK: - Initializer
    
    convenience init(comicSN: String,
                     title: String,
                     author: String,
                     updateCycle: String,
                     thumbnailImagePath: String) {
        self.init()
        self.comicSN = comicSN
        self.title = title
        self.author = author
        self.updateCycle = updateCycle
        self.thumbnailImagePath = thumbnailImagePath
    }
    
    override class func primaryKey() -> String? {
        return "comicSN"
    }
}

extension ComicBookmark: IdentifiableType {
    typealias Identity = String
    
    var identity: String {
        if isInvalidated {
            return UUID().uuidString
        } else {
            return comicSN
        }
    }
}

extension ComicBookmark {
    public func convertToComicEpisode() -> ComicEpisode {
        let comicEpisode = ComicEpisode(comicSN: comicSN,
                                        episodeSN: "",
                                        title: title,
                                        description: description,
                                        thumbnailImagePath: thumbnailImagePath)
        return comicEpisode
    }
}
