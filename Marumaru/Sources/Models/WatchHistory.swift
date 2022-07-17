//
//  WatchHistory.swift
//  Marumaru
//
//  Created by 이승기 on 2021/08/20.
//

import UIKit
import RealmSwift
import Differentiator

class WatchHistory: Object {

    
    // MARK: - Properties
    
    @objc dynamic var comicSN: String = ""
    @objc dynamic var episodeSN: String = ""
    @objc dynamic var title: String = ""
    @objc dynamic var thumbnailImagePath = ""
    @objc dynamic var timeStamp: Int64 = 0
    
    
    // MARK: - Initializer
    
    convenience init(comicSN: String,
                     episodeSN: String,
                     title: String,
                     thumbnailImagePath: String = "") {
        self.init()
        self.comicSN = comicSN
        self.episodeSN = episodeSN
        self.title = title
        self.thumbnailImagePath = thumbnailImagePath
        self.timeStamp = Int64(Date().timeIntervalSince1970)
    }
    
    override class func primaryKey() -> String? {
        return "episodeSN"
    }
}

extension WatchHistory {
    public var watchDateFormattedString: String {
        let stringDateFormatter = DateFormatter()
        stringDateFormatter.dateFormat = "yyyy년 MM월 dd일"
        return stringDateFormatter.string(from: watchDate)
    }
    
    public var watchDate: Date {
        return Date(timeIntervalSince1970: Double(timeStamp))
    }
}


extension WatchHistory: IdentifiableType {
    typealias Identity = String
    
    var identity: String {
        if isInvalidated {
            // return random id to prevent RLMException
            return UUID().uuidString
        } else {
            return episodeSN
        }
    }
}

extension WatchHistory {
    public func convertToComicEpisode() -> ComicEpisode {
        let comicEpisode = ComicEpisode(comicSN: comicSN,
                                        episodeSN: episodeSN,
                                        title: title,
                                        description: description,
                                        thumbnailImagePath: thumbnailImagePath)
        
        return comicEpisode
    }
}
