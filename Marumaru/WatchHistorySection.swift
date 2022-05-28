//
//  WatchHistorySection.swift
//  Marumaru
//
//  Created by 이승기 on 2022/05/27.
//

import RxDataSources

struct WatchHistorySection: IdentifiableType {
    var header: String
    var items: [WatchHistory]
}

extension WatchHistorySection: AnimatableSectionModelType {
    
    typealias Item = WatchHistory
    typealias Identity = String
    
    var identity: String {
        return header
    }
    
    init(original: WatchHistorySection, items: [WatchHistory]) {
        self = original
        self.items = items
    }
}
