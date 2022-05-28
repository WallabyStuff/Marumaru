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
        searchResultCollectionView.keyboardDismissMode = .onDrag
        searchResultCollectionView.contentInset = UIEdgeInsets(top: 12,
                                                               left: 12,
                                                               bottom: compactAppbarHeight,
                                                               right: 12)
        
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.minimumLineSpacing = 16
        flowLayout.itemSize = CGSize(width: view.frame.width - 24, height: 128)
        searchResultCollectionView.collectionViewLayout = flowLayout
    }
    
    private func setupSearchButton() {
        searchButton.rx.tap
            .asDriver()
            .drive(with: self, onNext: { vc, _ in
                vc.updateSearchResult()
            }).disposed(by: disposeBag)
    }
    
    
    // MARK: - Constraints
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        configureAppbarViewConstraints()
        configureSearchResultTableViewInsets()
    }
    
    private func configureAppbarViewConstraints() {
        appbarViewHeightConstraint.constant = view.safeAreaInsets.top + regularAppbarHeight
    }
    
    private func configureSearchResultTableViewInsets() {
        searchResultCollectionView.contentInset = UIEdgeInsets(top: 12,
                                                          left: 0, bottom: 40, right: 0)
    }
    
    
    // MARK: - Bind
    
    private func bind() {
        bindBackButton()
        
        bindSearchResultComicCollectionView()
        bindSearchResultComicCollectionCell()
        bindSearchResultComicLoadingState()
        bindSearchResultComicFailState()
        bindSearchResultComicCollectionViewScrollAction()
    }
    
    private func bindBackButton() {
        backButton.rx.tap
            .asDriver()
            .drive(with: self, onNext: { vc, _ in
                vc.adaptiveDismiss(animated: true)
            }).disposed(by: disposeBag)
    }
    
    private func bindSearchResultComicCollectionView() {
        viewModel.searchResultComicsObservable
            .bind(to: searchResultCollectionView.rx.items(cellIdentifier: SearchResultComicCollectionCell.identifier,
                                                          cellType: SearchResultComicCollectionCell.self)) { [weak self] _, comicInfo, cell in
                guard let self = self else { return }
                
                cell.hideSkeleton()
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
                    let token = self.viewModel.requestImage(thumbnailImageUrl) { result in
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
                            cell.thumbnailImagePlaceholderLabel.isHidden = false
                            self?.viewModel.cancelImageRequest(token)
                        }
                    }
                }
            }.disposed(by: disposeBag)
        
        viewModel.searchResultComicsObservable
            .subscribe(with: self, onNext: { vc, comics in
                if comics.isEmpty {
                    vc.searchResultCollectionView.heightAnchor.constraint(equalToConstant: vc.view.frame.height).isActive = true
                    vc.view.makeNoticeLabel("검색결과가 없습니다.")
                } else {
                    vc.view.removeNoticeLabels()
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func bindSearchResultComicCollectionCell() {
        searchResultCollectionView.rx.itemSelected
            .asDriver()
            .drive(with: self, onNext: { vc, indexPath in
                vc.viewModel.comicItemSelected(indexPath)
            })
            .disposed(by: disposeBag)
        
        viewModel.presentComicDetailVC
            .subscribe(with: self, onNext: { vc, comicInfo in
                vc.presentComicDetailVC(comicInfo)
            })
            .disposed(by: disposeBag)
    }
    
    private func bindSearchResultComicLoadingState() {
        viewModel.isLoadingSearchResultComics
            .subscribe(with: self, onNext: { vc, isLoading in
                vc.searchResultCollectionView.layoutIfNeeded()
                
                if isLoading {
                    vc.searchResultCollectionView.isUserInteractionEnabled = false
                    vc.searchResultCollectionView.visibleCells.forEach { cell in
                        cell.showCustomSkeleton()
                    }
                } else {
                    vc.searchResultCollectionView.isUserInteractionEnabled = true
                    vc.searchResultCollectionView.visibleCells.forEach { cell in
                        cell.hideSkeleton()
                    }
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func bindSearchResultComicFailState() {
        viewModel.failToLoadSearchResult
            .subscribe(with: self, onNext: { vc, isFailed in
                if isFailed {
                    vc.view.makeNoticeLabel("🛠서버 점검중입니다.\n나중에 다시 시도해주세요")
                } else {
                    vc.view.removeNoticeLabels()
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func bindSearchResultComicCollectionViewScrollAction() {
        searchResultCollectionView.rx.willBeginDragging
            .asDriver()
            .drive(with: self, onNext: { vc, _ in
                vc.view.endEditing(true)
            }).disposed(by: disposeBag)
    }
    
    
    // MARK: - Methods
    
    private func updateSearchResult() {
        guard let searchKeyword = searchTextField.text else {
            return
        }
        
        if searchKeyword.count <= 1 {
            self.view.stopLottie()
            self.view.makeToast("최소 두 글자 이상의 단어로 검색해주세요")
            return
        }
        
        view.endEditing(true)
        searchResultCollectionView.scrollToTop(topInset: 12, animated: false)
        viewModel.updateSearchResult(searchKeyword)
    }
    
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
        updateSearchResult()
        return true
    }
}
