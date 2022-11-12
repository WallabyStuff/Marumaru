//
//  SectionPlaceHoldable.swift
//  Marumaru
//
//  Created by 이승기 on 2022/07/11.
//

import UIKit

protocol SectionPlaceHoldable {
  associatedtype Section
  static func fakeSections(numberOfSection: Int, numberOfItem: Int) -> [Section]
  static func fakeSection(numberOfItem: Int) -> Section
}
