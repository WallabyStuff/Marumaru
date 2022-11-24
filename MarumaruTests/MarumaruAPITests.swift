//
//  MarumaruTests.swift
//  MarumaruTests
//
//  Created by 이승기 on 2021/04/06.
//

import XCTest
import RxSwift
import SwiftSoup
@testable import Marumaru

class MarumaruAPITests: XCTestCase {
  func testMarumaruApiService_WhenValidBasePathProvided_ShouldReturnNotNilDocument() {
    if let url = URL(string: UserDefaultsManager.basePath) {
      do {
        let html = try String(contentsOf: url, encoding: .utf8)
        let document = try SwiftSoup.parse(html)
        XCTAssertNotNil(document)
      } catch {
        XCTAssertTrue(false)
      }
    } else {
      XCTAssertTrue(false)
    }
  }
  
  func testMarumaruApiService_WhenValidBasePathProvided_ShouldReturn14AmountOfNewComics() {
    MarumaruApiService.shared.getNewComicEpisodes()
      .subscribe(onSuccess: { episodes in
        XCTAssertEqual(episodes.count, 14)
      })
      .dispose()
  }
  
  func testMarumaruApiService_WhenValidBasePathProvided_ShouldReturn18AmountOfCategorizedComics() {
    MarumaruApiService.shared.getComicCategory()
      .subscribe(onSuccess: { comics in
        XCTAssertEqual(comics.count, 18)
      })
      .dispose()
  }
}
