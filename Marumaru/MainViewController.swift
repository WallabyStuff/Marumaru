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
import Hero
import RxSwift
import RxCocoa
import RealmSwift

class MainViewController: UIViewController, ViewModelInjectable {
    
    
    // MARK: - Properties
    
    typealias ViewModel = MainViewModel
    
    @IBOutlet weak var appbarView: AppbarView!
    @IBOutlet weak var mainScrollView: UIScrollView!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var newUpdateComicContentsView: UIView!
    @IBOutlet weak var newUpdateComicHeaderLabel: UILabel!
    @IBOutlet weak var newUpdateComicCollectionView: UICollectionView!
    @IBOutlet weak var refreshNewUpdateComicButton: UIButton!
    @IBOutlet weak var watchHistoryHeaderLabel: UILabel!
    @IBOutlet weak var watchHistoryCollectionView: UICollectionView!
    @IBOutlet weak var showWatchHistoryButton: UIButton!
    @IBOutlet weak var comicRankHeaderLabel: UILabel!
    @IBOutlet weak var comicRankTableView: UITableView!
    @IBOutlet weak var refreshComicRankButton: UIButton!
    
    static let identifier = R.storyboard.main.mainStoryboard.identifier
    var viewModel: ViewModel
    var disposeBag = DisposeBag()
    private var loadingUpdatedMangaAnimView = LottieAnimationView()
    private var loadingMangaRankAnimView = LottieAnimationView()
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
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    // MARK: - LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        bind()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .darkContent
    }

    
    // MARK: - Setups
    
    private func setup() {
        setupView()
        setupData()
    }
    
    private func setupData() {
        viewModel.cleanCacheIfNeeded()
        
        reloadUpdatedComic()
        reloadWatchHistory()
        reloadComicRank()
    }
    
    private func setupView() {
        setupHero()
        setupAppbarView()
        setupSearchButton()
        setupRefreshNewUpdatedComicButton()
        setupUpdatedComicCollectionView()
        setupWatchHistoryCollectionView()
        setupTopRankComicTableView()
        setupNewComicHeaderLabel()
        setupWatchHistoryHeaderLabel()
        setupComicRankHeaderLabel()
    }
    
    private func setupHero() {
        self.hero.isEnabled = true
    }
    
    private func setupAppbarView() {
        appbarView.configure(frame: appbarView.frame, cornerRadius: 24, roundCorners: [.bottomRight])
    }
    
    private func setupSearchButton() {
        searchButton.hero.id = "appbarButton"
        searchButton.imageEdgeInsets(with: 10)
        searchButton.layer.cornerRadius = 12
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
    
    private func setupNewComicHeaderLabel() {
        newUpdateComicHeaderLabel.layer.masksToBounds = true
        newUpdateComicHeaderLabel.layer.cornerRadius = 10
    }
    
    private func setupWatchHistoryHeaderLabel() {
        watchHistoryHeaderLabel.layer.masksToBounds = true
        watchHistoryHeaderLabel.layer.cornerRadius = 10
    }
    
    private func setupComicRankHeaderLabel() {
        comicRankHeaderLabel.layer.masksToBounds = true
        comicRankHeaderLabel.layer.cornerRadius = 10
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
        searchButton.rx.tap
            .asDriver()
            .drive(onNext: { [weak self] _ in
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
        playUpdatedMangaLoadingAnimation()
        
        viewModel.getUpdatedContents()
            .subscribe(with: self, onCompleted: { vc in
                vc.loadingUpdatedMangaAnimView.stop()
            }).disposed(by: disposeBag)
    }
    
    func reloadWatchHistory() {
        watchHistoryPlaceholderLabel.detatchLabel()
        
        viewModel.getWatchHistories()
            .subscribe(with: self, onError: { vc, error in
                if let error = error as? MainViewError {
                    vc.watchHistoryPlaceholderLabel.attatchLabel(text: error.message, to: vc.watchHistoryCollectionView)
                }
            })
            .disposed(by: disposeBag)
    }
    
    func reloadComicRank() {
        playMangaRankLoadingAnimation()
        
        viewModel.getTopRankedComics()
            .subscribe(with: self, onCompleted: { vc in
                vc.loadingMangaRankAnimView.stop()
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
        present(comicStripVC, animated: true, completion: nil)
    }
    
    func presentSearchComicVC() {
        let storyboard = UIStoryboard(name: R.storyboard.searchComic.name, bundle: nil)
        let searchComicVC = storyboard.instantiateViewController(identifier: SearchComicViewController.identifier,
                                                                 creator: { coder -> SearchComicViewController in
            let viewModel = SearchComicViewModel()
            return .init(coder, viewModel) ?? SearchComicViewController(.init())
        })
        
        searchComicVC.modalPresentationStyle = .fullScreen
        present(searchComicVC, animated: true)
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
        present(watchHistoryVC, animated: true)
    }
    
    private func playUpdatedMangaLoadingAnimation() {
        loadingUpdatedMangaAnimView.play(name: "loading_cat",
                                         size: CGSize(width: 148, height: 148),
                                         to: newUpdateComicContentsView)
    }
    
    private func playMangaRankLoadingAnimation() {
        loadingMangaRankAnimView.play(name: "loading_cat",
                                      size: CGSize(width: 148, height: 148),
                                      to: comicRankTableView)
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
        guard let mangaCollectionCell = collectionView.dequeueReusableCell(withReuseIdentifier: ComicThumbnailCollectionCell.identifier, for: indexPath) as? ComicThumbnailCollectionCell else { return UICollectionViewCell() }
        
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
        
        let mangaInfo = viewModel.topRankCellItemForRow(at: indexPath)
        rankCell.titleLabel.text = mangaInfo.title
        rankCell.rankLabel.text = viewModel.topRankCellRank(indexPath: indexPath).description
        
        return rankCell
    }
}

extension MainViewController: WatchHistoryViewDelegate, ComicStripViewDelegate {
    func didWatchHistoryUpdated() {
        reloadWatchHistory()
    }
}
