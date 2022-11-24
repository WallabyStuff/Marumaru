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
  
  private var currentPage = 1
  public var noticeMessageObservable = PublishRelay<String>()
  public var presentComicDetailVCObservable = PublishRelay<ComicInfo>()
  
  public var comicSections = BehaviorRelay<[ComicInfoSection]>(value: [])
  public var isLoadingComics = BehaviorRelay<Bool>(value: true)
  public var isLoadingNextPage = PublishRelay<Bool>()
  
  public var comicCategories = BehaviorRelay<[ComicCategory]>(value: ComicCategory.allCases)
  public var selectedCategory = BehaviorRelay<ComicCategory>(value: .all)
}

extension ComicCategoryViewModel {
  public func updateComicCategory(_ category: ComicCategory) {
    let fakeSections = ComicInfoSection.fakeSections(numberOfSection: 6, numberOfItem: 10)
    comicSections.accept(fakeSections)
    isLoadingComics.accept(true)
    
    MarumaruApiService.shared
      .getComicCategory(category)
      .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .background))
      .observe(on: MainScheduler.instance)
      .subscribe(with: self, onSuccess: { strongSelf, comics in
        let sections = strongSelf.groupComicsBySection(comics)
        strongSelf.comicSections.accept(sections)
        strongSelf.isLoadingComics.accept(false)
      }, onFailure: { strongSelf, _ in
        strongSelf.comicSections.accept([])
        strongSelf.noticeMessageObservable.accept("message.serverError".localized())
        strongSelf.isLoadingComics.accept(false)
      })
      .disposed(by: disposeBag)
  }
  
  public func updateComicCategory() {
    let fakeSections = ComicInfoSection.fakeSections(numberOfSection: 6, numberOfItem: 10)
    comicSections.accept(fakeSections)
    isLoadingComics.accept(true)
    
    MarumaruApiService.shared
      .getComicCategory()
      .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .background))
      .observe(on: MainScheduler.instance)
      .subscribe(with: self, onSuccess: { strongSelf, comics in
        let sections = strongSelf.groupComicsBySection(comics)
        strongSelf.comicSections.accept(sections)
        strongSelf.isLoadingComics.accept(false)
      }, onFailure: { strongSelf, _ in
        strongSelf.comicSections.accept([])
        strongSelf.noticeMessageObservable.accept("message.serverError".localized())
        strongSelf.isLoadingComics.accept(false)
      })
      .disposed(by: disposeBag)
  }
}

extension ComicCategoryViewModel {
  public func showNextPage() {
    let nextPage = currentPage + 1
    isLoadingNextPage.accept(true)
    
    MarumaruApiService.shared
      .getComicCategory(category: selectedCategory.value, page: nextPage)
      .subscribe(on: ConcurrentDispatchQueueScheduler.init(qos: .background))
      .observe(on: MainScheduler.instance)
      .subscribe(with: self, onSuccess: { strongSelf, comics in
        if !comics.isEmpty {
          strongSelf.currentPage = nextPage
          let oldSections = strongSelf.comicSections.value
          let newSections = oldSections + strongSelf.groupComicsBySection(comics)
          strongSelf.comicSections.accept(newSections)
        }
        
        strongSelf.isLoadingNextPage.accept(false)
      }, onFailure: { strongSelf, _ in
        strongSelf.isLoadingNextPage.accept(false)
      })
      .disposed(by: disposeBag)
  }
}

extension ComicCategoryViewModel {
  private func groupComicsBySection(_ comics: [ComicInfo]) -> [ComicInfoSection] {
    var comics: [ComicInfo] = comics.reversed()
    var sections = [ComicInfoSection]()
    
    for row in (0..<3) {
      let identity = "\(currentPage)-\(row)"
      var section = ComicInfoSection(identity: identity,
                                     items: [])
      
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
    let comicInfo = comicSections.value[indexPath.section].items[indexPath.row]
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
  public func categoryItem(_ indexPath: IndexPath) -> ComicCategory {
    return comicCategories.value[indexPath.section]
  }
}

extension ComicCategoryViewModel {
  public func categoryItemSelectAction(_ indexPath: IndexPath) {
    let category = comicCategories.value[indexPath.row]
    if selectedCategory.value == category { return }
    
    selectedCategory.accept(category)
    currentPage = 1
    
    if indexPath.row == 0 {
      updateComicCategory()
    } else {
      updateComicCategory(category)
    }
  }
}

extension ComicCategoryViewModel {
  public var amountOfComicSection: Int {
    return comicSections.value.count
  }
}
