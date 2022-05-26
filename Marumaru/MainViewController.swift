//
//  MainViewController.swift
//  Marumaru
//
//  Created by 이승기 on 2021/04/06.
//

import UIKit

import Toast
import Lottie
import CoreData
import RxSwift
import RxCocoa
import RealmSwift

class MainViewController: BaseViewController, ViewModelInjectable {
    
    
    // MARK: - Properties
    
    typealias ViewModel = MainViewModel
    
    @IBOutlet weak var appbarViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var mainScrollView: UIScrollView!
    @IBOutlet weak var searchBarView: UIView!
    @IBOutlet weak var newUpdateComicContentsView: UIView!
    @IBOutlet weak var newUpdateComicCollectionView: UICollectionView!
    @IBOutlet weak var refreshNewUpdateComicButton: UIButton!
    @IBOutlet weak var watchHistoryCollectionView: UICollectionView!
    @IBOutlet weak var showWatchHistoryButton: UIButton!
    @IBOutlet weak var comicRankTableView: UITableView!
    @IBOutlet weak var refreshComicRankButton: UIButton!
    
    static let identifier = R.storyboard.main.mainStoryboard.identifier
    var viewModel: ViewModel
    private var watchHistoryPlaceholderLabel = StickyPlaceholderLabel()
    
    
    // MARK: - Initializers
    
    required init(_ viewModel: MainViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        dismiss(animated: true)
    }
    
    required init?(_ coder: NSCoder, _ viewModel: MainViewModel) {
        self.viewModel = viewModel
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("ViewModel has not been implemented")
    }
    
    
    // MARK: - Overrides
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        configureAppbarViewConstraints()
        configureMainContentViewInsets()
    }
    
    
    // MARK: - LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        bind()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
    }
    
    
    // MARK: - Setups
    
    private func setup() {
        setupData()
        setupView()
    }
    
    private func setupData() {
        viewModel.cleanCacheIfNeeded()
        reloadUpdatedComic()
        reloadWatchHistory()
        reloadComicRank()
    }
    
    private func setupView() {
        setupSearchBarView()
        setupRefreshNewUpdatedComicButton()
        setupUpdatedComicCollectionView()
        setupWatchHistoryCollectionView()
        setupTopRankComicTableView()
    }
    
    private func setupSearchBarView() {
        searchBarView.layer.cornerRadius = 12
    }
    
    private func setupRefreshNewUpdatedComicButton() {
        refreshNewUpdateComicButton.imageEdgeInsets(with: 6)
        refreshComicRankButton.imageEdgeInsets(with: 6)
    }
    
    private func setupUpdatedComicCollectionView() {
        let nibName = UINib(nibName: ComicThumbnailCollectionCell.identifier, bundle: nil)
        newUpdateComicCollectionView.register(nibName, forCellWithReuseIdentifier: ComicThumbnailCollectionCell.identifier)
        newUpdateComicCollectionView.clipsToBounds = false
        newUpdateComicCollectionView.delegate = self
        newUpdateComicCollectionView.dataSource = self
        newUpdateComicCollectionView.contentInset = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        
        viewModel.reloadUpdatedContentCollectionView = { [weak self] in
            DispatchQueue.main.async {
                self?.newUpdateComicCollectionView.reloadData()
            }
        }
    }
    
    private func setupWatchHistoryCollectionView() {
        let nibName = UINib(nibName: ComicThumbnailCollectionCell.identifier, bundle: nil)
        watchHistoryCollectionView.register(nibName, forCellWithReuseIdentifier: ComicThumbnailCollectionCell.identifier)
        watchHistoryCollectionView.clipsToBounds = false
        watchHistoryCollectionView.delegate = self
        watchHistoryCollectionView.dataSource = self
        watchHistoryCollectionView.contentInset = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        
        viewModel.reloadWatchHistoryCollectionView = { [weak self] in
            DispatchQueue.main.async {
                self?.watchHistoryCollectionView.reloadData()
            }
        }
    }
    
    private func setupTopRankComicTableView() {
        let nibName = UINib(nibName: ComicRankTableCell.identifier, bundle: nil)
        comicRankTableView.register(nibName, forCellReuseIdentifier: ComicRankTableCell.identifier)
        
        comicRankTableView.layer.cornerRadius = 12
        comicRankTableView.layer.masksToBounds = true
        
        comicRankTableView.delegate = self
        comicRankTableView.dataSource = self
        
        viewModel.reloadTopRankTableView = { [weak self] in
            DispatchQueue.main.async {
                self?.comicRankTableView.reloadData()
            }
        }
    }
    
        
    // MARK: - Constraints
    
    private func configureAppbarViewConstraints() {
        appbarViewHeightConstraint.constant = view.safeAreaInsets.top + regularAppbarHeight
    }
    
    private func configureMainContentViewInsets() {
        mainScrollView.contentInset = UIEdgeInsets(top: regularAppbarHeight + 24,
                                                   left: 0,
                                                   bottom: 0,
                                                   right: 0)
    }
    
    
    // MARK: - Binds
    
    private func bind() {
        bindSearchButton()
        bindRefreshUpdatedContentButton()
        bindShowWatchHistoryButton()
        bindRefreshComicRankButton()
        bindComicRankCell()
    }
    
    private func bindSearchButton() {
        searchBarView.rx.tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] _ in
                self?.presentSearchComicVC()
            })
            .disposed(by: disposeBag)
    }
    
    private func bindShowWatchHistoryButton() {
        showWatchHistoryButton.rx.tap
            .asDriver()
            .drive(onNext: { [weak self] _ in
                self?.presentWatchHistoryVC()
            })
            .disposed(by: disposeBag)
    }
    
    private func bindRefreshUpdatedContentButton() {
        refreshNewUpdateComicButton.rx.tap
            .asDriver()
            .debounce(.milliseconds(300))
            .drive(with: self, onNext: { vc, _  in
                vc.reloadUpdatedComic()
            })
            .disposed(by: disposeBag)
    }
    
    private func bindRefreshComicRankButton() {
        refreshComicRankButton.rx.tap
            .asDriver()
            .debounce(.milliseconds(300))
            .drive(with: self, onNext: { vc, _ in
                vc.reloadComicRank()
            })
            .disposed(by: disposeBag)
    }
    
    private func bindComicRankCell() {
        comicRankTableView.rx.itemSelected
            .asDriver()
            .drive(with: self, onNext: { vc, indexPath in
                let mangaInfo = vc.viewModel.topRankCellItemForRow(at: indexPath)
                vc.presentComicStripVC(mangaInfo.title, mangaInfo.link)
            }).disposed(by: disposeBag)
    }
    
    
    // MARK: - Methods
    
    func reloadUpdatedComic() {
        newUpdateComicCollectionView.playLottie()
        
        viewModel.getUpdatedContents()
            .subscribe(with: self, onCompleted: { vc in
                vc.newUpdateComicCollectionView.stopLottie()
            }).disposed(by: disposeBag)
    }
    
    func reloadWatchHistory() {
        watchHistoryPlaceholderLabel.detatchLabel()
        
        viewModel.getWatchHistories()
            .subscribe(with: self, onError: { vc, error in
                if let error = error as? MainViewError {
                    vc.watchHistoryPlaceholderLabel.attatchLabel(text: error.message,
                                                                 to: vc.watchHistoryCollectionView)
                }
            })
            .disposed(by: disposeBag)
    }
    
    func reloadComicRank() {
        comicRankTableView.playLottie()
        
        viewModel.getTopRankedComics()
            .subscribe(with: self, onCompleted: { vc in
                vc.comicRankTableView.stopLottie()
            }).disposed(by: disposeBag)
    }
    
    func presentComicStripVC(_ mangaTitle: String, _ mangaUrl: String) {
        let storyboard = UIStoryboard(name: R.storyboard.comicStrip.name, bundle: nil)
        let comicStripVC = storyboard.instantiateViewController(identifier: ComicStripViewController.identifier,
                                                                creator: { coder -> ComicStripViewController in
            let viewModel = ComicStripViewModel(comicTitle: mangaTitle, comicURL: mangaUrl)
            return .init(coder, viewModel) ?? ComicStripViewController(.init(comicTitle: "", comicURL: ""))
        })
        
        comicStripVC.delegate = self
        comicStripVC.modalPresentationStyle = .fullScreen
        navigationController?.pushViewController(comicStripVC, animated: true)
    }
    
    func presentSearchComicVC() {
        let storyboard = UIStoryboard(name: R.storyboard.searchComic.name, bundle: nil)
        let searchComicVC = storyboard.instantiateViewController(identifier: SearchComicViewController.identifier,
                                                                 creator: { coder -> SearchComicViewController in
            let viewModel = SearchComicViewModel()
            return .init(coder, viewModel) ?? SearchComicViewController(.init())
        })
        
        searchComicVC.modalPresentationStyle = .fullScreen
        navigationController?.pushViewController(searchComicVC, animated: true)
    }
    
    func presentWatchHistoryVC() {
        let storyboard = UIStoryboard(name: R.storyboard.watchHistory.name, bundle: nil)
        let watchHistoryVC = storyboard.instantiateViewController(identifier: WatchHistoryViewController.identifier,
                                                                  creator: { coder -> WatchHistoryViewController in
            let viewModel = WatchHistoryViewModel()
            return .init(coder, viewModel) ?? WatchHistoryViewController(.init())
        })
        
        watchHistoryVC.delegate = self
        watchHistoryVC.modalPresentationStyle = .fullScreen
        navigationController?.pushViewController(watchHistoryVC, animated: true)
    }
}


// MARK: - Extensions

extension MainViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if collectionView == newUpdateComicCollectionView {
            return viewModel.updatedContentsNumberOfItem
        } else {
            return viewModel.watchHistoriesNumberOfItem
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let mangaCollectionCell = collectionView.dequeueReusableCell(withReuseIdentifier: ComicThumbnailCollectionCell.identifier,
                                                                           for: indexPath) as? ComicThumbnailCollectionCell else {
            return UICollectionViewCell()
        }
        
        let mangaInfo = collectionView == newUpdateComicCollectionView ? viewModel.updatedContentCellItemForRow(at: indexPath) : viewModel.watchHistoryCellItemForRow(at: indexPath)
        
        mangaCollectionCell.titleLabel.text = mangaInfo.title
        mangaCollectionCell.thumbnailImagePlaceholderLabel.text = mangaInfo.title
        
        if let thumbnailImageUrl = mangaInfo.thumbnailImageUrl {
            let token = viewModel.requestImage(thumbnailImageUrl) { result in
                do {
                    let resultImage = try result.get()
                    DispatchQueue.main.async {
                        mangaCollectionCell.thumbnailImageView.image = resultImage.imageCache.image
                        mangaCollectionCell.thumbnailImagePlaceholderLabel.isHidden = true
                        mangaCollectionCell.thumbnailImageBaseView.setThumbnailShadow(with: resultImage.imageCache.averageColor.cgColor)
                        
                        if resultImage.animate {
                            mangaCollectionCell.thumbnailImageView.startFadeInAnimation(duration: 0.5, nil)
                        }
                    }
                } catch {
                    mangaCollectionCell.thumbnailImagePlaceholderLabel.isHidden = false
                }
            }
            
            mangaCollectionCell.onReuse = { [weak self] in
                if let token = token {
                    self?.viewModel.cancelImageRequest(token)
                }
            }
        }
        
        return mangaCollectionCell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let mangaInfo = collectionView == newUpdateComicCollectionView ? viewModel.updatedContentCellItemForRow(at: indexPath) : viewModel.watchHistoryCellItemForRow(at: indexPath)
        
        presentComicStripVC(mangaInfo.title, mangaInfo.link)
    }
}

extension MainViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.topRankNumberOfItemsInSection(section: 0)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let rankCell = tableView.dequeueReusableCell(withIdentifier: ComicRankTableCell.identifier, for: indexPath) as? ComicRankTableCell else { return UITableViewCell() }
        
        let comicInfo = viewModel.topRankCellItemForRow(at: indexPath)
        rankCell.titleLabel.text = comicInfo.title
        rankCell.rankLabel.text = viewModel.topRankCellRank(indexPath: indexPath).description
        return rankCell
    }
}

extension MainViewController: WatchHistoryViewDelegate, ComicStripViewDelegate {
    func didWatchHistoryUpdated() {
        reloadWatchHistory()
    }
}
