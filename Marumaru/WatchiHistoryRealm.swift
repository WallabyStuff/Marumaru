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
    
    // MARK: - Initialization
    convenience init(mangaUrl: String,
                     mangaTitle: String,
                     thumbnailImageUrl: String) {
        self.init()
        
        self.mangaUrl = mangaUrl
        self.mangaTitle = mangaTitle
        self.thumbnailImageUrl = thumbnailImageUrl
        self.timeStamp = Date.timeStamp
    }
    
    // MARK: - Override
    override class func primaryKey() -> String? {
        return "mangaUrl"
    }
}
