//
//  SearchResultSection.swift
//  Marumaru
//
//  Created by 이승기 on 2022/05/31.
//

import UIKit
import RxDataSources

struct ComicInfoSection: IdentifiableType {
    var header: String = UUID().uuidString
    var items: [ComicInfo]
}

extension ComicInfoSection: AnimatableSectionModelType {
    
    typealias Item = ComicInfo
    typealias Identity = String
    
    var identity: String {
        return UUID().uuidString
    }
    
    init(original: ComicInfoSection, items: [ComicInfo]) {
        self = original
        self.items = items
    }
}
