//
//  SearchResultSection.swift
//  Marumaru
//
//  Created by 이승기 on 2022/05/31.
//

import UIKit
import RxDataSources

struct SearchResultSection: IdentifiableType {
    var header: String = UUID().uuidString
    var items: [ComicInfo]
}

extension SearchResultSection: AnimatableSectionModelType {
    
    typealias Item = ComicInfo
    typealias Identity = String
    
    var identity: String {
        return header
    }
    
    init(original: SearchResultSection, items: [ComicInfo]) {
        self = original
        self.items = items
    }
}
