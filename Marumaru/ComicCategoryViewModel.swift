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
    
    public var noticeMessageObservable = PublishRelay<String>()
    public var presentComicDetailVCObservable = PublishRelay<ComicInfo>()
    
    private var comicSections = [ComicInfoSection]()
    public var comicSectionsObservable = BehaviorRelay<[ComicInfoSection]>(value: [])
    public var isLoadingComics = BehaviorRelay<Bool>(value: true)
    
    private var comicCategories = ComicCategory.allCases
    public var comicCategoriesObservable = BehaviorRelay<[ComicCategory]>(value: ComicCategory.allCases)
    public var selectedCategory = BehaviorRelay<ComicCategory>(value: .all)
}

extension ComicCategoryViewModel {
    public func updateComicCategory(_ category: ComicCategory) {
        let fakeSections = fakeComicSections(sectionCount: 6, rowCount: 10)
        comicSections = fakeSections
        comicSectionsObservable.accept(fakeSections)
        isLoadingComics.accept(true)
        
        MarumaruApiService.shared
            .getComicCategory(category)
            .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .background))
            .observe(on: MainScheduler.instance)
            .subscribe(with: self, onSuccess: { strongSelf, comics in
                let sections = strongSelf.groupComicsBySection(comics)
                strongSelf.comicSections = sections
                strongSelf.comicSectionsObservable.accept(sections)
                strongSelf.isLoadingComics.accept(false)
            }, onFailure: { strongSelf, _ in
                strongSelf.comicSectionsObservable.accept([])
                strongSelf.noticeMessageObservable.accept("message.serverError".localized())
                strongSelf.isLoadingComics.accept(false)
            })
            .disposed(by: disposeBag)
    }
    
    public func updateComicCategory() {
        let fakeSections = fakeComicSections(sectionCount: 6, rowCount: 10)
        comicSections = fakeSections
        comicSectionsObservable.accept(fakeSections)
        isLoadingComics.accept(true)
        
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
                strongSelf.comicSectionsObservable.accept([])
                strongSelf.noticeMessageObservable.accept("message.serverError".localized())
                strongSelf.isLoadingComics.accept(false)
            })
            .disposed(by: disposeBag)
    }
}

extension ComicCategoryViewModel {
    private func groupComicsBySection(_ comics: [ComicInfo]) -> [ComicInfoSection] {
        var comics: [ComicInfo] = comics.reversed()
        var sections = [ComicInfoSection]()
        
        for _ in (0..<3) {
            var section = ComicInfoSection(items: [])
            
            for _ in (0..<6) {
                if let comic = comics.popLast() {
                    section.items.append(comic)
                }
            }
            
            sections.append(section)
        }
        
        return sections
    }
}

extension ComicCategoryViewModel {
    public func didTapComicItem(_ indexPath: IndexPath) {
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
    public func categoryItem(_ indexPath: IndexPath) -> ComicCategory {
        return comicCategories[indexPath.row]
    }
}

extension ComicCategoryViewModel {
    public func categoryItemSelected(_ indexPath: IndexPath) {
        let category = comicCategories[indexPath.row]
        if selectedCategory.value == category { return }
        
        selectedCategory.accept(category)
        
        if indexPath.row == 0 {
            updateComicCategory()
        } else {
            updateComicCategory(category)
        }
    }
}
