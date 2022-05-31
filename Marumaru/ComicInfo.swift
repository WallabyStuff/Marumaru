//
//  ComicInfo.swift
//  Marumaru
//
//  Created by 이승기 on 2021/08/17.
//

import UIKit
import RxDataSources

struct ComicInfo: Equatable {
    var title: String
    var author: String
    var updateCycle: String
    var thumbnailImage: UIImage?
    var thumbnailImageURL: String?
    var serialNumber: String
}

extension ComicInfo: IdentifiableType {
    typealias Identity = String
    
    var identity: String {
        return UUID().uuidString
    }
}
