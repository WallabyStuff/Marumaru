//
//  SearchHistory.swift
//  Marumaru
//
//  Created by 이승기 on 2022/05/29.
//

import Foundation
import RealmSwift
import RxDataSources

class SearchHistory: Object {
    
    @objc dynamic var title: String = ""
    @objc dynamic var date: Date = Date()
    
    convenience init(date: Date = Date(), title: String) {
        self.init()
        self.title = title
        self.date = date
    }
    
    override class func primaryKey() -> String? {
        return "title"
    }
}

extension SearchHistory: IdentifiableType {
    typealias Identity = String
    
    var identity: String {
        if isInvalidated {
            return UUID().uuidString
        } else {
            return title
        }
    }
}
