//
//  ComicInfo.swift
//  Marumaru
//
//  Created by 이승기 on 2021/08/17.
//

import UIKit

import RxDataSources

struct ComicInfo {
  var comicSN: String
  var title: String
  var author: String = "작가정보 없음"
  var updateCycle: String = "미분류"
  var thumbnailImage: UIImage?
  var thumbnailImagePath: String?
}

extension ComicInfo: IdentifiableType {
  typealias Identity = String
  
  var identity: Identity {
    return comicSN
  }
}

extension ComicInfo: Equatable {
  static func == (lhs: ComicInfo, rhs: ComicInfo) -> Bool {
    if lhs.comicSN == rhs.comicSN {
      return true
    }
    return false
  }
}

extension ComicInfo: ItemPlaceHoldable {
  static func fakeItems(count: Int) -> [ComicInfo] {
    var items = [ComicInfo]()
    
    for _ in 0..<count {
      items.append(Self.fakeItem)
    }
    
    return items
  }
  
  static var fakeItem: ComicInfo {
    return .init(comicSN: UUID().uuidString,
                 title: "",
                 author: "",
                 updateCycle: "미분류")
  }
}
