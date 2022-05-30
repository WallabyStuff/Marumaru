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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        bindNewUpdateComicLoadingState()
        bindComicRankLoadingLoadingState()
    }
    
    
    // MARK: - Setups
    
    private func setup() {
        setupData()
        setupView()
    }
    
    private func setupData() {
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
        bindNewUpdateFailState()
        
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
                vc.makeHapticFeedback()
                vc.newUpdateComicCollectionView.scrollToLeft(leftInset: 12, animated: false)
                vc.viewModel.updateNewUpdatedComics()
            })
            .disposed(by: disposeBag)
    }
    
    private func bindRefreshComicRankButton() {
        refreshComicRankButton.rx.tap
            .asDriver()
            .debounce(.milliseconds(300))
            .drive(with: self, onNext: { vc, _ in
                vc.makeHapticFeedback()
                vc.comicRankTableView.scrollToTop(animated: false)
                vc.viewModel.updateComicRank()
            })
            .disposed(by: disposeBag)
    }
    
    private func bindNewUpdateComicCollectionView() {
        viewModel.newUpdateComicsObservable
            .bind(to: newUpdateComicCollectionView.rx
                .items(cellIdentifier: ComicThumbnailCollectionCell.identifier,
                       cellType: ComicThumbnailCollectionCell.self)) { _, comic, cell in
                    cell.hideSkeleton()
                    cell.thumbnailImagePlaceholderLabel.text = comic.title
                    cell.titleLabel.text = comic.title
                    
                    if let imageURL = comic.thumbnailImageUrl {
                        let url = URL(string: imageURL)
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
            .subscribe(with: self, onNext: { vc, isLoading in
                vc.newUpdateComicCollectionView.layoutIfNeeded()
                
                if isLoading {
                    vc.newUpdateComicCollectionView.isUserInteractionEnabled = false
                    vc.newUpdateComicCollectionView.visibleCells
                        .forEach({ cell in
                            cell.showCustomSkeleton()
                        })
                } else {
                    vc.newUpdateComicCollectionView.isUserInteractionEnabled = true
                    vc.newUpdateComicCollectionView.visibleCells
                        .forEach({ cell in
                            cell.hideSkeleton()
                        })
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
                    self.newUpdateComicCollectionView.makeNoticeLabel("message.serverError".localized(),
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
                                                          cellType: ComicThumbnailCollectionCell.self)) { _, comic, cell in
                cell.hideSkeleton()
                cell.thumbnailImagePlaceholderLabel.text = comic.episodeTitle
                cell.titleLabel.text = comic.episodeTitle
                
                let url = URL(string: comic.thumbnailImageURL)
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
            }.disposed(by: disposeBag)
        
        viewModel.watchHistoriesObservable
            .subscribe(with: self, onNext: { vc, comics in
                if comics.isEmpty {
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
                                                  cellType: ComicRankTableCell.self)) { index, comic, cell in
                cell.hideSkeleton()
                cell.titleLabel.text = comic.title
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
            .subscribe(with: self, onNext: { vc, comic in
                vc.presentComicStripVC(comic)
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
        if let tabbarController = tabBarController {
            tabbarController.selectedIndex = 1
        } else {
            return
        }
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
