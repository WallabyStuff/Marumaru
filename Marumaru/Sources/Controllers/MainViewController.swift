//
//  MainViewController.swift
//  Marumaru
//
//  Created by 이승기 on 2021/04/06.
//

import UIKit

import RxSwift
import RxCocoa

import Toast
import Lottie
import RealmSwift
import SkeletonView
import Kingfisher
import FloatingPanel

class MainViewController: BaseViewController, ViewModelInjectable {
  
  // MARK: - Properties
  
  static let identifier = R.storyboard.main.mainStoryboard.identifier
  typealias ViewModel = MainViewModel
  
  var viewModel: ViewModel
  
  
  // MARK: - UI
  
  @IBOutlet weak var navigationView: NavigationView!
  @IBOutlet weak var appBarViewHeightConstraint: NSLayoutConstraint!
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
  private var fpc = FloatingPanelController()
  
  
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
    setupNavigationView()
    setupUpdatedComicCollectionView()
    setupWatchHistoryCollectionView()
    setupComicRankTableView()
    setupFloatingPanelView()
  }
  
  private func setupNavigationView() {
    navigationView.configureScrollEdgeAppearance(mainScrollView)
  }
  
  private func setupUpdatedComicCollectionView() {
    let nibName = UINib(nibName: R.nib.comicEpisodeThumbnailCollectionCell.name, bundle: nil)
    newComicEpisodeCollectionView.register(nibName, forCellWithReuseIdentifier: ComicEpisodeThumbnailCollectionCell.identifier)
    newComicEpisodeCollectionView.decelerationRate = .fast
  }
  
  private func setupWatchHistoryCollectionView() {
    let nibName = UINib(nibName: R.nib.comicEpisodeThumbnailCollectionCell.name, bundle: nil)
    watchHistoryCollectionView.register(nibName, forCellWithReuseIdentifier: ComicEpisodeThumbnailCollectionCell.identifier)
    watchHistoryCollectionView.decelerationRate = .fast
  }
  
  private func setupComicRankTableView() {
    let nibName = UINib(nibName: R.nib.comicRankTableCell.name, bundle: nil)
    comicRankTableView.register(nibName, forCellReuseIdentifier: ComicRankTableCell.identifier)
  }
  
  private func setupFloatingPanelView() {
    fpc.layout = ShowComicOptionFloatingPanelLayout()
    let appearance = SurfaceAppearance()
    appearance.cornerRadius = 16
    fpc.surfaceView.appearance = appearance
    fpc.surfaceView.backgroundColor = R.color.backgroundWhite()
    fpc.surfaceView.grabberHandle.isHidden = true
    fpc.backdropView.dismissalTapGestureRecognizer.isEnabled = true
    fpc.isRemovalInteractionEnabled = true
  }
  
  
  // MARK: - Constraints
  
  override func updateViewConstraints() {
    configureAppBarViewConstraints()
    super.updateViewConstraints()
  }
  
  private func configureAppBarViewConstraints() {
    appBarViewHeightConstraint.constant = view.safeAreaInsets.top + regularAppBarHeight
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
    
    bindComicRankTableView()
    bindComicRankTableCell()
    bindComicRankFailState()
    
    bindPresentComicStripVC()
    bindPresentComicDetailVC()
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
    viewModel.newComicEpisodes
      .bind(to: newComicEpisodeCollectionView.rx
        .items(cellIdentifier: ComicEpisodeThumbnailCollectionCell.identifier,
               cellType: ComicEpisodeThumbnailCollectionCell.self)) { _, episode, cell in
        cell.configure(with: episode)
      }.disposed(by: disposeBag)
    
    newComicEpisodeCollectionView.rx.observe(CGRect.self, #keyPath(UIView.frame))
      .subscribe(onNext: { [weak self] _ in
        self?.newComicEpisodeCollectionView.reloadData()
      })
      .disposed(by: disposeBag)
  }
  
  private func bindNewComicEpisodeCollectionCell() {
    newComicEpisodeCollectionView.rx
      .itemSelected
      .asDriver()
      .drive(onNext: { [weak self] indexPath in
        self?.viewModel.newComicEpisodeItemSelected(indexPath)
      })
      .disposed(by: disposeBag)
    
    newComicEpisodeContentsView.rx.observe(CGRect.self, #keyPath(UIView.frame))
      .subscribe(onNext: { [weak self] _ in
        self?.newComicEpisodeCollectionView.reloadData()
      })
      .disposed(by: disposeBag)
  }
  
  private func bindNewUpdateComicLoadingState() {
    viewModel.isLoadingNewComicEpisode
      .subscribe(with: self, onNext: { vc, isLoading in
        vc.newComicEpisodeCollectionView.layoutIfNeeded()
        
        if isLoading {
          vc.refreshNewUpdateComicButton.isUserInteractionEnabled = false
          vc.newComicEpisodeCollectionView.isUserInteractionEnabled = false
          vc.newComicEpisodeCollectionView.visibleCells
            .forEach({ cell in
              cell.showCustomSkeleton()
            })
        } else {
          vc.refreshNewUpdateComicButton.isUserInteractionEnabled = true
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
    viewModel.watchHistories
      .bind(to: watchHistoryCollectionView.rx.items(cellIdentifier: ComicEpisodeThumbnailCollectionCell.identifier,
                                                    cellType: ComicEpisodeThumbnailCollectionCell.self)) { _, episode, cell in
        cell.configure(with: episode.convertToComicEpisode())
      }.disposed(by: disposeBag)
    
    viewModel.watchHistories
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
  
  private func bindComicRankTableView() {
    viewModel.comicRank
      .bind(to: comicRankTableView.rx.items(cellIdentifier: ComicRankTableCell.identifier,
                                            cellType: ComicRankTableCell.self)) { index, episode, cell in
        cell.configure(with: episode, rank: index + 1)
      }.disposed(by: disposeBag)
  }
  
  private func bindComicRankTableCell() {
    comicRankTableView.rx.itemSelected
      .asDriver()
      .drive(with: self, onNext: { vc, indexPath in
        vc.viewModel.comicRankItemSelected(indexPath)
      })
      .disposed(by: disposeBag)
  }
  
  private func bindComicRankLoadingLoadingState() {
    viewModel.isLoadingComicRank
      .subscribe(with: self, onNext: { vc, isLoading in
        vc.comicRankTableView.layoutIfNeeded()
        
        if isLoading {
          vc.refreshComicRankButton.isUserInteractionEnabled = false
          vc.comicRankTableView.isUserInteractionEnabled = false
          vc.comicRankTableView.visibleCells
            .forEach({ cell in
              cell.showCustomSkeleton()
            })
        } else {
          vc.refreshComicRankButton.isUserInteractionEnabled = true
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
  
  private func bindPresentComicStripVC() {
    viewModel.presentComicStripVC
      .subscribe(with: self, onNext: { vc, comicEpisode in
        vc.presentComicStripVC(comicEpisode)
      })
      .disposed(by: disposeBag)
  }
  
  private func bindPresentComicDetailVC() {
    viewModel.presentComicDetailVC
      .subscribe(with: self, onNext: { vc, comicEpisode in
        vc.presentShowComicOptionAlertFPC(comicEpisode)
      })
      .disposed(by: disposeBag)
  }
  
  
  // MARK: - Methods
  
  private func presentComicStripVC(_ comicEpisode: ComicEpisode) {
    let storyboard = UIStoryboard(name: R.storyboard.comicStrip.name, bundle: nil)
    let comicStripVC = storyboard.instantiateViewController(identifier: ComicStripViewController.identifier,
                                                            creator: { coder -> ComicStripViewController in
      let viewModel = ComicStripViewModel(currentEpisode: comicEpisode)
      return .init(coder, viewModel) ?? ComicStripViewController(viewModel)
    })
    
    navigationController?.pushViewController(comicStripVC, animated: true)
  }
  
  private func presentShowComicOptionAlertFPC(_ comicEpisode: ComicEpisode) {
    let storyboard = UIStoryboard(name: R.storyboard.showComicOption.name, bundle: nil)
    let comicDetailVC = storyboard.instantiateViewController(identifier: ShowComicOptionAlertViewController.identifier,
                                                             creator: { coder -> ShowComicOptionAlertViewController in
      let viewModel = ShowComicOptionAlertViewModel(currentEpisode: comicEpisode)
      return .init(coder, viewModel) ?? ShowComicOptionAlertViewController(viewModel)
    })
    
    comicDetailVC.delegate = self
    fpc.set(contentViewController: comicDetailVC)
    
    makeImpactFeedback(.light)
    self.present(fpc, animated: true)
  }
  
  private func presentSearchComicVC() {
    let storyboard = UIStoryboard(name: R.storyboard.searchComic.name, bundle: nil)
    let searchComicVC = storyboard.instantiateViewController(identifier: SearchComicViewController.identifier,
                                                             creator: { coder -> SearchComicViewController in
      let viewModel = SearchComicViewModel()
      return .init(coder, viewModel) ?? SearchComicViewController(.init())
    })
    
    navigationController?.pushViewController(searchComicVC, animated: true)
  }
  
  private func presentWatchHistoryVC() {
    let storyboard = UIStoryboard(name: R.storyboard.watchHistory.name, bundle: nil)
    let watchHistoryVC = storyboard.instantiateViewController(identifier: WatchHistoryViewController.identifier,
                                                              creator: { coder -> WatchHistoryViewController in
      let viewModel = WatchHistoryViewModel()
      return .init(coder, viewModel) ?? WatchHistoryViewController(.init())
    })
    
    navigationController?.pushViewController(watchHistoryVC, animated: true)
  }
  
  private func presentComicDetailVC(_ comicInfo: ComicInfo) {
    let storybaord = UIStoryboard(name: R.storyboard.comicDetail.name, bundle: nil)
    let comicStripVC = storybaord.instantiateViewController(identifier: ComicDetailViewController.identifier,
                                                            creator: { coder -> ComicDetailViewController in
      let viewModel = ComicDetailViewModel(comicInfo: comicInfo)
      return .init(coder, viewModel) ?? ComicDetailViewController(viewModel)
    })
    
    present(comicStripVC, animated: true)
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

extension MainViewController: ShowComicOptionAlertViewDelegate {
  func didTapShowComicStripButton(_ comicEpisode: ComicEpisode) {
    presentComicStripVC(comicEpisode)
  }
  
  func didTapShowComicDetailButton(_ comicInfo: ComicInfo) {
    presentComicDetailVC(comicInfo)
  }
}
