//
//  SearchComicViewController.swift
//  Marumaru
//
//  Created by 이승기 on 2021/04/12.
//

import UIKit

import Lottie
import RxSwift
import RxCocoa

class SearchComicViewController: BaseViewController, ViewModelInjectable {
        
    
    // MARK: - Properties
    
    typealias ViewModel = SearchComicViewModel
    
    @IBOutlet weak var appbarViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var mainContainerView: UIView!
    private var searchHistoryVC: SearchHistoryViewController?
    private var searchResultVC: SearchResultViewController?
    
    static let identifier = R.storyboard.searchComic.searchComicStoryboard.identifier
    var viewModel: ViewModel
    
    enum ContentType {
        case searchHistory
        case searchResult
    }
    
    
    // MARK: - Initializers
    
    required init(_ viewModel: SearchComicViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        dismiss(animated: true)
    }
    
    required init?(_ coder: NSCoder, _ viewModel: SearchComicViewModel) {
        self.viewModel = viewModel
        super.init(coder: coder)
        
        self.searchHistoryVC = configureSearchHistoryVC()
        self.searchResultVC = configureSearchResultVC()
    }
    
    required init?(coder: NSCoder) {
        fatalError("ViewModel has not been implemented")
    }
    
    
    // MARK: - LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        bind()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        focusSearchTextField()
        navigationController?.navigationBar.isHidden = true
    }
    
    
    // MARK: - Setup
    
    private func setup() {
        setupView()
    }
    
    private func setupView() {
        setupSearchTextField()
        setupSearchButton()
        setupWatchHistoryViewController()
        setupSearchResultViewController()
    }
    
    private func setupSearchTextField() {
        searchTextField.layer.cornerRadius = 12
        
        let leftPaddingView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: searchTextField.frame.height))
        searchTextField.leftView = leftPaddingView
        searchTextField.leftViewMode = .always
        
        let rightPaddingView = UIView(frame: CGRect(x: 0, y: 0, width: 48, height: searchTextField.frame.height))
        searchTextField.rightView = rightPaddingView
        searchTextField.rightViewMode = .always
        searchTextField.returnKeyType = .search
        searchTextField.delegate = self
        searchTextField.becomeFirstResponder()
    }
    

    private func setupSearchButton() {
        searchButton.rx.tap
            .asDriver()
            .drive(with: self, onNext: { vc, _ in
                vc.setSearchResult()
            }).disposed(by: disposeBag)
    }
    
    private func setupWatchHistoryViewController() {
        guard let searchHistoryVC = searchHistoryVC else {
            return
        }

        addChild(searchHistoryVC)
        mainContainerView.addSubview(searchHistoryVC.view)
        searchHistoryVC.didMove(toParent: self)
        searchHistoryVC.view.frame = mainContainerView.bounds
        searchHistoryVC.view.isHidden = false
    }
    
    private func setupSearchResultViewController() {
        guard let searchResultVC = searchResultVC else {
            return
        }

        addChild(searchResultVC)
        mainContainerView.addSubview(searchResultVC.view)
        searchResultVC.didMove(toParent: self)
        searchResultVC.view.frame = mainContainerView.bounds
        searchResultVC.view.isHidden = true
    }
    
    
    // MARK: - Constraints
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        configureAppbarViewConstraints()
    }
    
    private func configureAppbarViewConstraints() {
        appbarViewHeightConstraint.constant = view.safeAreaInsets.top + regularAppbarHeight
    }
    

    
    // MARK: - Bind
    
    private func bind() {
        bindBackButton()
        bindSearchTextField()
    }
    
    private func bindBackButton() {
        backButton.rx.tap
            .asDriver()
            .drive(with: self, onNext: { vc, _ in
                vc.adaptiveDismiss(animated: true)
            }).disposed(by: disposeBag)
    }
    
    private func bindSearchTextField() {
        searchTextField.rx.text
            .asDriver()
            .drive(with: self, onNext: { vc, text in
                if text == nil || text?.count == 0 {
                    if vc.searchResultVC?.view.isHidden == false {
                        vc.switchContentView(.searchHistory)
                    }
                }
            })
            .disposed(by: disposeBag)
    }
  
    
    // MARK: - Methods
    
    private func presentComicDetailVC(_ comicInfo: ComicInfo) {
        let storyboard = UIStoryboard(name: R.storyboard.comicDetail.name, bundle: nil)
        let comicDetailVC = storyboard.instantiateViewController(identifier: ComicDetailViewController.identifier,
                                                             creator: { coder -> ComicDetailViewController in
            let viewModel = ComicDetailViewModel(comicInfo: comicInfo)
            return .init(coder, viewModel) ?? ComicDetailViewController(.init())
        })
        
        present(comicDetailVC, animated: true, completion: nil)
    }
    
    private func focusSearchTextField() {
        searchTextField.becomeFirstResponder()
    }
    
    private func adaptiveDismiss(animated: Bool) {
        if let tabbarController = tabBarController {
            tabbarController.selectedIndex = 0
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
    
    private func setSearchResult() {
        guard let title = searchTextField.text?.trimmingCharacters(in: .whitespaces) else {
            return
        }
        
        if title.count <= 1 {
            self.view.stopLottie()
            self.view.makeToast("message.searchKeywordConstraint".localized())
            return
        }
        
        view.endEditing(true)
        viewModel.addSearchHistory(title)
        switchContentView(.searchResult)
        searchResultVC?.updateSearchResult(title)
    }
    
    private func configureSearchHistoryVC() -> SearchHistoryViewController {
        let storyboard = UIStoryboard(name: R.storyboard.searchHistory.name,
                                      bundle: nil)
        let viewController = storyboard.instantiateViewController(identifier: SearchHistoryViewController.identifier, creator: { coder -> SearchHistoryViewController in
            let viewModel = SearchHistoryViewModel()
            return .init(coder, viewModel) ?? SearchHistoryViewController(viewModel)
        })
        
        viewController.delegate = self
        return viewController
    }
    
    private func configureSearchResultVC() -> SearchResultViewController {
        let storyboard = UIStoryboard(name: R.storyboard.searchResult.name,
                                      bundle: nil)
        let viewController = storyboard.instantiateViewController(identifier: SearchResultViewController.identifier, creator: { coder -> SearchResultViewController in
            let viewModel = SearchResultViewModel()
            return .init(coder, viewModel) ?? SearchResultViewController(viewModel)
        })
        
        viewController.delegate = self
        return viewController
    }
    
    private func switchContentView(_ contentType: ContentType) {
        guard let searchHistoryVC = searchHistoryVC,
              let searchResultVC = searchResultVC else {
            return
        }
        
        if contentType == .searchHistory {
            searchHistoryVC.view.isHidden = false
            searchResultVC.view.isHidden = true
            searchHistoryVC.viewModel.updateSearchHistory()
        } else {
            searchHistoryVC.view.isHidden = true
            searchResultVC.view.isHidden = false
        }
    }
}


// MARK: - Extensions

extension SearchComicViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Seach action on keyboard
        setSearchResult()
        return true
    }
}

extension SearchComicViewController: SearchHistoryViewDelegate {
    func didSelectedSearchHistory(title: String) {
        searchTextField.text = title
        setSearchResult()
    }
    
    func didHistoryCollectionViewViewScrolled() {
        view.endEditing(true)
    }
}

extension SearchComicViewController: SearchResultViewDelegate {
    func didSelectedComicItem(_ comicInfo: ComicInfo) {
        presentComicDetailVC(comicInfo)
    }
    
    func didSearchResultCollectionViewScrolled() {
        view.endEditing(true)
    }
}
