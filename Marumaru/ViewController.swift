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
    let coredataHandler = HistoryHandler()
    var updatedMangaArr: [UpdatedManga] = []
    var recentMangaArr: [WatchHistory] = []
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
    @IBOutlet weak var recentMangaPlaceholderLabel: UILabel!
    
    @IBOutlet weak var updatedMangaCollectionView: UICollectionView!
    @IBOutlet weak var recentMangaCollectionView: UICollectionView!
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
//        let topSafeAreaHeight = UIApplication.shared.windows[0].safeAreaInsets.top
//        appBarView.heightAnchor.constraint(equalToConstant: topSafeAreaHeight + 80).isActive = true
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
        recentMangaCollectionView.contentInset = UIEdgeInsets(top: 0, left: 25, bottom: 0, right: 25)
        
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
        updatedMangaCollectionView.delegate = self
        updatedMangaCollectionView.dataSource = self
        
        // Recent Manga CollectionView inistialization
        recentMangaCollectionView.delegate = self
        recentMangaCollectionView.dataSource = self
        
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
        
        guard let baseUrl = URL(string: "https://marumaru.cloud") else {return}
        
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
        coredataHandler.getWatchHistory { result in
            do {
                let recentMangas = try result.get()
                // check has history update
                if !self.recentMangaArr.elementsEqual(recentMangas) {
                    self.recentMangaArr = recentMangas
                    
                    DispatchQueue.main.async {
                        if self.recentMangaArr.count > 0 {
                            self.recentMangaPlaceholderLabel.isHidden = true
                        } else {
                            self.recentMangaPlaceholderLabel.isHidden = false
                        }
                        
                        self.recentMangaCollectionView.reloadData()
                    }
                }
            } catch {
                print(error.localizedDescription)
                
                DispatchQueue.main.async {
                    self.recentMangaArr.removeAll()
                    self.recentMangaCollectionView.reloadData()
                    self.recentMangaPlaceholderLabel.isHidden = false
                }
            }
        }
    }
    
    // MARK: - Actions
    @IBAction func searchButtonAction(_ sender: Any) {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let destStotyboard = mainStoryboard.instantiateViewController(identifier: "SearchStoryboard") as! SearchViewController
        
        destStotyboard.modalPresentationStyle = .fullScreen
        
        present(destStotyboard, animated: true)
    }
    
    @IBAction func showAllHistoryButtonAction(_ sender: Any) {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let destStoryboard = mainStoryboard.instantiateViewController(identifier: "MangaHistoryStoryboard") as! MangaHistoryViewController
        
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
        case recentMangaCollectionView:
            // limit maximum item count
            return min(15, recentMangaArr.count)
        default:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        switch collectionView {
        case updatedMangaCollectionView:
            let collectionCell = collectionView.dequeueReusableCell(withReuseIdentifier: "UpdatedMangaCell", for: indexPath) as! MangaCollectionCell
            
            if indexPath.row > updatedMangaArr.count - 1 {
                return UICollectionViewCell()
            }
            
            collectionCell.titleLabel.text = updatedMangaArr[indexPath.row].title
            collectionCell.previewImage.image = UIImage()
            collectionCell.previewImagePlaceholderLabel.isHidden = false
            collectionCell.previewImagePlaceholderLabel.text = updatedMangaArr[indexPath.row].title
            
            if let previewImageUrl = updatedMangaArr[indexPath.row].previewImageUrl {
                if let url = URL(string: previewImageUrl) {
                    let token = networkHandler.getImage(url) { result in
                        DispatchQueue.global(qos: .background).async {
                            do {
                                let result = try result.get()
                                
                                DispatchQueue.main.async {
                                    collectionCell.previewImage.image = result.imageCache.image
                                    collectionCell.previewImagePlaceholderLabel.isHidden = true
                                    
                                    if result.animate {
                                        collectionCell.previewImage.startFadeInAnim(duration: 0.5)
                                    }
                                }
                            } catch {
                                DispatchQueue.main.async {
                                    collectionCell.previewImagePlaceholderLabel.isHidden = false
                                }
                                
                                print(error.localizedDescription)
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
        case recentMangaCollectionView:
            let collectionCell = collectionView.dequeueReusableCell(withReuseIdentifier: "RecentMangaCell", for: indexPath) as! MangaCollectionCell
            
            if indexPath.row > recentMangaArr.count - 1 {
                return UICollectionViewCell()
            }
            
            // init preview image
            collectionCell.previewImage.image = UIImage()
            
            if let title = recentMangaArr[indexPath.row].title {
                // set title & place holder
                collectionCell.titleLabel.text = title
                collectionCell.previewImagePlaceholderLabel.text = title
            }
            
            // set preview image
            if let previewImage = recentMangaArr[indexPath.row].preview_image {
                if !previewImage.isEmpty {
                    // preview image is exists
                    collectionCell.previewImage.image = UIImage(data: previewImage)
                    collectionCell.previewImagePlaceholderLabel.isHidden = true
                } else {
                    if let previewImageUrl = recentMangaArr[indexPath.row].preview_image_url {
                        if !previewImageUrl.isEmpty {
                            // preview image url is exists
                            if let url = URL(string: previewImageUrl) {
                                networkHandler.getImage(url) { result in
                                    DispatchQueue.global(qos: .background).async {
                                        do {
                                            let result = try result.get()
                                            
                                            DispatchQueue.main.async {
                                                collectionCell.previewImage.image = result.imageCache.image
                                                collectionCell.previewImagePlaceholderLabel.isHidden = true
                                                
                                                if result.animate {
                                                    collectionCell.previewImage.startFadeInAnim(duration: 0.5)
                                                }
                                            }
                                        } catch {
                                            DispatchQueue.main.async {
                                                collectionCell.previewImagePlaceholderLabel.isHidden = false
                                            }
                                            print(error.localizedDescription)
                                        }
                                    }
                                }
                            } else {
                                collectionCell.previewImagePlaceholderLabel.isHidden = false
                            }
                        }
                    } else {
                        collectionCell.previewImagePlaceholderLabel.isHidden = false
                    }
                }
            } else {
                collectionCell.previewImagePlaceholderLabel.isHidden = false
            }
            
            return collectionCell
        default:
            return UICollectionViewCell()
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let destStoryboard = mainStoryboard.instantiateViewController(identifier: "ViewMangaStoryboard") as! ViewMangaViewController
        
        destStoryboard.modalPresentationStyle = .fullScreen
        
        var link = ""
        var title = ""
        
        // check collectionview type
        if collectionView == updatedMangaCollectionView {
            link = updatedMangaArr[indexPath.row].link
            title = updatedMangaArr[indexPath.row].title
        } else {
            link = recentMangaArr[indexPath.row].link!
            title = recentMangaArr[indexPath.row].title!
        }
        
        // check link does have baseUrl
        if !link.contains(baseUrl) {
            link = "\(baseUrl)\(link)"
        }
        
        // pass data
        destStoryboard.mangaUrl = link
        destStoryboard.mangaTitle = title
        
        present(destStoryboard, animated: true, completion: nil)
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return topRankMangaArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let topRankCell = tableView.dequeueReusableCell(withIdentifier: "TopRankMangaCell", for: indexPath) as! TopRankMangaCell
        
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
        let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        
        let destStroyboard = mainStoryboard.instantiateViewController(identifier: "ViewMangaStoryboard") as! ViewMangaViewController
        
        destStroyboard.modalPresentationStyle = .fullScreen
        
        var link = topRankMangaArr[indexPath.row].link
        let title = topRankMangaArr[indexPath.row].title
        
        if !link.contains(baseUrl) {
            link = "\(baseUrl)\(link)"
        }
        
        destStroyboard.mangaUrl = link
        destStroyboard.mangaTitle = title
        
        present(destStroyboard, animated: true, completion: nil)
    }
}

extension ViewController: DismissDelegate {
    func refreshHistory() {
        self.loadMangaHistory()
    }
}
