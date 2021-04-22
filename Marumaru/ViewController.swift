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

class ViewController: UIViewController {
    
    let baseUrl = "https://marumaru.cloud"
    
    struct UpdatedManga {
        var title: String
        var link: String
        var previewImageUrl: String?
        var previewImage: UIImage?
    }
    
    struct RecentManga{
        var title: String
        var link: String
        var previewImageUrl: String?
        var previewImage: UIImage?
    }
    
    struct TopRankManga {
        var title: String
        var link: String
    }
    
    
    let networkHandler = NetworkHandler()
    var updatedMangaArr = Array<UpdatedManga>()
    var recentMangaArr = Array<MangaHistory>()
    var topRankMangaArr = Array<TopRankManga>()
    

    @IBOutlet weak var homeIcon: UIImageView!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var mainScrollView: UIScrollView!
    @IBOutlet weak var loadingUpdatedMangaAnimView: UIView!
    @IBOutlet weak var loadingMangaRankAnimView: UIView!
    @IBOutlet weak var recentMangaPlaceholderLabel: UILabel!
    
    
    
    @IBOutlet weak var updatedMangaCollectionView: UICollectionView!
    @IBOutlet weak var recentMangaCollectionView: UICollectionView!
    @IBOutlet weak var topRankMangaTableView: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initDesigns()
        initInstance()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        setMainContents()
        setLottieAnims()
        
        loadMangaHistory()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle{
        return .darkContent
    }
    

    func initDesigns(){
        homeIcon.image = homeIcon.image!.withRenderingMode(.alwaysTemplate)
        searchButton.imageView?.image = searchButton.imageView?.image?.withRenderingMode(.alwaysTemplate)
        
        updatedMangaCollectionView.contentInset = UIEdgeInsets(top: 0, left: 25, bottom: 0, right: 25)
        recentMangaCollectionView.contentInset = UIEdgeInsets(top: 0, left: 25, bottom: 0, right: 25)
        
        topRankMangaTableView.layer.cornerRadius = 10
        topRankMangaTableView.layer.masksToBounds = true
    }
    
    func initInstance(){
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
    
    func setMainContents(){
        DispatchQueue.global(qos: .background).async {
            self.setUpdated()
            self.setRank()
        }
    }
    
    func setLottieAnims(){
        // set updated manga loading anim -lottie-
        let loadingSqaureAnimView = AnimationView(name: "loading_square")
        loadingSqaureAnimView.frame = CGRect(x: 0, y: 0, width: 300, height: 300)
        loadingSqaureAnimView.center = loadingUpdatedMangaAnimView.center
        loadingSqaureAnimView.loopMode = .loop
        loadingSqaureAnimView.play()
        loadingUpdatedMangaAnimView.addSubview(loadingSqaureAnimView)
        
        // set top rank manga loading anim -lottie-
        let loadingCircleAnimView = AnimationView(name: "loading_horizontal")
        loadingCircleAnimView.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        loadingCircleAnimView.center = loadingMangaRankAnimView.center
        loadingCircleAnimView.loopMode = .loop
        loadingCircleAnimView.play()
        loadingMangaRankAnimView.addSubview(loadingCircleAnimView)
    }
    
    
    func setUpdated(){
        guard let baseUrl = URL(string: "https://marumaru.cloud") else {return}
        
        do{
            let htmlContent = try String(contentsOf: baseUrl, encoding: .utf8)
            let doc = try SwiftSoup.parse(htmlContent)
            let updatedMangas = try doc.getElementsByClass("post-row")
            
            self.updatedMangaArr.removeAll()
            
            for (index, Element) in updatedMangas.enumerated(){
                
                let title = try Element.select("a").text()
                var imgUrl = try String(Element.select("img").attr("src"))
                let link = try Element.select("a").attr("href")
                
                // url preset
                if !imgUrl.contains(self.baseUrl) {
                    imgUrl = "\(baseUrl)\(imgUrl)"
                }
                
                self.updatedMangaArr.append(UpdatedManga(title: title, link: link, previewImageUrl: imgUrl, previewImage: nil))
                
            }
            
            // Finish to load updated manga
            DispatchQueue.main.async {
                self.loadingUpdatedMangaAnimView.isHidden = true
                
                self.updatedMangaCollectionView.reloadData()
            }
            
        }catch{
            
            
            print(error.localizedDescription)
        }
        
    }
    
    func setRank(){
        guard let baseUrl = URL(string: "https://marumaru.cloud") else {return}
        
        do{
            let htmlContent = try String(contentsOf: baseUrl, encoding: .utf8)
            let doc = try SwiftSoup.parse(htmlContent)
            let rank = try doc.getElementsByClass("basic-post-list")
            let rankElements = try rank.select("a")
            
            self.topRankMangaArr.removeAll()
            
            for (index, Element) in rankElements.enumerated(){
                do{
                    let title = try Element.select("a").text()
                    let link = try Element.select("a").attr("href")
                    
                    self.topRankMangaArr.append(TopRankManga(title: title, link: link))
                    
                }catch{
                    print(error.localizedDescription)
                }
            }
            
            // Finish to load TopRank Manga data
            DispatchQueue.main.async {
                self.loadingMangaRankAnimView.isHidden = true
                self.topRankMangaTableView.reloadData()
            }

        }catch{
            print(error.localizedDescription)
        }
    }
    
    
    func saveToMangaHistory(mangaTitle: String, mangaLink: String, mangaPreviewImageUrl: String?, mangaPreviewImage: UIImage?){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let entity = NSEntityDescription.entity(forEntityName: "MangaHistory", in: context)
        
        if let entity = entity{
            let manga = NSManagedObject(entity: entity, insertInto: context)
            
            if mangaTitle.isEmpty || mangaLink.isEmpty{
                return
            }
            
            // save title & link
            manga.setValue(mangaTitle, forKey: "title")
            manga.setValue(mangaLink, forKey: "link")
            
            // save preview image url & data safely
            if let mangaPreviewImageUrl = mangaPreviewImageUrl{
                manga.setValue(mangaPreviewImageUrl, forKey: "preview_image_url")
            }
            if let mangaPreviewImage = mangaPreviewImage{
                let jpegData = mangaPreviewImage.jpegData(compressionQuality: 1)
                manga.setValue(jpegData, forKey: "preview_image")
            }
            
            do{
                try context.save()
            }catch{
                // fail to save manga history
                print(error.localizedDescription)
            }
        }
    }
    
    
    func loadMangaHistory(){
        recentMangaArr.removeAll()
        recentMangaCollectionView.reloadData()
        self.recentMangaPlaceholderLabel.isHidden = false
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        DispatchQueue.global(qos: .background).async {
            do{
                let recentMangas = try context.fetch(MangaHistory.fetchRequest()) as! [MangaHistory]
                
                self.recentMangaArr = recentMangas.reversed()
                
                DispatchQueue.main.async {
                    if self.recentMangaArr.count > 0{
                        self.recentMangaPlaceholderLabel.isHidden = true
                    }
                    
                    self.recentMangaCollectionView.reloadData()
                }
                
            }catch{
                print(error.localizedDescription)
            }
        }
    }
    
    
    @IBAction func searchButtonAction(_ sender: Any) {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let destStotyboard = mainStoryboard.instantiateViewController(identifier: "SearchStoryboard") as! SearchViewController
        
        destStotyboard.modalPresentationStyle = .fullScreen
        
        present(destStotyboard, animated: true)
    }
    
    
    @IBAction func showAllHistoryButtonAction(_ sender: Any) {
        print("activated")
        let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let destStoryboard = mainStoryboard.instantiateViewController(identifier: "MangaHistoryStoryboard") as! MangaHistoryViewController
        
        present(destStoryboard, animated: true, completion: nil)
    }
}



extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        switch collectionView {
        case updatedMangaCollectionView:
            return updatedMangaArr.count
        case recentMangaCollectionView:
            return recentMangaArr.count
        default:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        switch collectionView {
        case updatedMangaCollectionView:
            let collectionCell = collectionView.dequeueReusableCell(withReuseIdentifier: "UpdatedMangaCell", for: indexPath) as! MangaCollectionCell
            
            collectionCell.titleLabel.text = updatedMangaArr[indexPath.row].title
            collectionCell.previewImage.image = UIImage()
            collectionCell.previewImagePlaceholderLabel.isHidden = false
            collectionCell.previewImagePlaceholderLabel.text = updatedMangaArr[indexPath.row].title
            
            
            if let previewImageUrl = updatedMangaArr[indexPath.row].previewImageUrl{
                if let url = URL(string: previewImageUrl){
                    let token = networkHandler.getImage(url){result in
                        DispatchQueue.global(qos: .background).async {
                            do{
                                let image = try result.get()
                                DispatchQueue.main.async {
                                    collectionCell.previewImage.image = image
                                    collectionCell.previewImagePlaceholderLabel.isHidden = true
                                    
                                    collectionCell.previewImage.alpha = 0
                                    UIView.animate(withDuration: 0.5) {
                                        collectionCell.previewImage.alpha = 1
                                    }
                                }
                            }catch{
                                DispatchQueue.main.async {
                                    collectionCell.previewImagePlaceholderLabel.isHidden = false
                                }
                                
                                print(error.localizedDescription)
                            }
                        }
                    }
                    
                    collectionCell.onReuse = {
                        if let token = token{
                            self.networkHandler.cancelLoadImage(token)
                        }
                    }
                }
            }
//
//            // 안전하게 인덱스 접근
//            if indexPath.row < updatedMangaArr.count{
//                // set preview updated manga's preview image
//                if updatedMangaArr[indexPath.row].previewImage != nil{
//                    // preview image has already loaded
//                    collectionCell.previewImage.image = updatedMangaArr[indexPath.row].previewImage
//                    collectionCell.previewImagePlaceholderLabel.isHidden = true
//                }else{
//                    // preview image has not been loaded
//                    if let previewImgUrl = updatedMangaArr[indexPath.row].previewImageUrl{
//                        let imgUrl = URL(string: previewImgUrl)
//                        DispatchQueue.global(qos: .background).async {
//                            do{
//                                let previewImgData = try Data(contentsOf: imgUrl!)
//                                self.updatedMangaArr[indexPath.row].previewImage = UIImage(data: previewImgData)
//
//                                DispatchQueue.main.async {
//                                    collectionCell.previewImage.alpha = 0
//                                    collectionCell.previewImage.image = self.updatedMangaArr[indexPath.row].previewImage
//                                    collectionCell.previewImagePlaceholderLabel.isHidden = true
//
//                                    UIView.animate(withDuration: 0.5) {
//                                        collectionCell.previewImage.alpha = 1
//                                    }
//                                }
//                            }catch{
//                                DispatchQueue.main.async {
//                                    collectionCell.previewImagePlaceholderLabel.isHidden = false
//                                    collectionCell.previewImagePlaceholderLabel.text = self.updatedMangaArr[indexPath.row].title
//                                }
//                                print(error.localizedDescription)
//                            }
//                        }
//                    }else{
//                        collectionCell.previewImagePlaceholderLabel.isHidden = false
//                        collectionCell.previewImagePlaceholderLabel.text = self.updatedMangaArr[indexPath.row].title
//                    }
//                }
//            }

            
            return collectionCell
        case recentMangaCollectionView:
            let collectionCell = collectionView.dequeueReusableCell(withReuseIdentifier: "RecentMangaCell", for: indexPath) as! MangaCollectionCell
            
            // init preview image
            collectionCell.previewImage.image = UIImage()
            
            if let title = recentMangaArr[indexPath.row].title{
                // set title & place holder
                collectionCell.titleLabel.text = title
                collectionCell.previewImagePlaceholderLabel.text = title
            }
            
            // set preview image
            if let previewImage = recentMangaArr[indexPath.row].preview_image{
                if !previewImage.isEmpty{
                    // preview image is exists
                    collectionCell.previewImage.image = UIImage(data: previewImage)
                    collectionCell.previewImagePlaceholderLabel.isHidden = true
                }else{
                    if let previewImageUrl = recentMangaArr[indexPath.row].preview_image_url{
                        if !previewImageUrl.isEmpty{
                            // preview image url is exists
                            DispatchQueue.global(qos: .background).async {
                                do{
                                    let url = URL(string: previewImageUrl)
                                    
                                    if let url = url{
                                        let data = try Data(contentsOf: url)
                                        
                                        DispatchQueue.main.async {
                                            collectionCell.previewImage.image = UIImage(data: data)
                                            collectionCell.previewImagePlaceholderLabel.isHidden = true
                                        }
                                    }else{
                                        DispatchQueue.main.async {
                                            collectionCell.previewImagePlaceholderLabel.isHidden = false
                                        }
                                    }
                                }catch{
                                    DispatchQueue.main.async {
                                        collectionCell.previewImagePlaceholderLabel.isHidden = false
                                    }
                                    print(error.localizedDescription)
                                }
                            }
                        }
                    }else{
                        collectionCell.previewImagePlaceholderLabel.isHidden = false
                    }
                }
            }else{
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
        
        if collectionView == updatedMangaCollectionView {
            link = updatedMangaArr[indexPath.row].link
        }else{
            if let mangaUrl = recentMangaArr[indexPath.row].link{
                link = mangaUrl
            }
        }
        
        // check link does have baseUrl
        if !link.contains(baseUrl){
            link = "\(baseUrl)\(link)"
        }
        
        // pass data
        destStoryboard.mangaUrl = link
        
        // save to history
        if indexPath.row < updatedMangaArr.count{
            let manga = updatedMangaArr[indexPath.row]
            
            if let previewImageUrl = manga.previewImageUrl, let previewImage = manga.previewImage{
                saveToMangaHistory(mangaTitle: manga.title, mangaLink: manga.link, mangaPreviewImageUrl: previewImageUrl, mangaPreviewImage: previewImage)
            }else{
                saveToMangaHistory(mangaTitle: manga.title, mangaLink: manga.link, mangaPreviewImageUrl: nil, mangaPreviewImage: nil)
            }
        }
        
        present(destStoryboard, animated: true, completion: nil)
    }
}



extension ViewController: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return topRankMangaArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let topRankCell = tableView.dequeueReusableCell(withIdentifier: "TopRankMangaCell", for: indexPath) as! TopRankMangaCell
        
        // Custom Selection Style
        let rect = CGRect(x: 0, y: 0, width: 200, height: 200)
        let selectedUIView = UIView(frame: rect)
        selectedUIView.layer.cornerRadius = 10
        selectedUIView.backgroundColor = UIColor(named: "CellSelectionColor")
        topRankCell.selectedBackgroundView = selectedUIView
        
        topRankCell.rankLabel.text = String(indexPath.row + 1)
        
        if indexPath.row < updatedMangaArr.count{
            topRankCell.titleLabel.text = topRankMangaArr[indexPath.row].title
        }
        
        return topRankCell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        
        let destStroyboard = mainStoryboard.instantiateViewController(identifier: "ViewMangaStoryboard") as! ViewMangaViewController
        
        destStroyboard.modalPresentationStyle = .fullScreen
        
        var link = topRankMangaArr[indexPath.row].link
        
        if !link.contains(baseUrl) {
            link = "\(baseUrl)\(link)"
        }
        
        destStroyboard.mangaUrl = link
        
        // save to history
        if indexPath.row < topRankMangaArr.count{
            let manga = topRankMangaArr[indexPath.row]
                        
            saveToMangaHistory(mangaTitle: manga.title, mangaLink: manga.link, mangaPreviewImageUrl: nil, mangaPreviewImage: nil)
            
        }
        
        present(destStroyboard, animated: true, completion: nil)
    }
}
