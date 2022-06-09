//
//  ComicInfo.swift
//  Marumaru
//
//  Created by 이승기 on 2021/08/17.
//

import UIKit
import RxDataSources

struct ComicInfo: Equatable {
    var comicSN: String
    var title: String
    var author: String = "작가정보 없음"
    var updateCycle: String = "미분류"
    var thumbnailImage: UIImage?
    var thumbnailImagePath: String?
}

extension ComicInfo: IdentifiableType {
    typealias Identity = String
    
    var identity: String {
        return UUID().uuidString
    }
}
