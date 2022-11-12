//
//  CellPlaceHoldable.swift
//  Marumaru
//
//  Created by 이승기 on 2022/07/11.
//

import UIKit

protocol ItemPlaceHoldable {
  associatedtype Item
  static func fakeItems(count: Int) -> [Item]
  static var fakeItem: Item { get }
}
