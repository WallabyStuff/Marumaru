//
//  ViewController.swift
//  Marumaru
//
//  Created by 이승기 on 2021/04/06.
//

import UIKit

import Alamofire
import SwiftSoup
import Toast
import Lottie
import CoreData
import Hero
import RealmSwift
import RxSwift
import RxCocoa

class ViewController: UIViewController {
    
    // MARK: - Declarations
    let baseUrl = "https://marumaru.cloud"
    
    struct UpdatedManga {
        var title: String
        var link: String
        var previewImageUrl: String?
    }
    
    struct RecentManga {
        var title: String
        var link: String
        var previewImageUrl: String?
        var previewImage: UIImage?
    }
    
    struct TopRankManga {
        var title: String
        var link: String
    }
    
    let disposeBag = DisposeBag()
    let imageCacheHandler = ImageCacheHandler()
    let networkHandler = NetworkHandler()
    let watchHistoryHandler = WatchHistoryHandler()
    var updatedMangaArr: [UpdatedManga] = []
    var watchHistoryArr: [WatchHistory] = []
    var topRankMangaArr: [TopRankManga] = []
    
    var isLoadingUpdatedManga = false
    var isLoadingTopRankManga = false
    
    var loadingUpdatedMangaAnimView = AnimationView()
    var loadingToprankMangaAnimView = AnimationView()

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
    
    @IBOutlet weak var updatedMangaCollectionView: UICollectionView!
    @IBOutlet weak var watchHistoryCollectionView: UICollectionView!
    @IBOutlet weak var topRankMangaTableView: UITableView!
    
    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initView()
        initInstance()
        
        setMainContents()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        loadMangaHistory()
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
//        updatedMangaCollectionView.layer.masksToBounds = false
        
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
        
        loadingUpdatedMangaAnimView = AnimationView(name: "loading_square")
        loadingUpdatedMangaAnimView.frame = CGRect(x: 0, y: 0, width: 300, height: 300)
        loadingUpdatedMangaAnimView.loopMode = .loop
        updatedMangaCollectionView.addSubview(loadingUpdatedMangaAnimView)
        loadingUpdatedMangaAnimView.translatesAutoresizingMaskIntoConstraints = false
        loadingUpdatedMangaAnimView.centerXAnchor.constraint(equalTo: updatedMangaCollectionView.centerXAnchor, constant: -25).isActive = true
        loadingUpdatedMangaAnimView.centerYAnchor.constraint(equalTo: updatedMangaCollectionView.centerYAnchor).isActive = true
        loadingUpdatedMangaAnimView.isHidden = true
        
        loadingToprankMangaAnimView = AnimationView(name: "loading_square")
        loadingToprankMangaAnimView.frame = CGRect(x: 0, y: 0, width: 300, height: 300)
        loadingToprankMangaAnimView.loopMode = .loop
        topRankMangaTableView.addSubview(loadingToprankMangaAnimView)
        loadingToprankMangaAnimView.translatesAutoresizingMaskIntoConstraints = false
        loadingToprankMangaAnimView.centerXAnchor.constraint(equalTo: topRankMangaTableView.centerXAnchor).isActive = true
        loadingToprankMangaAnimView.centerYAnchor.constraint(equalTo: topRankMangaTableView.centerYAnchor).isActive = true
        loadingToprankMangaAnimView.isHidden = true
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
    
    // MARK: - Methods
    func setMainContents() {
        DispatchQueue.global(qos: .background).async {
            self.startLoadingUpdateAnim()
            self.setUpdated()
        }
        DispatchQueue.global(qos: .background).async {
            self.startLoadingRankAnim()
            self.setRank()
        }
    }
    
    func startLoadingUpdateAnim() {
        DispatchQueue.main.async {
            self.loadingUpdatedMangaAnimView.isHidden = false
            self.loadingUpdatedMangaAnimView.play()
        }
    }
    
    func stopLoadingUpdateAnim() {
        DispatchQueue.main.async {
            self.loadingUpdatedMangaAnimView.isHidden = true
            self.loadingUpdatedMangaAnimView.stop()
        }
    }
    
    func startLoadingRankAnim() {
        DispatchQueue.main.async {
            self.loadingToprankMangaAnimView.isHidden = false
            self.loadingToprankMangaAnimView.play()
        }
    }
    
    func stopLoadingRankAnim() {
        DispatchQueue.main.async {
            self.loadingToprankMangaAnimView.isHidden = true
            self.loadingToprankMangaAnimView.stop()
        }
    }
    
    func setUpdated() {
        if isLoadingUpdatedManga == true {
            return
        }
        
        DispatchQueue.main.async {
            self.isLoadingUpdatedManga = true
            self.updatedMangaArr.removeAll()
            self.updatedMangaCollectionView.reloadData()
            self.startLoadingUpdateAnim()
        }
        
        guard let baseUrl = URL(string: "https://marumaru.cloud") else { return }
        
        do {
            let htmlContent = try String(contentsOf: baseUrl, encoding: .utf8)
            let doc = try SwiftSoup.parse(htmlContent)
            let updatedMangas = try doc.getElementsByClass("post-row")
            
            self.updatedMangaArr.removeAll()
            
            try updatedMangas.forEach { element in
                let title = try element.select("a").text().trimmingCharacters(in: .whitespaces)
                var imgUrl = try String(element.select("img").attr("src")).trimmingCharacters(in: .whitespaces)
                let link = try element.select("a").attr("href").trimmingCharacters(in: .whitespaces)
                
                // url preset
                if !imgUrl.contains(self.baseUrl) {
                    imgUrl = "\(baseUrl)\(imgUrl)"
                }
                
                self.updatedMangaArr.append(UpdatedManga(title: title, link: link, previewImageUrl: imgUrl))
            }
            
            // Finish to load updated manga
            DispatchQueue.main.async {
                self.stopLoadingUpdateAnim()
                self.updatedMangaCollectionView.reloadData()
                self.isLoadingUpdatedManga = false
            }
            
        } catch {
            print("Log something wend wrong")
            print(error.localizedDescription)
        }
        
    }
    
    func setRank() {
        if isLoadingTopRankManga == true {
            return
        }
        
        DispatchQueue.main.async {
            self.isLoadingTopRankManga = true
            self.topRankMangaArr.removeAll()
            self.topRankMangaTableView.reloadData()
            self.startLoadingRankAnim()
        }
        
        guard let baseUrl = URL(string: "https://marumaru.cloud") else { return }
        
        do {
            let htmlContent = try String(contentsOf: baseUrl, encoding: .utf8)
            let doc = try SwiftSoup.parse(htmlContent)
            let rank = try doc.getElementsByClass("basic-post-list")
            let rankElements = try rank.select("a")
            
            self.topRankMangaArr.removeAll()
            
            try rankElements.forEach { element in
                let title = try element.select("a").text().trimmingCharacters(in: .whitespaces)
                let link = try element.select("a").attr("href").trimmingCharacters(in: .whitespaces)
                
                self.topRankMangaArr.append(TopRankManga(title: title, link: link))
            }
            
            // Finish to load TopRank Manga data
            DispatchQueue.main.async {
                self.stopLoadingRankAnim()
                self.topRankMangaTableView.reloadData()
                self.isLoadingTopRankManga = false
            }

        } catch {
            print(error.localizedDescription)
        }
    }
    
    func loadMangaHistory() {
        watchHistoryArr.removeAll()
        watchHistoryCollectionView.reloadData()
        
        watchHistoryHandler.fetchData()
            .subscribe { event in
                if let watchHistories = event.element {
                    self.watchHistoryArr = watchHistories
                    self.reloadWatchHistoryCollectionView()
                }
                
            }.disposed(by: disposeBag)
    }
    
    func reloadWatchHistoryCollectionView() {
        DispatchQueue.main.async {
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
    
    // MARK: - Actions
    @IBAction func searchButtonAction(_ sender: Any) {
        let destStotyboard = storyboard?.instantiateViewController(identifier: "SearchStoryboard") as! SearchViewController
        
        destStotyboard.modalPresentationStyle = .fullScreen
        
        present(destStotyboard, animated: true)
    }
    
    @IBAction func showAllHistoryButtonAction(_ sender: Any) {
        guard let destStoryboard = storyboard?.instantiateViewController(identifier: "MangaHistoryStoryboard") as? WatchHistoryViewController else { return }
        
        destStoryboard.dismissDelegate = self
        destStoryboard.modalPresentationStyle = .fullScreen
        
        present(destStoryboard, animated: true)
    }
    
    @IBAction func reloadUpdatedMangaButtonAction(_ sender: Any) {
        DispatchQueue.global(qos: .background).async {
            self.setUpdated()
        }
    }
    
    @IBAction func reloadTopRankMangaButtonAction(_ sender: Any) {
        DispatchQueue.global(qos: .background).async {
            self.setRank()
        }
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
            
            if indexPath.row > updatedMangaArr.count - 1 {
                return UICollectionViewCell()
            }
            
            collectionCell.titleLabel.text = updatedMangaArr[indexPath.row].title
            collectionCell.thumbnailImageView.image = UIImage()
            collectionCell.thumbnailImagePlaceholderLabel.isHidden = false
            collectionCell.thumbnailImagePlaceholderLabel.text = updatedMangaArr[indexPath.row].title
            
            if let previewImageUrl = updatedMangaArr[indexPath.row].previewImageUrl {
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
                                print(error.localizedDescription)
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
            
            if indexPath.row > watchHistoryArr.count - 1 {
                return UICollectionViewCell()
            }
            
            let currentManga = watchHistoryArr[indexPath.row]
            // set title & place holder
            collectionCell.titleLabel.text = currentManga.mangaTitle
            collectionCell.thumbnailImagePlaceholderLabel.text = currentManga.mangaTitle
            
            if let thumbnailImageUrl = URL(string: currentManga.thumbnailImageUrl) {
                networkHandler.getImage(thumbnailImageUrl) { result in
                    do {
                        let result = try result.get()
                        DispatchQueue.main.async {
                            collectionCell.thumbnailImageView.image = result.imageCache.image
                            collectionCell.thumbnailImageBaseView.setThumbnailShadow(with: result.imageCache.averageColor.cgColor)
                            collectionCell.thumbnailImagePlaceholderLabel.isHidden = true
                            collectionCell.thumbnailImageView.startFadeInAnim(duration: 0.3)
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
            let mangaTitle = updatedMangaArr[indexPath.row].title
            
            // check link does have baseUrl
            if !mangaUrl.contains(baseUrl) {
                mangaUrl = "\(baseUrl)\(mangaUrl)"
            }
            
            presentViewMangaVC(mangaTitle, mangaUrl)
        } else {
            var mangaUrl = watchHistoryArr[indexPath.row].mangaUrl
            let mangaTitle = watchHistoryArr[indexPath.row].mangaTitle
//            guard var mangaUrl = watchHistoryArr[indexPath.row].mangaUrl,
//                  let mangaTitle = watchHistoryArr[indexPath.row].mangaTitle else { return }
//
            // check link does have baseUrl
            if !mangaUrl.contains(baseUrl) {
                mangaUrl = "\(baseUrl)\(mangaUrl)"
            }
            
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
        
        // Custom Selection Style
        let rect = CGRect(x: 0, y: 0, width: 200, height: 200)
        let selectedUIView = UIView(frame: rect)
        selectedUIView.layer.cornerRadius = 10
        selectedUIView.backgroundColor = ColorSet.cellSelectionColor
        topRankCell.selectedBackgroundView = selectedUIView
        
        topRankCell.rankLabel.text = String(indexPath.row + 1)
        topRankCell.titleLabel.text = topRankMangaArr[indexPath.row].title
        
        return topRankCell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var mangaUrl = topRankMangaArr[indexPath.row].link
        let mangaTitl = topRankMangaArr[indexPath.row].title
        
        if !mangaUrl.contains(baseUrl) {
            mangaUrl = "\(baseUrl)\(mangaUrl)"
        }
        
        presentViewMangaVC(mangaTitl, mangaUrl)
    }
}

extension ViewController: DismissDelegate {
    func refreshHistory() {
        self.loadMangaHistory()
    }
}
