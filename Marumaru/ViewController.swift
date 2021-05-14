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
    let coredataHandler = CoreDataHandler()
    var updatedMangaArr = Array<UpdatedManga>()
    var recentMangaArr = Array<WatchHistory>()
    var topRankMangaArr = Array<TopRankManga>()
    

    @IBOutlet weak var appBarView: UIView!
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
        
        initView()
        initInstance()
        
        setMainContents()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        setLottieAnims()
        loadMangaHistory()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle{
        return .darkContent
    }
    
    
    func initView(){
        homeIcon.image = homeIcon.image!.withRenderingMode(.alwaysTemplate)
        searchButton.imageView?.image = searchButton.imageView?.image?.withRenderingMode(.alwaysTemplate)
        
        updatedMangaCollectionView.contentInset = UIEdgeInsets(top: 0, left: 25, bottom: 0, right: 25)
        recentMangaCollectionView.contentInset = UIEdgeInsets(top: 0, left: 25, bottom: 0, right: 25)
        
        topRankMangaTableView.layer.cornerRadius = 10
        topRankMangaTableView.layer.masksToBounds = true
        
        // init appbar height
        let topSafeAreaHeight = UIApplication.shared.windows[0].safeAreaInsets.top
        appBarView.heightAnchor.constraint(equalToConstant: topSafeAreaHeight + 80).isActive = true
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
            
            for (_, Element) in updatedMangas.enumerated(){
                
                let title = try Element.select("a").text().trimmingCharacters(in: .whitespaces)
                var imgUrl = try String(Element.select("img").attr("src")).trimmingCharacters(in: .whitespaces)
                let link = try Element.select("a").attr("href").trimmingCharacters(in: .whitespaces)
                
                // url preset
                if !imgUrl.contains(self.baseUrl) {
                    imgUrl = "\(baseUrl)\(imgUrl)"
                }
                
                self.updatedMangaArr.append(UpdatedManga(title: title, link: link, previewImageUrl: imgUrl))
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
            
            for (_, Element) in rankElements.enumerated(){
                do{
                    let title = try Element.select("a").text().trimmingCharacters(in: .whitespaces)
                    let link = try Element.select("a").attr("href").trimmingCharacters(in: .whitespaces)
                    
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
    
    
    func loadMangaHistory(){
        coredataHandler.getWatchHistory(){ Result in
            do{
                let recentMangas = try Result.get()
                // check has history update
                if !self.recentMangaArr.elementsEqual(recentMangas){
                    self.recentMangaArr = recentMangas
                    
                    DispatchQueue.main.async {
                        if self.recentMangaArr.count > 0{
                            self.recentMangaPlaceholderLabel.isHidden = true
                        }else{
                            self.recentMangaPlaceholderLabel.isHidden = false
                        }
                        
                        self.recentMangaCollectionView.reloadData()
                    }
                }
            }catch{
                print(error.localizedDescription)
                
                DispatchQueue.main.async {
                    self.recentMangaArr.removeAll()
                    self.recentMangaCollectionView.reloadData()
                    self.recentMangaPlaceholderLabel.isHidden = false
                }
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
        let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let destStoryboard = mainStoryboard.instantiateViewController(identifier: "MangaHistoryStoryboard") as! MangaHistoryViewController
        destStoryboard.dismissDelegate = self
        
        present(destStoryboard, animated: true)
    }
}



extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource{
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
            
            if indexPath.row > updatedMangaArr.count - 1{
                return UICollectionViewCell()
            }
            
            
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
            
            return collectionCell
        case recentMangaCollectionView:
            let collectionCell = collectionView.dequeueReusableCell(withReuseIdentifier: "RecentMangaCell", for: indexPath) as! MangaCollectionCell
            
            if indexPath.row > recentMangaArr.count - 1{
                return UICollectionViewCell()
            }
            
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
                            if let url = URL(string: previewImageUrl){
                                networkHandler.getImage(url){result in
                                    DispatchQueue.global(qos: .background).async {
                                        do{
                                            let image = try result.get()
                                            
                                            DispatchQueue.main.async {
                                                collectionCell.previewImage.image = image
                                                collectionCell.previewImagePlaceholderLabel.isHidden = true
                                                
                                                // preview image fade in animation
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
                            }else{
                                collectionCell.previewImagePlaceholderLabel.isHidden = false
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
        var title = ""
        
        // check collectionview type
        if collectionView == updatedMangaCollectionView {
            link = updatedMangaArr[indexPath.row].link
            title = updatedMangaArr[indexPath.row].title
        }else{
            link = recentMangaArr[indexPath.row].link!
            title = recentMangaArr[indexPath.row].title!
        }
        
        // check link does have baseUrl
        if !link.contains(baseUrl){
            link = "\(baseUrl)\(link)"
        }
        
        // pass data
        destStoryboard.mangaUrl = link
        destStoryboard.mangaTitle = title
        
        present(destStoryboard, animated: true, completion: nil)
    }
}



extension ViewController: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return topRankMangaArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let topRankCell = tableView.dequeueReusableCell(withIdentifier: "TopRankMangaCell", for: indexPath) as! TopRankMangaCell
        
        if indexPath.row > topRankMangaArr.count - 1{
            return UITableViewCell()
        }
        
        // Custom Selection Style
        let rect = CGRect(x: 0, y: 0, width: 200, height: 200)
        let selectedUIView = UIView(frame: rect)
        selectedUIView.layer.cornerRadius = 10
        selectedUIView.backgroundColor = UIColor(named: "CellSelectionColor")
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

extension ViewController: DismissDelegate{
    func refreshHistory() {
        self.loadMangaHistory()
    }
}


public extension UIImage {
    var averageColor: UIColor? {
        guard let inputImage = CIImage(image: self) else { return nil }
        let extentVector = CIVector(x: inputImage.extent.origin.x, y: inputImage.extent.origin.y, z: inputImage.extent.size.width, w: inputImage.extent.size.height)

        guard let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: inputImage, kCIInputExtentKey: extentVector]) else { return nil }
        guard let outputImage = filter.outputImage else { return nil }

        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: kCFNull])
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)

        return UIColor(red: CGFloat(bitmap[0]) / 255, green: CGFloat(bitmap[1]) / 255, blue: CGFloat(bitmap[2]) / 255, alpha: CGFloat(bitmap[3]) / 255)
    }
}
