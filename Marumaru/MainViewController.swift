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
import SkeletonView
import Kingfisher

class MainViewController: BaseViewController, ViewModelInjectable {
    
    
    // MARK: - Properties
    
    typealias ViewModel = MainViewModel
    
    @IBOutlet weak var appbarViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var mainScrollView: UIScrollView!
    @IBOutlet weak var searchBarView: UIView!
    
    @IBOutlet weak var newComicEpisodeContentsView: UIView!
    @IBOutlet weak var newComicEpisodeCollectionView: UICollectionView!
    @IBOutlet weak var refreshNewUpdateComicButton: UIButton!
    @IBOutlet weak var newUpdateComicHeaderAnimationView: LottieAnimationView!
    
    @IBOutlet weak var watchHistoryCollectionView: UICollectionView!
    @IBOutlet weak var showWatchHistoryButton: UIButton!
    @IBOutlet weak var watchHistoryHeaderAnimationView: LottieAnimationView!
    
    @IBOutlet weak var comicRankTableView: UITableView!
    @IBOutlet weak var refreshComicRankButton: UIButton!
    @IBOutlet weak var comicRankHeaderAnimationView: LottieAnimationView!
    
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        bindNewUpdateComicLoadingState()
        bindComicRankLoadingLoadingState()
        playAllHeaderAnimations()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopAllHeaderAnimations()
    }
    
    
    // MARK: - Setups
    
    private func setup() {
        setupData()
        setupView()
    }
    
    private func setupData() {
        viewModel.updateNewComicEpisodes()
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
        registerNewEpisodeCollecionCell()
        newComicEpisodeCollectionView.contentInset = UIEdgeInsets.leftAndRight(12)
        newComicEpisodeCollectionView.clipsToBounds = false
        newComicEpisodeCollectionView.decelerationRate = .fast
    }
    
    private func registerNewEpisodeCollecionCell() {
        let nibName = UINib(nibName: R.nib.comicEpisodeThumbnailCollectionCell.name, bundle: nil)
        newComicEpisodeCollectionView.register(nibName, forCellWithReuseIdentifier: ComicEpisodeThumbnailCollectionCell.identifier)
    }
    
    private func setupWatchHistoryCollectionView() {
        registerWatchHistoryCollectionCell()
        watchHistoryCollectionView.clipsToBounds = false
        watchHistoryCollectionView.contentInset = UIEdgeInsets.leftAndRight(12)
        watchHistoryCollectionView.decelerationRate = .fast
    }
    
    private func registerWatchHistoryCollectionCell() {
        let nibName = UINib(nibName: R.nib.comicEpisodeThumbnailCollectionCell.name, bundle: nil)
        watchHistoryCollectionView.register(nibName, forCellWithReuseIdentifier: ComicEpisodeThumbnailCollectionCell.identifier)
    }
    
    private func setupComicRankTableView() {
        registerComicRankTableCell()
        comicRankTableView.layer.cornerRadius = 12
        comicRankTableView.layer.masksToBounds = true
    }
    
    private func registerComicRankTableCell() {
        let nibName = UINib(nibName: R.nib.comicRankTableCell.name, bundle: nil)
        comicRankTableView.register(nibName, forCellReuseIdentifier: ComicRankTableCell.identifier)
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
        mainScrollView.contentInset = UIEdgeInsets.top(regularAppbarHeight + 24)
    }
    
    
    // MARK: - Binds
    
    private func bind() {
        bindSearchButton()
        bindShowWatchHistoryButton()
        bindRefreshNewUpdatedComicsButton()
        bindRefreshComicRankButton()
        
        bindNewComicEpisodeCollectionView()
        bindNewComicEpisodeCollectionCell()
        bindNewComicEpisodeFailState()
        
        bindWatchHistoryCollectionView()
        bindWatchHistoryCollectionCell()
        
        bindComicRankCollctionView()
        bindComicRankCollectionCell()
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
                vc.makeSelectionFeedback()
                vc.newComicEpisodeCollectionView.scrollToLeft(leftInset: 12, animated: false)
                vc.viewModel.updateNewComicEpisodes()
            })
            .disposed(by: disposeBag)
    }
    
    private func bindRefreshComicRankButton() {
        refreshComicRankButton.rx.tap
            .asDriver()
            .debounce(.milliseconds(300))
            .drive(with: self, onNext: { vc, _ in
                vc.makeSelectionFeedback()
                vc.comicRankTableView.scrollToTop(animated: false)
                vc.viewModel.updateComicRank()
            })
            .disposed(by: disposeBag)
    }
    
    private func bindNewComicEpisodeCollectionView() {
        viewModel.newComicEpisodesObservable
            .bind(to: newComicEpisodeCollectionView.rx
                .items(cellIdentifier: ComicEpisodeThumbnailCollectionCell.identifier,
                       cellType: ComicEpisodeThumbnailCollectionCell.self)) { [weak self] _, episode, cell in
                guard let self = self else { return }
                
                cell.hideSkeleton()
                cell.thumbnailImagePlaceholderLabel.text = episode.title
                cell.titleLabel.text = episode.title
                
                let url = self.viewModel.getImageURL(episode.thumbnailImagePath)
                cell.thumbnailImageView.kf.setImage(with: url, options: [.transition(.fade(0.3))]) { result in
                    do {
                        let result = try result.get()
                        let image = result.image
                        cell.thumbnailImagePlaceholderView.makeThumbnailShadow(with: image.averageColor)
                        cell.thumbnailImagePlaceholderLabel.isHidden = true
                    } catch {
                        cell.thumbnailImagePlaceholderLabel.isHidden = false
                    }
                }
                
                cell.onReuse = {
                    cell.thumbnailImageView.kf.cancelDownloadTask()
                }
            }.disposed(by: disposeBag)
    }
    
    private func bindNewComicEpisodeCollectionCell() {
        newComicEpisodeCollectionView.rx
            .itemSelected
            .asDriver()
            .drive(onNext: { [weak self] indexPath in
                self?.viewModel.newComicEpisodeItemSelected(indexPath)
            })
            .disposed(by: disposeBag)
    }
    
    private func bindNewUpdateComicLoadingState() {
        viewModel.isLoadingNewComicEpisode
            .subscribe(with: self, onNext: { vc, isLoading in
                vc.newComicEpisodeCollectionView.layoutIfNeeded()
                
                if isLoading {
                    vc.newComicEpisodeCollectionView.isUserInteractionEnabled = false
                    vc.newComicEpisodeCollectionView.visibleCells
                        .forEach({ cell in
                            cell.showCustomSkeleton()
                        })
                } else {
                    vc.newComicEpisodeCollectionView.isUserInteractionEnabled = true
                    vc.newComicEpisodeCollectionView.visibleCells
                        .forEach({ cell in
                            cell.hideSkeleton()
                        })
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func bindNewComicEpisodeFailState() {
        viewModel.failToGetNewComicEpisode
            .subscribe(onNext: { [weak self] isFailed in
                guard let self = self else { return }
                if isFailed {
                    self.newComicEpisodeCollectionView.stopLottie()
                    self.newComicEpisodeCollectionView.makeNoticeLabel("message.serverError".localized(),
                                                                      contentInsets: self.newComicEpisodeCollectionView.contentInset)
                } else {
                    self.newComicEpisodeCollectionView.removeNoticeLabels()
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func bindWatchHistoryCollectionView() {
        viewModel.watchHistoriesObservable
            .bind(to: watchHistoryCollectionView.rx.items(cellIdentifier: ComicEpisodeThumbnailCollectionCell.identifier,
                                                          cellType: ComicEpisodeThumbnailCollectionCell.self)) { [weak self] _, episode, cell in
                guard let self = self else { return }
                
                cell.hideSkeleton()
                cell.thumbnailImagePlaceholderLabel.text = episode.title
                cell.titleLabel.text = episode.title
                
                let url = self.viewModel.getImageURL(episode.thumbnailImagePath)
                cell.thumbnailImageView.kf.setImage(with: url, options: [.transition(.fade(0.3))]) { result in
                    do {
                        let result = try result.get()
                        let image = result.image
                        cell.thumbnailImagePlaceholderView.makeThumbnailShadow(with: image.averageColor)
                        cell.thumbnailImagePlaceholderLabel.isHidden = true
                    } catch {
                        cell.thumbnailImagePlaceholderLabel.isHidden = false
                    }
                }

                cell.onReuse = {
                    cell.thumbnailImageView.kf.cancelDownloadTask()
                }
            }.disposed(by: disposeBag)
        
        viewModel.watchHistoriesObservable
            .subscribe(with: self, onNext: { vc, comicEpisodes in
                if comicEpisodes.isEmpty {
                    vc.watchHistoryCollectionView.makeNoticeLabel("message.emptyWatchHistory".localized(),
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
                                                  cellType: ComicRankTableCell.self)) { index, episode, cell in
                cell.hideSkeleton()
                cell.titleLabel.text = episode.title
                cell.rankLabel.text = "\(index + 1)"
            }.disposed(by: disposeBag)
    }
    
    private func bindComicRankCollectionCell() {
        comicRankTableView.rx.itemSelected
            .asDriver()
            .drive(with: self, onNext: { vc, indexPath in
                vc.viewModel.comicRankItemSelected(indexPath)
            })
            .disposed(by: disposeBag)
        
        viewModel.presentComicStripVCObservable
            .subscribe(with: self, onNext: { vc, comicEpisode in
                vc.presentComicStripVC(comicEpisode)
            })
            .disposed(by: disposeBag)
    }
    
    private func bindComicRankLoadingLoadingState() {
        viewModel.isLoadingComicRank
            .subscribe(with: self, onNext: { vc, isLoading in
                vc.comicRankTableView.layoutIfNeeded()
                
                if isLoading {
                    vc.comicRankTableView.isUserInteractionEnabled = false
                    vc.comicRankTableView.visibleCells
                        .forEach({ cell in
                            cell.showCustomSkeleton()
                        })
                } else {
                    vc.comicRankTableView.isUserInteractionEnabled = true
                    vc.comicRankTableView.visibleCells
                        .forEach({ cell in
                            cell.hideSkeleton()
                        })
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func bindComicRankFailState() {
        viewModel.failToGetComicRank
            .subscribe(with: self, onNext: { vc, isFailed in
                if isFailed {
                    vc.comicRankTableView.stopLottie()
                    vc.comicRankTableView.makeNoticeLabel("message.serverError".localized())
                } else {
                    vc.comicRankTableView.removeNoticeLabels()
                }
            })
            .disposed(by: disposeBag)
    }
    
    
    // MARK: - Methods
    
    func presentComicStripVC(_ comicEpisode: ComicEpisode) {
        let storyboard = UIStoryboard(name: R.storyboard.comicStrip.name, bundle: nil)
        let comicStripVC = storyboard.instantiateViewController(identifier: ComicStripViewController.identifier,
                                                                creator: { coder -> ComicStripViewController in
            let viewModel = ComicStripViewModel(currentEpisode: comicEpisode)
            return .init(coder, viewModel) ?? ComicStripViewController(viewModel)
        })

        navigationController?.pushViewController(comicStripVC, animated: true)
    }
    
    func presentSearchComicVC() {
        let storyboard = UIStoryboard(name: R.storyboard.searchComic.name, bundle: nil)
        let searchComicVC = storyboard.instantiateViewController(identifier: SearchComicViewController.identifier,
                                                                  creator: { coder -> SearchComicViewController in
            let viewModel = SearchComicViewModel()
            return .init(coder, viewModel) ?? SearchComicViewController(.init())
        })
        
        navigationController?.pushViewController(searchComicVC, animated: true)
    }
    
    func presentWatchHistoryVC() {
        let storyboard = UIStoryboard(name: R.storyboard.watchHistory.name, bundle: nil)
        let watchHistoryVC = storyboard.instantiateViewController(identifier: WatchHistoryViewController.identifier,
                                                                  creator: { coder -> WatchHistoryViewController in
            let viewModel = WatchHistoryViewModel()
            return .init(coder, viewModel) ?? WatchHistoryViewController(.init())
        })
        
        navigationController?.pushViewController(watchHistoryVC, animated: true)
    }
    
    private func playAllHeaderAnimations() {
        newUpdateComicHeaderAnimationView.play()
        watchHistoryHeaderAnimationView.play()
        comicRankHeaderAnimationView.play()
    }
    
    private func stopAllHeaderAnimations() {
        newUpdateComicHeaderAnimationView.stop()
        watchHistoryHeaderAnimationView.stop()
        comicRankHeaderAnimationView.stop()
    }
}
