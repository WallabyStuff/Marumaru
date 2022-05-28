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
    
    
    // MARK: - LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        bind()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
        viewModel.updateWatchHistories()
    }
    
    
    // MARK: - Setups
    
    private func setup() {
        setupData()
        setupView()
    }
    
    private func setupData() {
        viewModel.cleanCacheIfNeeded()
        viewModel.updateNewUpdatedComics()
        viewModel.updateComicRank()
    }
    
    private func setupView() {
        setupSearchBarView()
        setupRefreshNewUpdatedComicButton()
        setupUpdatedComicCollectionView()
        setupWatchHistoryCollectionView()
        setupComicRankTableView()
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
        newUpdateComicCollectionView.contentInset = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
    }
    
    private func setupWatchHistoryCollectionView() {
        let nibName = UINib(nibName: ComicThumbnailCollectionCell.identifier, bundle: nil)
        watchHistoryCollectionView.register(nibName, forCellWithReuseIdentifier: ComicThumbnailCollectionCell.identifier)
        watchHistoryCollectionView.clipsToBounds = false
        watchHistoryCollectionView.contentInset = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
    }
    
    private func setupComicRankTableView() {
        let nibName = UINib(nibName: ComicRankTableCell.identifier, bundle: nil)
        comicRankTableView.register(nibName, forCellReuseIdentifier: ComicRankTableCell.identifier)
        
        comicRankTableView.layer.cornerRadius = 12
        comicRankTableView.layer.masksToBounds = true
    }
    
        
    // MARK: - Constraints
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        configureAppbarViewConstraints()
        configureMainContentViewInsets()
    }
    
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
        bindShowWatchHistoryButton()
        bindRefreshNewUpdatedComicsButton()
        bindRefreshComicRankButton()
        
        bindNewUpdateComicCollectionView()
        bindNewUpdatecomicCollectionCell()
        bindNewUpdateComicLoadingState()
        bindNewUpdateFailState()
        
        bindWatchHistoryCollectionView()
        bindWatchHistoryCollectionCell()
        
        bindComicRankCollctionView()
        bindComicRankCollectionCell()
        bindComicRankLoadingLoadingState()
        bindComicRankFailState()
    }
    
    private func bindSearchButton() {
        searchBarView.rx.tapGesture()
            .when(.recognized)
            .subscribe(with: self, onNext: { vc, _ in
                vc.presentSearchComicVC()
            })
            .disposed(by: disposeBag)
    }
    
    private func bindShowWatchHistoryButton() {
        showWatchHistoryButton.rx.tap
            .asDriver()
            .drive(with: self, onNext: { vc, _ in
                vc.presentWatchHistoryVC()
            })
            .disposed(by: disposeBag)
    }
    
    private func bindRefreshNewUpdatedComicsButton() {
        refreshNewUpdateComicButton.rx.tap
            .asDriver()
            .debounce(.milliseconds(300))
            .drive(with: self, onNext: { vc, _ in
                vc.viewModel.updateNewUpdatedComics()
            })
            .disposed(by: disposeBag)
    }
    
    private func bindRefreshComicRankButton() {
        refreshComicRankButton.rx.tap
            .asDriver()
            .debounce(.milliseconds(300))
            .drive(with: self, onNext: { vc, _ in
                vc.viewModel.updateComicRank()
            })
            .disposed(by: disposeBag)
    }
    
    private func bindNewUpdateComicCollectionView() {
        viewModel.newUpdateComicsObservable
            .bind(to: newUpdateComicCollectionView.rx
                .items(cellIdentifier: ComicThumbnailCollectionCell.identifier, cellType: ComicThumbnailCollectionCell.self)) { [weak self] _, comic, cell in
                    guard let self = self else { return }
                    
                    cell.thumbnailImagePlaceholderLabel.text = comic.title
                    cell.titleLabel.text = comic.title
                    
                    if let imageURL = comic.thumbnailImageUrl {
                        let token = self.viewModel.requestImage(imageURL) { result in
                            do {
                                let image = try result.get()
                                DispatchQueue.main.async {
                                    cell.thumbnailImageView.image = image.imageCache.image
                                    cell.thumbnailImagePlaceholderLabel.isHidden = true
                                    cell.thumbnailImageBaseView.setThumbnailShadow(with: image.imageCache.averageColor.cgColor)
                                    
                                    if image.animate {
                                        cell.thumbnailImageView.startFadeInAnimation(duration: 0.5, nil)
                                    }
                                }
                            } catch {
                                cell.thumbnailImagePlaceholderLabel.isHidden = false
                            }
                        }
                        
                        cell.onReuse = { [weak self] in
                            if let token = token {
                                self?.viewModel.cancelImageRequest(token)
                            }
                        }
                    }
                }.disposed(by: disposeBag)
    }
    
    private func bindNewUpdatecomicCollectionCell() {
        newUpdateComicCollectionView.rx
            .itemSelected
            .asDriver()
            .drive(onNext: { [weak self] indexPath in
                self?.viewModel.newUpdateComicItemSelected(indexPath)
            })
            .disposed(by: disposeBag)
    }
    
    private func bindNewUpdateComicLoadingState() {
        viewModel.isLoadingNewUpdateComic
            .subscribe(onNext: { [weak self] isLoading in
                if isLoading {
                    self?.newUpdateComicCollectionView.playLottie()
                } else {
                    self?.newUpdateComicCollectionView.stopLottie()
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func bindNewUpdateFailState() {
        viewModel.failToGetNewUPdateComic
            .subscribe(onNext: { [weak self] isFailed in
                guard let self = self else { return }
                if isFailed {
                    self.newUpdateComicCollectionView.stopLottie()
                    self.newUpdateComicCollectionView.makeNoticeLabel("🛠서버 점검중입니다.\n나중에 다시 시도해주세요",
                                                                      contentInsets: self.newUpdateComicCollectionView.contentInset)
                } else {
                    self.newUpdateComicCollectionView.removeNoticeLabels()
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func bindWatchHistoryCollectionView() {
        viewModel.watchHistoriesObservable
            .bind(to: watchHistoryCollectionView.rx.items(cellIdentifier: ComicThumbnailCollectionCell.identifier,
                                                          cellType: ComicThumbnailCollectionCell.self)) { [weak self] _, comic, cell in
                guard let self = self else { return }
                cell.thumbnailImagePlaceholderLabel.text = comic.episodeTitle
                cell.titleLabel.text = comic.episodeTitle
                
                let token = self.viewModel.requestImage(comic.thumbnailImageURL) { result in
                    do {
                        let image = try result.get()
                        DispatchQueue.main.async {
                            cell.thumbnailImageView.image = image.imageCache.image
                            cell.thumbnailImagePlaceholderLabel.isHidden = true
                            cell.thumbnailImageBaseView.setThumbnailShadow(with: image.imageCache.averageColor.cgColor)
                            
                            if image.animate {
                                cell.thumbnailImageView.startFadeInAnimation(duration: 0.5, nil)
                            }
                        }
                    } catch {
                        cell.thumbnailImagePlaceholderLabel.isHidden = false
                    }
                }
                
                cell.onReuse = { [weak self] in
                    if let token = token {
                        self?.viewModel.cancelImageRequest(token)
                    }
                }
            }.disposed(by: disposeBag)
        
        viewModel.watchHistoriesObservable
            .subscribe(with: self, onNext: { vc, comics in
                if comics.isEmpty {
                    vc.watchHistoryCollectionView.makeNoticeLabel("아직 시청기록이 없습니다.",
                                                                  contentInsets: vc.watchHistoryCollectionView.contentInset)
                } else {
                    vc.watchHistoryCollectionView.removeNoticeLabels()
                }
            }).disposed(by: disposeBag)
    }
    
    private func bindWatchHistoryCollectionCell() {
        watchHistoryCollectionView.rx
            .itemSelected
            .asDriver()
            .drive(onNext: { [weak self] indexPath in
                self?.viewModel.watchHistoryItemSelected(indexPath)
            })
            .disposed(by: disposeBag)
    }
    
    private func bindComicRankCollctionView() {
        viewModel.comicRankObservable
            .bind(to: comicRankTableView.rx.items(cellIdentifier: ComicRankTableCell.identifier,
                                                  cellType: ComicRankTableCell.self)) { index, comic, cell in
                cell.titleLabel.text = comic.title
                cell.rankLabel.text = "\(index + 1)"
            }.disposed(by: disposeBag)
    }
    
    private func bindComicRankCollectionCell() {
        comicRankTableView.rx.itemSelected
            .asDriver()
            .drive(onNext: { [weak self] indexPath in
                self?.viewModel.comicRankItemSelected(indexPath)
            })
            .disposed(by: disposeBag)
        
        viewModel.presentComicStripVCObservable
            .subscribe(onNext: { [weak self] comic in
                self?.presentComicStripVC(comic)
            })
            .disposed(by: disposeBag)
    }
    
    private func bindComicRankLoadingLoadingState() {
        viewModel.isLoadingComicRank
            .subscribe(onNext: { [weak self] isLoading in
                if isLoading {
                    self?.comicRankTableView.playLottie()
                } else {
                    self?.comicRankTableView.stopLottie()
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func bindComicRankFailState() {
        viewModel.failToGetComicRank
            .subscribe(onNext: { [weak self] isFailed in
                if isFailed {
                    self?.comicRankTableView.stopLottie()
                    self?.comicRankTableView.makeNoticeLabel("🛠서버 점검중입니다.\n나중에 다시 시도해주세요")
                } else {
                    self?.comicRankTableView.removeNoticeLabels()
                }
            })
            .disposed(by: disposeBag)
    }
    
    
    // MARK: - Methods
    
    func presentComicStripVC(_ comic: Comic) {
        let storyboard = UIStoryboard(name: R.storyboard.comicStrip.name, bundle: nil)
        let comicStripVC = storyboard.instantiateViewController(identifier: ComicStripViewController.identifier,
                                                                creator: { coder -> ComicStripViewController in
            let episode = Episode(title: comic.title, serialNumber: "")
            let viewModel = ComicStripViewModel(episode: episode, episodeURL: comic.link)
            return .init(coder, viewModel) ?? ComicStripViewController(.init(episode: episode, episodeURL: ""))
        })

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
        
        watchHistoryVC.modalPresentationStyle = .fullScreen
        navigationController?.pushViewController(watchHistoryVC, animated: true)
    }
}
