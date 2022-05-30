//
//  SearchHistoryViewController.swift
//  Marumaru
//
//  Created by 이승기 on 2022/05/29.
//

import UIKit

protocol SearchHistoryViewDelegate: AnyObject {
    func didSelectedSearchHistory(title: String)
    func didHistoryCollectionViewViewScrolled()
}

class SearchHistoryViewController: BaseViewController, ViewModelInjectable {
    
    
    // MARK: - Properties
    
    typealias ViewModel = SearchHistoryViewModel
    static let identifier = R.storyboard.searchHistory.searchHistoryStoryboard.identifier
    
    @IBOutlet weak var searchHistoryCollectionView: UICollectionView!
    
    weak var delegate: SearchHistoryViewDelegate?
    var viewModel: SearchHistoryViewModel
    private var searchResultCollectionViewTopInset: CGFloat {
        return regularAppbarHeight + 28
    }
    
    
    // MARK: - Initializers
    
    required init(_ viewModel: SearchHistoryViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        dismiss(animated: true)
    }
    
    required init?(_ coder: NSCoder, _ viewModel: SearchHistoryViewModel) {
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
    
    // MARK: - Setups

    private func setup() {
        setupData()
        setupView()
    }
    
    private func setupData() {
        viewModel.updateSearchHistory()
    }
    
    private func setupView() {
        setupSearchHistoryCollectionView()
    }
    
    private func setupSearchHistoryCollectionView() {
        let nibName = UINib(nibName: SearchHistoryCollectionCell.identifier, bundle: nil)
        searchHistoryCollectionView.register(nibName, forCellWithReuseIdentifier: SearchHistoryCollectionCell.identifier)
        
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.minimumLineSpacing = 20
        flowLayout.itemSize = CGSize(width: view.frame.width, height: 36)
        searchHistoryCollectionView.collectionViewLayout = flowLayout
        searchHistoryCollectionView.clipsToBounds = false
        searchHistoryCollectionView.alwaysBounceVertical = true
        configureSearchHistoryCollectionViewInsets()
    }
    
    
    // MARK: - Constraints
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        configureSearchHistoryCollectionViewInsets()
    }
    
    private func configureSearchHistoryCollectionViewInsets() {
        searchHistoryCollectionView.contentInset = UIEdgeInsets(top: searchResultCollectionViewTopInset,
                                                               left: 0, bottom: 40, right: 0)
    }
    
    
    // MARK: - Binds
    
    private func bind() {
        bindSearchHistoryCollectionView()
        bindSearchHistoryCollectionCell()
        bindCollectionViewScrollAction()
    }
    
    private func bindSearchHistoryCollectionView() {
        viewModel.searchHistoriesObservable
            .bind(to: searchHistoryCollectionView.rx.items(cellIdentifier: SearchHistoryCollectionCell.identifier,
                                                           cellType: SearchHistoryCollectionCell.self)) { index, searchHistory, cell in
                cell.titleLabel.text = searchHistory.title
                cell.deleteButtonTapAction = { [weak self] in
                    self?.viewModel.deleteSearchHistoryItem(index)
                }
            }.disposed(by: disposeBag)
    }
    
    private func bindSearchHistoryCollectionCell() {
        searchHistoryCollectionView.rx.itemSelected
            .asDriver()
            .drive(with: self, onNext: { vc, indexPath in
                vc.viewModel.selectHistoryItem(indexPath)
            })
            .disposed(by: disposeBag)
        
        viewModel.didSelectedHistoryItem
            .subscribe(with: self, onNext: { vc, searchHistory in
                vc.delegate?.didSelectedSearchHistory(title: searchHistory.title)
            })
            .disposed(by: disposeBag)
    }
    
    private func bindCollectionViewScrollAction() {
        searchHistoryCollectionView.rx.didScroll
            .subscribe(with: self, onNext: { vc, _ in
                vc.view.endEditing(true)
                vc.delegate?.didHistoryCollectionViewViewScrolled()
            })
            .disposed(by: disposeBag)
    }
}
