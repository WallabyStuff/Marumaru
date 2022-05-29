//
//  TabBarController.swift
//  Marumaru
//
//  Created by 이승기 on 2022/05/23.
//

import UIKit

enum TabBarItem: CaseIterable {
    case main
    case search
    case category
    case bookMark
    
    var title: String {
        switch self {
        case .main:
            return "홈"
        case .search:
            return "검색"
        case .category:
            return "카테고리"
        case .bookMark:
            return "북마크"
        }
    }
    
    var image: UIImage {
        switch self {
        case .main:
            return R.image.tabbarHome()!
        case .search:
            return R.image.tabbarMagnifyingGlass()!
        case .category:
            return R.image.tabbarCategory()!
        case .bookMark:
            return R.image.tabbarBookmark()!
        }
    }
    
    var selectedImage: UIImage {
        switch self {
        case .main:
            return R.image.tabbarHomeFilled()!
        case .search:
            return R.image.tabbarMagnifyingGlassFilled()!
        case .category:
            return R.image.tabbarCategoryFilled()!
        case .bookMark:
            return R.image.tabbarBookmarkFilled()!
        }
    }
}

class MainTabBarController: UITabBarController {
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        setupViewControllers()
        setupTabBarItems()
    }
    
    private func setupViewControllers() {
        setViewControllers([mainViewController, searchViewController, comingSoonViewController, comingSoonViewController],
                           animated: true)
    }
    
    private func setupTabBarItems() {
        guard let items = tabBar.items else { return }
        
        for (i, item) in items.enumerated() {
            let tabBarItem = TabBarItem.allCases[i]
            item.title = tabBarItem.title
            item.image = tabBarItem.image
            item.selectedImage = tabBarItem.selectedImage
        }
    }
}

extension MainTabBarController {
    private var mainViewController: UIViewController {
        let storyboard = UIStoryboard(name: R.storyboard.main.name, bundle: nil)
        let viewController = storyboard.instantiateViewController(identifier: MainViewController.identifier,
                                                                  creator: { coder -> MainViewController in
            let viewModel = MainViewModel()
            return .init(coder, viewModel) ?? MainViewController(.init())
        })
        
        return viewController
    }
    
    private var searchViewController: UIViewController {
        let storyboard = UIStoryboard(name: R.storyboard.searchComic.name, bundle: nil)
        let viewController = storyboard.instantiateViewController(identifier: SearchComicViewController.identifier,
                                                                  creator: { coder -> SearchComicViewController in
            let viewModel = SearchComicViewModel()
            return .init(coder, viewModel) ?? SearchComicViewController(.init())
        })
        
        return viewController
    }
    
    private var comingSoonViewController: UIViewController {
        let viewController = ComingSoonViewController()
        return viewController
    }
}
