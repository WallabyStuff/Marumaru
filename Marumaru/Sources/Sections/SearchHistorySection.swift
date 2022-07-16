//
//  SearchHistorySection.swift
//  Marumaru
//
//  Created by 이승기 on 2022/05/31.
//

import UIKit
import RxDataSources

struct SearchHistorySection: IdentifiableType {
    var header: String = UUID().uuidString
    var items: [SearchHistory]
}

extension SearchHistorySection: AnimatableSectionModelType {
    
    typealias Item = SearchHistory
    typealias Identity = String
    
    var identity: String {
        return header
    }
    
    init(original: SearchHistorySection, items: [SearchHistory]) {
        self = original
        self.items = items
    }
}
