//
//  WatchiHistoryRealm.swift
//  Marumaru
//
//  Created by 이승기 on 2021/08/20.
//

import UIKit
import RealmSwift

class WatchHistory: Object {
    
    // MARK: - Declaration
    @objc dynamic var mangaUrl: String = ""
    @objc dynamic var mangaTitle: String = ""
    @objc dynamic var thumbnailImageUrl: String = ""
    @objc dynamic var timeStamp: Int64 = 0
    
    // MARK: - Initializer
    convenience init(mangaUrl: String,
                     mangaTitle: String,
                     thumbnailImageUrl: String) {
        self.init()
        self.mangaUrl = mangaUrl
        self.mangaTitle = mangaTitle
        self.thumbnailImageUrl = thumbnailImageUrl
        self.timeStamp = Date.timeStamp
    }
    
    override class func primaryKey() -> String? {
        return "mangaUrl"
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
