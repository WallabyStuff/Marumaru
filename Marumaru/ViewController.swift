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

class ViewController: UIViewController {
    
    // MARK: - Declarations
    let disposeBag = DisposeBag()
    let imageCacheHandler = ImageCacheHandler()
    let networkHandler = NetworkHandler()
    let watchHistoryHandler = WatchHistoryHandler()
    let userDefaultsHandler = UserDefaultsHandler()
    
    var updatedMangaArr: [Manga] = []
    var watchHistoryArr: [WatchHistory] = []
    var topRankMangaArr: [TopRankManga] = []
    
    var loadingUpdatedMangaAnimView = LoadingView()
    var loadingToprankMangaAnimView = LoadingView()
    
    @IBOutlet weak var appbarView: AppbarView!
    @IBOutlet weak var homeIcon: UIImageView!
    @IBOutlet weak var updatesHeaderLabel: UILabel!
    @IBOutlet weak var recentsHeaderLabel: UILabel!
    @IBOutlet weak var top20HeaderLabel: UILabel!
    @IBOutlet weak var refreshUpdatedMangaButton: UIButton!
    @IBOutlet weak var refreshTop20MangaButton: UIButton!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var mainScrollView: UIScrollView!
    @IBOutlet weak var watchHisotryPlaceholderLabel: UILabel!
    @IBOutlet weak var showWatchHistoryButton: UIButton!
    @IBOutlet weak var updatedMangaCollectionView: UICollectionView!
    @IBOutlet weak var watchHistoryCollectionView: UICollectionView!
    @IBOutlet weak var topRankMangaTableView: UITableView!
    @IBOutlet weak var updatedMangaPlaceholderLabel: UILabel!
    @IBOutlet weak var top20MangaPlaceholderLabel: UILabel!
    @IBOutlet weak var updatesBoardView: UIView!
    
    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Clean cache datas
        userDefaultsHandler.checkCacheNeedsCleanUp()
        
        // Update basePath
        networkHandler.updateBasePath()
        
        initView()
        initInstance()
        initEventListener()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        setMainContents()
        setWatchHistory()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .darkContent
    }
    
    // MARK: - Initializations
    func initView() {
        // hero enable
        self.hero.isEnabled = true
        
        // appbar View
        appbarView.configure(frame: appbarView.frame, cornerRadius: 40, roundCorners: [.bottomRight])
        
        // search button ImageView
        searchButton.hero.id = "appbarButton"
        searchButton.imageEdgeInsets(with: 10)
        searchButton.layer.cornerRadius = 13
        
        // reloadUpdatedManga Button
        refreshUpdatedMangaButton.imageEdgeInsets(with: 6)
        refreshTop20MangaButton.imageEdgeInsets(with: 6)
        
        // updatedManga CollectionView
        updatedMangaCollectionView.contentInset = UIEdgeInsets(top: 0, left: 25, bottom: 0, right: 25)
        
        // recentManga CollectionView
        watchHistoryCollectionView.contentInset = UIEdgeInsets(top: 0, left: 25, bottom: 0, right: 25)
        
        // topRankManga TableView
        topRankMangaTableView.layer.cornerRadius = 10
        topRankMangaTableView.layer.masksToBounds = true
        
        // updates Header Label
        updatesHeaderLabel.layer.masksToBounds = true
        updatesHeaderLabel.layer.cornerRadius = 10
        
        // recentse Header Label
        recentsHeaderLabel.layer.masksToBounds = true
        recentsHeaderLabel.layer.cornerRadius = 10
        
        // top20 Header Label
        top20HeaderLabel.layer.masksToBounds = true
        top20HeaderLabel.layer.cornerRadius = 10
        
        // loading updated manga animation View
        loadingUpdatedMangaAnimView = LoadingView(name: "loading_cat",
                                                  loopMode: .autoReverse,
                                                  frame: CGRect(x: 0, y: 0, width: 150, height: 150))
        updatesBoardView.addSubview(loadingUpdatedMangaAnimView)
        loadingUpdatedMangaAnimView.setConstraint(width: 150, targetView: updatesBoardView)
        
        // loading top rank animation View
        loadingToprankMangaAnimView = LoadingView(name: "loading_cat",
                                                  loopMode: .autoReverse,
                                                  frame: CGRect(x: 0, y: 0, width: 150, height: 150))
        topRankMangaTableView.addSubview(loadingToprankMangaAnimView)
        loadingToprankMangaAnimView.setConstraint(width: 150, targetView: topRankMangaTableView)
    }
    
    func initInstance() {
        // Updated Manga CollectionView initialization
        let mangaThumbnailCollectionCellNib = UINib(nibName: "MangaThumbnailCollectionViewCell", bundle: nil)
        updatedMangaCollectionView.register(mangaThumbnailCollectionCellNib, forCellWithReuseIdentifier: "mangaThumbnailCollectionCell")
        updatedMangaCollectionView.delegate = self
        updatedMangaCollectionView.dataSource = self
        
        // Recent Manga CollectionView inistialization
        watchHistoryCollectionView.register(mangaThumbnailCollectionCellNib, forCellWithReuseIdentifier: "mangaThumbnailCollectionCell")
        watchHistoryCollectionView.delegate = self
        watchHistoryCollectionView.dataSource = self
        
        // Top Rank Manga TableView initialization
        topRankMangaTableView.delegate = self
        topRankMangaTableView.dataSource = self
    }
    
    func initEventListener() {
        // searchButton Action
        searchButton.rx.tap
            .asDriver()
            .drive(onNext: { [weak self] _ in
                self?.presentSearchVC()
            })
            .disposed(by: disposeBag)
        
        // show History Button Action
        showWatchHistoryButton.rx.tap
            .asDriver()
            .drive(onNext: { [weak self] _ in
                self?.presentWatchHistoryVC()
            })
            .disposed(by: disposeBag)
        
        // refresh updated Manga Button Action
        refreshUpdatedMangaButton.rx.tap
            .debounce(.milliseconds(300), scheduler: ConcurrentMainScheduler.instance)
            .observe(on: ConcurrentDispatchQueueScheduler.init(qos: .background))
            .subscribe(onNext: { [weak self] _ in
                self?.setUpdatedManga()
            })
            .disposed(by: disposeBag)
        
        // refresh top20 Manga Button Action
        refreshTop20MangaButton.rx.tap
            .debounce(.milliseconds(300), scheduler: ConcurrentMainScheduler.instance)
            .observe(on: ConcurrentDispatchQueueScheduler.init(qos: .background))
            .subscribe(onNext: { [weak self] in
                self?.setTopRankManga()
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Methods
    func setMainContents() {
        if updatedMangaArr.count == 0 {
            setUpdatedManga()
        } else {
            loadingUpdatedMangaAnimView.stop()
            if updatedMangaCollectionView.visibleCells.count == 0 {
                updatedMangaCollectionView.reloadData()
            }
        }
        
        if topRankMangaArr.count == 0 {
            setTopRankManga()
        } else {
            loadingToprankMangaAnimView.stop()
            if topRankMangaTableView.visibleCells.count == 0 {
                topRankMangaTableView.reloadData()
            }
        }
    }
    
    func setUpdatedManga() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.updatedMangaPlaceholderLabel.isHidden = true
            self.updatedMangaArr.removeAll()
            self.updatedMangaCollectionView.reloadData()
            self.loadingUpdatedMangaAnimView.play()
        }
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            self.networkHandler.getUpdatedManga { result in
                do {
                    let result = try result.get()
                    self.updatedMangaArr = result
                    
                    // Finish to load updated manga
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        self.loadingUpdatedMangaAnimView.stop { isDone in
                            if isDone {
                                self.updatedMangaCollectionView.reloadData()
                            }
                        }
                    }
                } catch {
                    // failure state
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        self.loadingUpdatedMangaAnimView.stop { isDone in
                            if isDone {
                                self.updatedMangaPlaceholderLabel.isHidden = false
                            }
                        }
                    }
                }
            }
        }
    }
    
    func setTopRankManga() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.top20MangaPlaceholderLabel.isHidden = true
            self.topRankMangaArr.removeAll()
            self.topRankMangaTableView.reloadData()
            self.loadingToprankMangaAnimView.play()
        }
        
        networkHandler.getTopRankedManga { [weak self] result in
            guard let self = self else { return }
            do {
                let result = try result.get()
                self.topRankMangaArr = result
                
                // Finish to load TopRank Manga data
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.loadingToprankMangaAnimView.stop { isDone in
                        if isDone {
                            self.topRankMangaTableView.reloadData()
                        }
                    }
                }
            } catch {
                // failure state
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.loadingToprankMangaAnimView.stop { isDone in
                        if isDone {
                            self.top20MangaPlaceholderLabel.isHidden = false
                        }
                    }
                }
            }
        }
    }
    
    func setWatchHistory() {
        watchHistoryArr.removeAll()
        reloadWatchHistoryCollectionView()
        
        watchHistoryHandler.fetchData()
            .subscribe(onNext: { watchHistories in
                if self.watchHistoryArr != watchHistories {
                    self.watchHistoryArr = watchHistories
                    self.reloadWatchHistoryCollectionView()
                }
            })
            .disposed(by: disposeBag)
    }
    
    func reloadWatchHistoryCollectionView() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.watchHistoryCollectionView.reloadData()
            
            if self.watchHistoryArr.count == 0 {
                self.watchHisotryPlaceholderLabel.isHidden = false
            } else {
                self.watchHisotryPlaceholderLabel.isHidden = true
            }
        }
    }
    
    func presentViewMangaVC(_ mangaTitle: String, _ mangaUrl: String) {
        guard let viewMangaVC = storyboard?.instantiateViewController(identifier: "ViewMangaStoryboard") as? ViewMangaViewController else { return }
        viewMangaVC.modalPresentationStyle = .fullScreen
        
        viewMangaVC.mangaTitle = mangaTitle
        viewMangaVC.mangaUrl = mangaUrl
        
        present(viewMangaVC, animated: true, completion: nil)
    }
    
    func presentSearchVC() {
        guard let destStotyboard = storyboard?.instantiateViewController(identifier: "SearchStoryboard") as? SearchViewController else { return }
        destStotyboard.modalPresentationStyle = .fullScreen
        
        present(destStotyboard, animated: true)
    }
    
    func presentWatchHistoryVC() {
        guard let destStoryboard = storyboard?.instantiateViewController(identifier: "MangaHistoryStoryboard") as? WatchHistoryViewController else { return }
        destStoryboard.modalPresentationStyle = .fullScreen
        
        present(destStoryboard, animated: true)
    }
}

// MARK: - Extensions
extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        switch collectionView {
        case updatedMangaCollectionView:
            return updatedMangaArr.count
        case watchHistoryCollectionView:
            // limit maximum item count
            return min(15, watchHistoryArr.count)
        default:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        switch collectionView {
        case updatedMangaCollectionView:
            guard let collectionCell = collectionView.dequeueReusableCell(withReuseIdentifier: "mangaThumbnailCollectionCell", for: indexPath) as? MangaThumbnailCollectionCell else { return UICollectionViewCell() }
            
            let currentManga = updatedMangaArr[indexPath.row]
            
            collectionCell.titleLabel.text = currentManga.title
            collectionCell.thumbnailImageView.image = UIImage()
            collectionCell.thumbnailImagePlaceholderLabel.isHidden = false
            collectionCell.thumbnailImagePlaceholderLabel.text = currentManga.title
            
            if let previewImageUrl = currentManga.thumbnailImageUrl {
                if let url = URL(string: previewImageUrl) {
                    let token = networkHandler.getImage(url) { result in
                        DispatchQueue.global(qos: .background).async {
                            do {
                                let result = try result.get()
                                
                                DispatchQueue.main.async {
                                    collectionCell.thumbnailImageView.image = result.imageCache.image
                                    collectionCell.thumbnailImagePlaceholderLabel.isHidden = true
                                    collectionCell.thumbnailImageBaseView.setThumbnailShadow(with: result.imageCache.averageColor.cgColor)
                                    
                                    if result.animate {
                                        collectionCell.thumbnailImageView.startFadeInAnim(duration: 0.5)
                                    }
                                }
                            } catch {
                                DispatchQueue.main.async {
                                    collectionCell.thumbnailImagePlaceholderLabel.isHidden = false
                                }
                            }
                        }
                    }
                    collectionCell.onReuse = {
                        if let token = token {
                            self.networkHandler.cancelLoadImage(token)
                        }
                    }
                }
            }
            return collectionCell
            
        case watchHistoryCollectionView:
            guard let collectionCell = collectionView.dequeueReusableCell(withReuseIdentifier: "mangaThumbnailCollectionCell", for: indexPath) as? MangaThumbnailCollectionCell else { return UICollectionViewCell() }
            
            let currentManga = watchHistoryArr[indexPath.row]
            // set title & place holder
            collectionCell.titleLabel.text = currentManga.mangaTitle
            collectionCell.thumbnailImagePlaceholderLabel.text = currentManga.mangaTitle
            collectionCell.thumbnailImagePlaceholderLabel.isHidden = false
            
            if let thumbnailImageUrl = URL(string: currentManga.thumbnailImageUrl) {
                networkHandler.getImage(thumbnailImageUrl) { result in
                    do {
                        let result = try result.get()
                        DispatchQueue.main.async {
                            collectionCell.thumbnailImageView.image = result.imageCache.image
                            collectionCell.thumbnailImageBaseView.setThumbnailShadow(with: result.imageCache.averageColor.cgColor)
                            collectionCell.thumbnailImagePlaceholderLabel.isHidden = true
                            
                            if result.animate {
                                collectionCell.thumbnailImageView.startFadeInAnim(duration: 0.3)
                            }
                        }
                    } catch {
                        DispatchQueue.main.async {
                            collectionCell.thumbnailImagePlaceholderLabel.isHidden = false
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    collectionCell.thumbnailImagePlaceholderLabel.isHidden = false
                }
            }
            
            return collectionCell
        default:
            return UICollectionViewCell()
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if collectionView == updatedMangaCollectionView {
            var mangaUrl = updatedMangaArr[indexPath.row].link
            mangaUrl = networkHandler.getCompleteUrl(url: mangaUrl)
            
            let mangaTitle = updatedMangaArr[indexPath.row].title
            
            presentViewMangaVC(mangaTitle, mangaUrl)
        } else {
            var mangaUrl = watchHistoryArr[indexPath.row].mangaUrl
            mangaUrl = networkHandler.getCompleteUrl(url: mangaUrl)
            
            let mangaTitle = watchHistoryArr[indexPath.row].mangaTitle
            
            presentViewMangaVC(mangaTitle, mangaUrl)
        }
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return topRankMangaArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let topRankCell = tableView.dequeueReusableCell(withIdentifier: "TopRankMangaCell", for: indexPath) as? TopRankMangaCell else { return UITableViewCell() }
        
        if indexPath.row > topRankMangaArr.count - 1 {
            return UITableViewCell()
        }
        
        topRankCell.selectionStyle = .none
        topRankCell.rankLabel.text = String(indexPath.row + 1)
        topRankCell.titleLabel.text = topRankMangaArr[indexPath.row].title
        
        return topRankCell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var mangaUrl = topRankMangaArr[indexPath.row].link
        mangaUrl = networkHandler.getCompleteUrl(url: mangaUrl)
        
        let mangaTitle = topRankMangaArr[indexPath.row].title
        
        presentViewMangaVC(mangaTitle, mangaUrl)
    }
}
