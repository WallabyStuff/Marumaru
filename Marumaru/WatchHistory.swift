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
    
    @objc dynamic var episodeTitle: String = ""
    @objc dynamic var episodeURL: String = ""
    @objc dynamic var thumbnailImageURL: String = ""
    @objc dynamic var timeStamp: Int64 = 0
    
    
    // MARK: - Initializer
    
    convenience init(episodeTitle: String,
                     episodeURL: String,
                     thumbnailImageUrl: String) {
        self.init()
        self.episodeTitle = episodeTitle
        self.episodeURL = episodeURL
        self.thumbnailImageURL = thumbnailImageUrl
        self.timeStamp = Date.timeStamp
    }
    
    override class func primaryKey() -> String? {
        return "episodeURL"
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
            return episodeURL
        }
    }
}
