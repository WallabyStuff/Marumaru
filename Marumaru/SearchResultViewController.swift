//
//  SearchResultViewController.swift
//  Marumaru
//
//  Created by 이승기 on 2022/05/29.
//

import UIKit

protocol SearchResultViewDelegate: AnyObject {
    func didSelectedComicItem(_ comicInfo: ComicInfo)
    func didSearchResultCollectionViewScrolled()
}

class SearchResultViewController: BaseViewController, ViewModelInjectable {

    
    // MARK: - Properties
    
    typealias ViewModel = SearchResultViewModel
    static let identifier = R.storyboard.searchResult.searchResultStoryboard.identifier
    
    @IBOutlet weak var searchResultCollectionView: UICollectionView!
    
    weak var delegate: SearchResultViewDelegate?
    var viewModel: ViewModel
    private var searchResultCollectionViewTopInset: CGFloat {
        return regularAppbarHeight + 12
    }
    private var actualSearchResultCollectionViewTopInset: CGFloat {
        return searchResultCollectionViewTopInset + view.safeAreaInsets.top
    }
    
    
    // MARK: - LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        bind()
    }
    
    
    // MARK: - Initializers
    
    required init(_ viewModel: SearchResultViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        dismiss(animated: true)
    }
    
    required init?(_ coder: NSCoder, _ viewModel: SearchResultViewModel) {
        self.viewModel = viewModel
        super.init(coder: coder)
    }
    
    required init(coder: NSCoder) {
        fatalError("ViewModel has not been implemented")
    }
    
    
    // MARK: - Setups
    
    private func setup() {
        setupView()
    }
    
    private func setupView() {
        setupSearchResultCollectionView()
    }
    
    private func setupSearchResultCollectionView() {
        let nibName = UINib(nibName: SearchResultComicCollectionCell.identifier, bundle: nil)
        searchResultCollectionView.register(nibName,
                                            forCellWithReuseIdentifier: SearchResultComicCollectionCell.identifier)
        searchResultCollectionView.keyboardDismissMode = .onDrag
        
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.minimumLineSpacing = 16
        flowLayout.itemSize = CGSize(width: view.frame.width - 24, height: 128)
        searchResultCollectionView.collectionViewLayout = flowLayout
        searchResultCollectionView.clipsToBounds = false
        searchResultCollectionView.alwaysBounceVertical = true
        configureSearchResultCollectionViewInsets()
    }
    
    
    // MARK: - Constraints
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        configureSearchResultCollectionViewInsets()
    }
    
    private func configureSearchResultCollectionViewInsets() {
        searchResultCollectionView.contentInset = UIEdgeInsets(top: searchResultCollectionViewTopInset,
                                                               left: 0, bottom: 40, right: 0)
    }
    
    
    // MARK: - Binds
    
    private func bind() {
        bindSearchResultComicCollectionView()
        bindSearchResultComicCollectionCell()
        bindSearchResultComicLoadingState()
        bindSearchResultComicFailState()
        bindSearchResultComicCollectionViewScrollAction()
    }
    
    private func bindSearchResultComicCollectionView() {
        viewModel.searchResultComicsObservable
            .bind(to: searchResultCollectionView.rx.items(cellIdentifier: SearchResultComicCollectionCell.identifier,
                                                          cellType: SearchResultComicCollectionCell.self)) { _, comicInfo, cell in
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
                    let url = URL(string: thumbnailImageUrl)
                    cell.thumbnailImageView.kf.setImage(with: url, options: [.transition(.fade(0.3))]) { result in
                        do {
                            let result = try result.get()
                            let image = result.image
                            cell.thumbnailImagePlaceholderView.setThumbnailShadow(with: image.averageColor)
                            cell.thumbnailImagePlaceholderLabel.isHidden = true
                        } catch {
                            cell.thumbnailImagePlaceholderLabel.isHidden = false
                        }
                    }
                }
            }.disposed(by: disposeBag)
        
        viewModel.searchResultComicsObservable
            .subscribe(with: self, onNext: { vc, comics in
                if comics.isEmpty {
                    vc.searchResultCollectionView.heightAnchor.constraint(equalToConstant: vc.view.frame.height).isActive = true
                    vc.view.makeNoticeLabel("message.emptyResult".localized())
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
                vc.viewModel.selectComicItem(indexPath)
            })
            .disposed(by: disposeBag)
        
        viewModel.presentComicDetailVC
            .subscribe(with: self, onNext: { vc, comicInfo in
                vc.delegate?.didSelectedComicItem(comicInfo)
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
                    vc.makeHapticFeedback()
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
                    vc.view.makeNoticeLabel("message.serverError".localized())
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
                vc.delegate?.didSearchResultCollectionViewScrolled()
            }).disposed(by: disposeBag)
    }
    
    
    // MARK: - Methods
    
    public func updateSearchResult(_ title: String) {
        searchResultCollectionView.scrollToTop(topInset: actualSearchResultCollectionViewTopInset,
                                               animated: false)
        viewModel.updateSearchResult(title)
    }
}
