//
//  SearchResultSection.swift
//  Marumaru
//
//  Created by 이승기 on 2022/05/31.
//

import UIKit

import RxDataSources

struct ComicInfoSection: IdentifiableType {
  typealias Identity = String
  typealias Items = [ComicInfo]
  
  var identity: Identity
  var items: Items
  
  init(identity: Identity, items: Items) {
    self.identity = identity
    self.items = items
  }
}

extension ComicInfoSection: AnimatableSectionModelType {
  typealias Item = ComicInfo
  
  init(original: ComicInfoSection, items: [ComicInfo]) {
    self = original
    self.items = items
  }
}

extension ComicInfoSection: SectionPlaceHoldable {
  static func fakeSections(numberOfSection: Int, numberOfItem: Int) -> [ComicInfoSection] {
    var sections = [ComicInfoSection]()
    
    for _ in 0..<numberOfSection {
      let section = Self.fakeSection(numberOfItem: numberOfItem)
      sections.append(section)
    }
    
    return sections
  }
  
  static func fakeSection(numberOfItem: Int) -> ComicInfoSection {
    let items = ComicInfo.fakeItems(count: numberOfItem)
    let section = ComicInfoSection(identity: UUID().uuidString, items: items)
    
    return section
  }
}
