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
    @IBOutlet weak var searchResultCollectionView: UICollectionView!
    @IBOutlet weak var searchButton: UIButton!
    
    static let identifier = R.storyboard.searchComic.searchComicStoryboard.identifier
    var viewModel: ViewModel
    private var isSearching = false
    private var searchResultPlaceholderLabel = StickyPlaceholderLabel()
    
    
    // MARK: - Initializers
    
    required init(_ viewModel: SearchComicViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        dismiss(animated: true)
    }
    
    required init?(_ coder: NSCoder, _ viewModel: SearchComicViewModel) {
        self.viewModel = viewModel
        super.init(coder: coder)
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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
    }
    
    
    // MARK: - Overrides
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        configureAppbarViewConstraints()
        configureSearchResultTableViewInsets()
    }
    
    
    // MARK: - Setup
    
    private func setup() {
        setupView()
    }
    
    private func setupView() {
        setupSearchTextField()
        setupSearchResultCollectionView()
        setupSearchButton()
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
    
    private func setupSearchResultCollectionView() {
        let nibName = UINib(nibName: SearchResultComicCollectionCell.identifier, bundle: nil)
        searchResultCollectionView.register(nibName,
                                            forCellWithReuseIdentifier: SearchResultComicCollectionCell.identifier)
        searchResultCollectionView.delegate = self
        searchResultCollectionView.dataSource = self
        searchResultCollectionView.keyboardDismissMode = .onDrag
        searchResultCollectionView.contentInset = UIEdgeInsets(top: compactAppbarHeight,
                                                               left: 12,
                                                               bottom: compactAppbarHeight,
                                                               right: 12)
        
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.minimumLineSpacing = 16
        flowLayout.itemSize = CGSize(width: view.frame.width - 24, height: 128)
        searchResultCollectionView.collectionViewLayout = flowLayout
        
        viewModel.reloadSearchResultTableView = { [weak self] in
            self?.searchResultCollectionView.reloadData()
        }
    }
    
    private func setupSearchButton() {
        searchButton.rx.tap
            .asDriver()
            .drive(with: self, onNext: { vc, _ in
                vc.searchComic()
            }).disposed(by: disposeBag)
    }
    
    
    // MARK: - Constraints
    
    private func configureAppbarViewConstraints() {
        appbarViewHeightConstraint.constant = view.safeAreaInsets.top + regularAppbarHeight
    }
    
    private func configureSearchResultTableViewInsets() {
        searchResultCollectionView.contentInset = UIEdgeInsets(top: regularAppbarHeight + 12,
                                                          left: 0, bottom: 40, right: 0)
    }
    
    
    // MARK: - Bind
    
    private func bind() {
        bindBackButton()
        bindSearchResultCell()
        bindSearchResultTableViewScroll()
    }
    
    private func bindBackButton() {
        backButton.rx.tap
            .asDriver()
            .drive(with: self, onNext: { vc, _ in
                vc.adaptiveDismiss(animated: true)
            }).disposed(by: disposeBag)
    }
    
    private func bindSearchResultCell() {
        searchResultCollectionView.rx.itemSelected
            .asDriver()
            .drive(with: self, onNext: { vc, indexPath in
                let comicInfo = vc.viewModel.cellItemForRow(at: indexPath)
                vc.presentComicDetailVC(comicInfo)
            }).disposed(by: disposeBag)
    }
    
    private func bindSearchResultTableViewScroll() {
        searchResultCollectionView.rx.willBeginDragging
            .asDriver()
            .drive(onNext: { [weak self] in
                self?.view.endEditing(true)
            }).disposed(by: disposeBag)
    }
    
    
    // MARK: - Methods
    
    private func searchComic() {
        if let title = searchTextField.text?.trimmingCharacters(in: .whitespaces) {
            if isSearching {
                self.view.makeToast("검색중입니다.")
            } else {
                setSearchResult(title: title)
            }
        }
    }
    
    private func setSearchResult(title: String) {
        if title.count < 1 {
            self.view.stopLottie()
            self.view.makeToast("최소 한 글자 이상의 단어로 검색해주세요")
            return
        }
        
        isSearching = true
        searchResultPlaceholderLabel.detatchLabel()
        self.view.playLottie(animation: .loading_cat_radial)
        view.endEditing(true)
        
        viewModel.getSearchResult(title)
            .subscribe(with: self, onError: { vc, error in
                if let error = error as? SearchViewError {
                    vc.searchResultPlaceholderLabel.attatchLabel(text: error.message, to: vc.view)
                }
            }, onDisposed: { vc in
                self.view.stopLottie()
                vc.isSearching = false
            }).disposed(by: disposeBag)
    }
    
    private func presentComicDetailVC(_ comicInfo: ComicInfo) {
        let storyboard = UIStoryboard(name: R.storyboard.comicDetail.name, bundle: nil)
        let comicDetailVC = storyboard.instantiateViewController(identifier: ComicDetailViewController.identifier,
                                                             creator: { coder -> ComicDetailViewController in
            let viewModel = ComicDetailViewModel()
            return .init(coder, viewModel) ?? ComicDetailViewController(.init())
        })
        
        comicDetailVC.currentComic = comicInfo
        present(comicDetailVC, animated: true, completion: nil)
    }
    
    private func focusSearchTextField() {
        searchTextField.becomeFirstResponder()
    }
    
    private func adaptiveDismiss(animated: Bool) {
        if let navigationController = navigationController {
            guard let tabBarController = tabBarController else {
                navigationController.popViewController(animated: animated)
                return
            }
            
            if tabBarController.selectedIndex == 0 {
                navigationController.popViewController(animated: animated)
            } else {
                tabBarController.selectedIndex = 0
            }
        } else {
            dismiss(animated: animated)
        }
    }
}


// MARK: - Extensions

extension SearchComicViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Seach action on keyboard
        searchComic()
        return true
    }
}


extension SearchComicViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return viewModel.numberOfSection
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.numberOfRowsIn(section: section)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SearchResultComicCollectionCell.identifier, for: indexPath) as? SearchResultComicCollectionCell else {
            return UICollectionViewCell()
        }
        
        let comicInfo = viewModel.cellItemForRow(at: indexPath)
        
        cell.titleLabel.text = comicInfo.title
        cell.thumbnailImagePlaceholderLabel.text = comicInfo.title
        cell.authorLabel.text = comicInfo.author.isEmpty ? "작가정보 없음" : comicInfo.author
        cell.uploadCycleLabel.text = comicInfo.updateCycle
        
        if comicInfo.updateCycle.contains("미분류") {
            cell.uploadCycleLabel.setBackgroundHighlight(with: .systemTeal,
                                                         textColor: .white)
        } else {
            cell.uploadCycleLabel.setBackgroundHighlight(with: .systemTeal,
                                                         textColor: .white)
        }
        
        if let thumbnailImageUrl = comicInfo.thumbnailImageURL {
            let token = viewModel.requestImage(thumbnailImageUrl) { result in
                do {
                    let resultImage = try result.get()
                    DispatchQueue.main.async {
                        cell.thumbnailImagePlaceholderLabel.isHidden = true
                        cell.thumbnailImageView.image = resultImage.imageCache.image
                        cell.thumbnailImagePlaceholderView.setThumbnailShadow(with: resultImage.imageCache.averageColor.cgColor)
                        
                        if resultImage.animate {
                            cell.thumbnailImageView.startFadeInAnimation(duration: 0.3)
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        cell.thumbnailImagePlaceholderLabel.isHidden = false
                    }
                }
            }
            
            cell.onReuse = { [weak self] in
                if let token = token {
                    self?.viewModel.cancelImageRequest(token)
                }
            }
        }
        
        return cell
    }
}
