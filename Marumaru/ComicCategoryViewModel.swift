//
//  ComicCategoryViewModel.swift
//  Marumaru
//
//  Created by 이승기 on 2022/06/07.
//

import UIKit

import RxSwift
import RxCocoa

class ComicCategoryViewModel {
    
    
    // MARK: - Properties
    private var disposeBag = DisposeBag()
    
    private var comicSections = [ComicInfoSection]()
    public var comicSectionsObservable = BehaviorRelay<[ComicInfoSection]>(value: [])
    public var isLoadingComics = BehaviorRelay<Bool>(value: true)
    
    public var noticeMessageObservable = PublishRelay<String>()
    
    public var presentComicDetailVCObservable = PublishRelay<ComicInfo>()
}

extension ComicCategoryViewModel {
    public func updateComicCategory() {
        isLoadingComics.accept(true)
        let fakeSections = fakeComicSections(sectionCount: 6, rowCount: 10)
        comicSections = fakeSections
        comicSectionsObservable.accept(fakeSections)
        
        MarumaruApiService.shared
            .getComicCategory()
            .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .background))
            .observe(on: MainScheduler.instance)
            .subscribe(with: self, onSuccess: { strongSelf, comics in
                let sections = strongSelf.groupComicsBySection(comics)
                strongSelf.comicSections = sections
                strongSelf.comicSectionsObservable.accept(sections)
                strongSelf.isLoadingComics.accept(false)
            }, onFailure: { strongSelf, _ in
                strongSelf.isLoadingComics.accept(false)
                strongSelf.comicSectionsObservable.accept([])
                strongSelf.noticeMessageObservable.accept("message.serverError".localized())
            })
            .disposed(by: disposeBag)
    }
}

extension ComicCategoryViewModel {
    private func groupComicsBySection(_ comics: [ComicInfo]) -> [ComicInfoSection] {
        var comics = comics
        var sections = [ComicInfoSection]()
        
        for _ in (0..<3) {
            var section = ComicInfoSection(items: [])
            
            for _ in (0..<6) {
                let comic = comics.removeFirst()
                section.items.append(comic)
            }
            
            sections.append(section)
        }
        
        return sections
    }
}

extension ComicCategoryViewModel {
    public func tapComicItem(_ indexPath: IndexPath) {
        let comicInfo = comicSections[indexPath.section].items[indexPath.row]
        presentComicDetailVCObservable.accept(comicInfo)
    }
}

extension ComicCategoryViewModel {
    public func getImageURL(_ imagePath: String?) -> URL? {
        if let imagePath = imagePath {
            return MarumaruApiService.shared.getImageURL(imagePath)
        }
        
        return nil
    }
}

extension ComicCategoryViewModel {
    private func fakeComicSections(sectionCount: Int, rowCount: Int) -> [ComicInfoSection] {
        return [ComicInfoSection](repeating: fakeComicSection(rowCount), count: sectionCount)
    }
    
    private func fakeComicSection(_ rowCount: Int) -> ComicInfoSection {
        return .init(items: [ComicInfo](repeating: fakeComicItem, count: rowCount))
    }
    
    private var fakeComicItem: ComicInfo {
        return .init(comicSN: "", title: "", author: "", updateCycle: "")
    }
}

extension ComicCategoryViewModel {
    public var alignIndexPath: IndexPath? {
        if comicSections.count >= 2 {
            let lastItem = comicSections[1].items.count - 1
            let indexPath = IndexPath(row: lastItem, section: 1)
            return indexPath
        }
        
        return nil
    }
}
