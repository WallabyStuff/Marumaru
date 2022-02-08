//
//  ViewController.swift
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

class MainViewController: UIViewController {
    
    // MARK: - Declarations
    @IBOutlet weak var appbarView: AppbarView!
    @IBOutlet weak var updatesHeaderLabel: UILabel!
    @IBOutlet weak var recentsHeaderLabel: UILabel!
    @IBOutlet weak var top20HeaderLabel: UILabel!
    @IBOutlet weak var refreshUpdatedMangaButton: UIButton!
    @IBOutlet weak var refreshMangaRankButton: UIButton!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var mainScrollView: UIScrollView!
    @IBOutlet weak var showWatchHistoryButton: UIButton!
    @IBOutlet weak var updatedContentsCollectionView: UICollectionView!
    @IBOutlet weak var watchHistoryCollectionView: UICollectionView!
    @IBOutlet weak var mangaRankTableView: UITableView!
    @IBOutlet weak var updatedContentsBoardView: UIView!
    
    private let disposeBag = DisposeBag()
    private let viewModel = MainViewModel()
    private var loadingUpdatedMangaAnimView = LottieAnimationView()
    private var loadingMangaRankAnimView = LottieAnimationView()
    private var watchHistoryPlaceholderLabel = StickyPlaceholderLabel()
    
    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        bind()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .darkContent
    }
    
    // MARK: - Setup
    private func setup() {
        setupView()
        setupData()
    }
    
    private func setupData() {
        viewModel.cleanCacheIfNeeded()
        
        reloadUpdatedContents()
        reloadWatchHistories()
        reloadMangaRank()
    }
    
    private func setupView() {
        setupHero()
        setupAppbarView()
        setupSearchButton()
        setupRefreshUpdatedMangaButton()
        setupUpdatedMangaCollectionView()
        setupWatchHistoryCollectionView()
        setupTopRankMangaTableView()
        setupUpdatesHeaderLabel()
        setupRecentsHeaderLabel()
        setupTop20HeaderLabel()
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
    
    private func setupRefreshUpdatedMangaButton() {
        refreshUpdatedMangaButton.imageEdgeInsets(with: 6)
        refreshMangaRankButton.imageEdgeInsets(with: 6)
    }
    
    private func setupUpdatedMangaCollectionView() {
        let nibName = UINib(nibName: "MangaThumbnailCollectionViewCell", bundle: nil)
        updatedContentsCollectionView.register(nibName, forCellWithReuseIdentifier: MangaThumbnailCollectionCell.identifier)
        updatedContentsCollectionView.clipsToBounds = false
        updatedContentsCollectionView.delegate = self
        updatedContentsCollectionView.dataSource = self
        updatedContentsCollectionView.contentInset = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        
        viewModel.reloadUpdatedContentCollectionView = { [weak self] in
            DispatchQueue.main.async {
                self?.updatedContentsCollectionView.reloadData()
            }
        }
    }
    
    private func setupWatchHistoryCollectionView() {
        let nibName = UINib(nibName: "MangaThumbnailCollectionViewCell", bundle: nil)
        watchHistoryCollectionView.register(nibName, forCellWithReuseIdentifier: MangaThumbnailCollectionCell.identifier)
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
    
    private func setupTopRankMangaTableView() {
        let nibName = UINib(nibName: "MangaRankTableViewCell", bundle: nil)
        mangaRankTableView.register(nibName, forCellReuseIdentifier: MangaRankTableViewCell.identifier)
        
        mangaRankTableView.layer.cornerRadius = 12
        mangaRankTableView.layer.masksToBounds = true
        
        mangaRankTableView.delegate = self
        mangaRankTableView.dataSource = self
        
        viewModel.reloadTopRankTableView = { [weak self] in
            DispatchQueue.main.async {
                self?.mangaRankTableView.reloadData()
            }
        }
    }
    
    private func setupUpdatesHeaderLabel() {
        updatesHeaderLabel.layer.masksToBounds = true
        updatesHeaderLabel.layer.cornerRadius = 10
    }
    
    private func setupRecentsHeaderLabel() {
        recentsHeaderLabel.layer.masksToBounds = true
        recentsHeaderLabel.layer.cornerRadius = 10
    }
    
    private func setupTop20HeaderLabel() {
        top20HeaderLabel.layer.masksToBounds = true
        top20HeaderLabel.layer.cornerRadius = 10
    }
    
    // MARK: - Binds
    private func bind() {
        bindSearchButton()
        bindRefreshUpdatedContentButton()
        bindShowWatchHistoryButton()
        bindRefreshMangaRankButton()
        bindTopRankedMangaCell()
    }
    
    private func bindSearchButton() {
        searchButton.rx.tap
            .asDriver()
            .drive(onNext: { [weak self] _ in
                self?.presentSearchVC()
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
        refreshUpdatedMangaButton.rx.tap
            .asDriver()
            .debounce(.milliseconds(300))
            .drive(with: self, onNext: { vc, _  in
                vc.reloadUpdatedContents()
            })
            .disposed(by: disposeBag)
    }
    
    private func bindRefreshMangaRankButton() {
        refreshMangaRankButton.rx.tap
            .asDriver()
            .debounce(.milliseconds(300))
            .drive(with: self, onNext: { vc, _ in
                vc.reloadMangaRank()
            })
            .disposed(by: disposeBag)
    }
    
    private func bindTopRankedMangaCell() {
        mangaRankTableView.rx.itemSelected
            .asDriver()
            .drive(with: self, onNext: { vc, indexPath in
                let mangaInfo = vc.viewModel.topRankCellItemForRow(at: indexPath)
                vc.presentPlayMangaVC(mangaInfo.title, mangaInfo.link)
            }).disposed(by: disposeBag)
    }
    
    // MARK: - Methods
    func reloadUpdatedContents() {
        playUpdatedMangaLoadingAnimation()
        
        viewModel.getUpdatedContents()
            .subscribe(with: self, onCompleted: { vc in
                vc.loadingUpdatedMangaAnimView.stop()
            }).disposed(by: disposeBag)
    }
    
    func reloadWatchHistories() {
        watchHistoryPlaceholderLabel.detatchLabel()
        
        viewModel.getWatchHistories()
            .subscribe(with: self, onError: { vc, error in
                if let error = error as? MainViewError {
                    vc.watchHistoryPlaceholderLabel.attatchLabel(text: error.message, to: vc.watchHistoryCollectionView)
                }
            })
            .disposed(by: disposeBag)
    }
    
    func reloadMangaRank() {
        playMangaRankLoadingAnimation()
        
        viewModel.getTopRankedMangas()
            .subscribe(with: self, onCompleted: { vc in
                vc.loadingMangaRankAnimView.stop()
            }).disposed(by: disposeBag)
    }
    
    func presentPlayMangaVC(_ mangaTitle: String, _ mangaUrl: String) {
        let viewModel = PlayMangaViewModel(mangaTitle: mangaTitle, link: mangaUrl)
        
        guard let playMangaVC = storyboard?.instantiateViewController(identifier: "ViewMangaStoryboard", creator: { coder in
            PlayMangaViewController(
                coder: coder, viewModel: viewModel)
        }) else { return }
        
        playMangaVC.delegate = self
        playMangaVC.modalPresentationStyle = .fullScreen
        present(playMangaVC, animated: true, completion: nil)
    }
    
    func presentSearchVC() {
        guard let searchVC = storyboard?.instantiateViewController(identifier: "SearchStoryboard") as? SearchViewController else { return }
        searchVC.modalPresentationStyle = .fullScreen
        
        present(searchVC, animated: true)
    }
    
    func presentWatchHistoryVC() {
        guard let watchHistoryVC = storyboard?.instantiateViewController(identifier: "MangaHistoryStoryboard") as? WatchHistoryViewController else { return }
        watchHistoryVC.delegate = self
        watchHistoryVC.modalPresentationStyle = .fullScreen
        
        present(watchHistoryVC, animated: true)
    }
    
    private func playUpdatedMangaLoadingAnimation() {
        loadingUpdatedMangaAnimView.play(name: "loading_cat",
                                         size: CGSize(width: 148, height: 148),
                                         to: updatedContentsBoardView)
    }
    
    private func playMangaRankLoadingAnimation() {
        loadingMangaRankAnimView.play(name: "loading_cat",
                                      size: CGSize(width: 148, height: 148),
                                      to: mangaRankTableView)
    }
}

// MARK: - Extensions
extension MainViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if collectionView == updatedContentsCollectionView {
            return viewModel.updatedContentsNumberOfItem
        } else {
            return viewModel.watchHistoriesNumberOfItem
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let mangaCollectionCell = collectionView.dequeueReusableCell(withReuseIdentifier: MangaThumbnailCollectionCell.identifier, for: indexPath) as? MangaThumbnailCollectionCell else { return UICollectionViewCell() }
        
        let mangaInfo = collectionView == updatedContentsCollectionView ? viewModel.updatedContentCellItemForRow(at: indexPath) : viewModel.watchHistoryCellItemForRow(at: indexPath)
        
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
        let mangaInfo = collectionView == updatedContentsCollectionView ? viewModel.updatedContentCellItemForRow(at: indexPath) : viewModel.watchHistoryCellItemForRow(at: indexPath)
        
        presentPlayMangaVC(mangaInfo.title, mangaInfo.link)
    }
}

extension MainViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.topRankNumberOfItemsInSection(section: 0)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let rankCell = tableView.dequeueReusableCell(withIdentifier: MangaRankTableViewCell.identifier, for: indexPath) as? MangaRankTableViewCell else { return UITableViewCell() }
        
        let mangaInfo = viewModel.topRankCellItemForRow(at: indexPath)
        rankCell.titleLabel.text = mangaInfo.title
        rankCell.rankLabel.text = viewModel.topRankCellRank(indexPath: indexPath).description
        
        return rankCell
    }
}

extension MainViewController: WatchHistoryViewDelegate, PlayMangaViewDelegate {
    func didWatchHistoryUpdated() {
        reloadWatchHistories()
    }
}
