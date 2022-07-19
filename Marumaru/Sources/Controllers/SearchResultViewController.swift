//
//  SearchResultViewController.swift
//  Marumaru
//
//  Created by 이승기 on 2022/05/29.
//

import UIKit
import RxDataSources

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
    private var dataSource: RxCollectionViewSectionedAnimatedDataSource<ComicInfoSection>?
    private var searchResultCollectionViewTopInset: CGFloat {
        return regularAppbarHeight
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
        self.dataSource = configureDataSource()
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
        registerSearchResultCell()
        registerSearchResultHeader()
        searchResultCollectionView.collectionViewLayout = flowLayout()
        
        searchResultCollectionView.clipsToBounds = false
        searchResultCollectionView.alwaysBounceVertical = true
        searchResultCollectionView.keyboardDismissMode = .onDrag
        configureSearchResultCollectionViewInsets()
    }
    
    private func registerSearchResultCell() {
        let nibName = UINib(nibName: R.nib.searchResultComicCollectionCell.name, bundle: nil)
        searchResultCollectionView.register(nibName, forCellWithReuseIdentifier: SearchResultComicCollectionCell.identifier)
    }
    
    private func registerSearchResultHeader() {
        let nibName = UINib(nibName: R.nib.descriptionHeaderReusableView.name, bundle: nil)
        searchResultCollectionView.register(nibName,
                                            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                            withReuseIdentifier: DescriptionHeaderReusableView.identifier)
    }
    
    
    // MARK: - Constraints
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        configureSearchResultCollectionViewInsets()
    }
    
    private func configureSearchResultCollectionViewInsets() {
        searchResultCollectionView.contentInset = UIEdgeInsets.inset(top: searchResultCollectionViewTopInset,
                                                                     bottom: 40)
    }
    
    
    // MARK: - Binds
    
    private func bind() {
        bindSearchResultComicCollectionView()
        bindSearchResultComicCollectionCell()
        bindSearchResultComicLoadingState()
        bindSearchResultComicFailState()
        bindSearchResultComicCollectionViewScrollAction()
        bindUpdateSearchResultFlowLayout()
    }
    
    private func bindSearchResultComicCollectionView() {
        guard let dataSource = dataSource else {
            return
        }

        viewModel.searchResultComics
            .bind(to: searchResultCollectionView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        
        viewModel.searchResultComics
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
                    
                    vc.searchResultCollectionView.collectionViewLayout.invalidateLayout()
                } else {
                    vc.makeSelectionFeedback()
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
    
    private func bindUpdateSearchResultFlowLayout() {
        baseFrameSizeViewSizeDidChange
            .subscribe(with: self, onNext: { strongSelf, _ in
                strongSelf.searchResultCollectionView.collectionViewLayout = strongSelf.flowLayout()
            })
            .disposed(by: disposeBag)
    }
    
    
    // MARK: - Methods
    
    public func updateSearchResult(_ title: String) {
        searchResultCollectionView.scrollToTop(topInset: actualSearchResultCollectionViewTopInset,
                                               animated: false)
        viewModel.updateSearchResult(title)
    }
    
    private func configureDataSource() -> RxCollectionViewSectionedAnimatedDataSource<ComicInfoSection> {
        let dataSource = RxCollectionViewSectionedAnimatedDataSource<ComicInfoSection>(configureCell: { _, cv, indexPath, comicInfo in
            guard let cell = cv.dequeueReusableCell(withReuseIdentifier: SearchResultComicCollectionCell.identifier, for: indexPath) as? SearchResultComicCollectionCell else {
                return UICollectionViewCell()
            }
            
            cell.configure(with: comicInfo)
            return cell
        }, configureSupplementaryView: { [weak self] _, cv, kind, indexPath in
            guard let self = self else {
                return UICollectionReusableView()
            }
            
            if kind == UICollectionView.elementKindSectionHeader {
                guard let cell = cv.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: DescriptionHeaderReusableView.identifier, for: indexPath) as? DescriptionHeaderReusableView else {
                    return UICollectionReusableView()
                }
                
                self.viewModel.isLoadingSearchResultComics
                    .subscribe(onNext: { isLoading in
                        if isLoading {
                            cell.descriptionLabel.text = "message.searching".localized()
                        } else {
                            let searchKeyword = self.viewModel.searchKeyword
                            cell.descriptionLabel.text = "\"\(searchKeyword)\"\("title.searchResultHeader".localized())"
                        }
                    })
                    .disposed(by: self.disposeBag)
                
                return cell
            } else {
                return UICollectionReusableView()
            }
        })
        
        return dataSource
    }
    
    private func flowLayout() -> UICollectionViewFlowLayout {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.minimumLineSpacing = 16
        flowLayout.itemSize = CGSize(width: view.frame.width - 24, height: 128)
        flowLayout.headerReferenceSize = CGSize(width: view.frame.width, height: 100)
        
        return flowLayout
    }
}
