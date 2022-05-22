//
//  WatchHistory.swift
//  Marumaru
//
//  Created by 이승기 on 2021/08/20.
//

import UIKit
import RealmSwift

class WatchHistory: Object {
    
    // MARK: - Declaration
    @objc dynamic var comicURL: String = ""
    @objc dynamic var comicTitle: String = ""
    @objc dynamic var thumbnailImageURL: String = ""
    @objc dynamic var timeStamp: Int64 = 0
    
    // MARK: - Initializer
    convenience init(comicURL: String,
                     comicTitle: String,
                     thumbnailImageUrl: String) {
        self.init()
        self.comicURL = comicURL
        self.comicTitle = comicTitle
        self.thumbnailImageURL = thumbnailImageUrl
        self.timeStamp = Date.timeStamp
    }
    
    override class func primaryKey() -> String? {
        return "comicURL"
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
