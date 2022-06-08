//
//  MarumaruTests.swift
//  MarumaruTests
//
//  Created by 이승기 on 2021/04/06.
//

import XCTest
import RxSwift
@testable import Marumaru

class MarumaruAPITests: XCTestCase {
    func newEpisodes() {
        MarumaruApiService.shared.getNewComicEpisodes()
            .subscribe(onSuccess: { episodes in
                XCTAssertEqual(episodes.count, 14)
            })
            .dispose()
    }
    
    func comicCategory() {
        MarumaruApiService.shared.getComicCategory()
            .subscribe(onSuccess: { comics in
                XCTAssertEqual(comics.count, 18)
            })
            .dispose()
    }
}
