//
//  MangaContentViewController.swift
//  Marumaru
//
//  Created by 이승기 on 2021/04/08.
//

import UIKit
import SwiftSoup
import Toast
import Lottie
import CoreData

class MangaEpisodeViewController: UIViewController {

    struct Episode {
        var title: String
        var description: String
        var previewImageUrl: String?
        var previewImage: UIImage?
        var link: String
    }
    
    let baseUrl = "https://marumaru.cloud/bbs/cmoic/"
    let baseImgUrl = "https://marumaru.cloud"
    public var mangaSN: String?
    
    var infoTitle = ""
    var infoDesc1 = ""
    var infoDesc2 = ""
    var infoPreviewImageUrl = ""
    
    let networkHandler = NetworkHandler()
    var episodeArr = Array<Episode>()
    
    @IBOutlet weak var infoView: UIView!
    @IBOutlet weak var infoPreviewImage: UIImageView!
    @IBOutlet weak var infoTitleLabel: UILabel!
    @IBOutlet weak var infoDesc1Label: UILabel!
    @IBOutlet weak var infoDesc2Label: UILabel!
    @IBOutlet weak var mangaSizeLabel: UILabel!
    @IBOutlet weak var loadingView: UIView!
    
    @IBOutlet weak var mangaEpisodeTableView: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        initDesign()
        initInstance()
        
        getData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        setLottieAnims()
        setMangaInfo()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle{
        return .darkContent
    }
    
    func initDesign(){
        infoView.layer.cornerRadius = 15
        infoView.layer.shadowColor = UIColor(named: "PointColor")!.cgColor
        infoView.layer.shadowOffset = .zero
        infoView.layer.shadowRadius = 8
        infoView.layer.shadowOpacity = 0.5
        
        infoPreviewImage.layer.masksToBounds = true
        infoPreviewImage.layer.cornerRadius = 10
        infoPreviewImage.layer.borderWidth = 1
        infoPreviewImage.layer.borderColor = UIColor(named: "PointColor")?.cgColor
    }
    
    func initInstance(){
        mangaEpisodeTableView.delegate = self
        mangaEpisodeTableView.dataSource = self
    }
    
    func setLottieAnims(){
        // set manga episode loading anim -lottie-
        let loadingSquareAnimView = AnimationView(name: "loading_square")
        loadingSquareAnimView.frame = CGRect(x: 0, y: 0, width: 300, height: 300)
        loadingSquareAnimView.center = loadingView.center
        loadingSquareAnimView.loopMode = .loop
        loadingSquareAnimView.play()
        loadingView.addSubview(loadingSquareAnimView)
    }
    
    func getData(){
        if episodeArr.count > 0{
            return
        }
        
        loadingView.isHidden = false
        
        DispatchQueue.global(qos: .background).async {
            if let serialNumber = self.mangaSN{
                do{
                    let completeUrl = "\(self.baseUrl)\(serialNumber)"
                    
                    print(completeUrl)
                    guard let url = URL(string: completeUrl) else {return}
                    
                    let htmlContent = try String(contentsOf: url, encoding: .utf8)
                    let doc = try SwiftSoup.parse(htmlContent)
                    
                    
                    // Getting Infos
                    let headElement = try doc.getElementsByClass("list-wrap")
                    
                    if let superElement = headElement.first(){
                        let tbody = try superElement.getElementsByTag("tbody")
                        
                        if let tbody = tbody.first(){
                            let episodeElement = try tbody.getElementsByTag("tr")
                            
                            try episodeElement.forEach { (Element) in
                                let title = try Element.select("a").text()
                                let description = try Element.getElementsByTag("span").text()
                                
                                var link = String(try Element.select("a").attr("href"))
                                if link != "" && !link.contains(self.baseUrl){
                                    link = "\(self.baseUrl)\(link)"
                                }
                                
                                var previewImageUrl = String(try Element.select("img").attr("src"))
                                if !previewImageUrl.isEmpty && !previewImageUrl.contains(self.baseImgUrl){
                                    previewImageUrl = "\(self.baseImgUrl)\(previewImageUrl)"
                                }
                                
                                print("\(title)\n preview image url is \(previewImageUrl)")
                                
                                
                                self.episodeArr.append(Episode(title: title, description: description, previewImageUrl: previewImageUrl, previewImage: nil, link: link))
                            }
                        }
                        
                        DispatchQueue.main.async {
                            self.mangaEpisodeTableView.reloadData()
                            self.mangaSizeLabel.text = "총 \(self.episodeArr.count)화"
                            
                            self.loadingView.isHidden = true
                        }
                        
                    }else{
                        // no episodes
                        self.loadingView.isHidden = true
                    }
                    
                }catch{
                    print(error.localizedDescription)
                }
            }else{
                DispatchQueue.main.async {
                    self.infoTitleLabel.text = "Fail to load"
                    self.infoPreviewImage.image = UIImage(named: "empty-image")!
                }
            }
        }
    }
    
    func setMangaInfo(){
        infoTitleLabel.text = infoTitle
        infoDesc1Label.text = infoDesc1
        infoDesc2Label.text = infoDesc2
        
        DispatchQueue.global(qos: .background).async {
            if self.infoPreviewImageUrl != ""{
                do{
                    let url = URL(string: self.infoPreviewImageUrl)
                    let data = try Data(contentsOf: url!)
                    
                    DispatchQueue.main.async {
                        self.infoPreviewImage.alpha = 0
                        self.infoPreviewImage.image = UIImage(data: data)
                        self.infoPreviewImage.contentMode = .scaleAspectFill
                        
                        UIView.animate(withDuration: 0.5) {
                            self.infoPreviewImage.alpha = 1
                        }
                    }
                    
                }catch{
                    DispatchQueue.main.async {
                        self.infoPreviewImage.image = UIImage(named: "empty-image")!
                        self.infoPreviewImage.contentMode = .scaleAspectFit
                    }
                    
                    print(error.localizedDescription)
                }
            }else{
                DispatchQueue.main.async {
                    self.infoPreviewImage.image = UIImage(named: "empty-image")!
                    self.infoPreviewImage.contentMode = .scaleAspectFit
                }
            }
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
    
    // https://stackoverflow.com/questions/48576329/ios-urlstring-not-working-always
    func transformURLString(_ string: String) -> URLComponents? {
        guard let urlPath = string.components(separatedBy: "?").first else {
            return nil
        }
        var components = URLComponents(string: urlPath)
        if let queryString = string.components(separatedBy: "?").last {
            components?.queryItems = []
            let queryItems = queryString.components(separatedBy: "&")
            for queryItem in queryItems {
                guard let itemName = queryItem.components(separatedBy: "=").first,
                      let itemValue = queryItem.components(separatedBy: "=").last else {
                        continue
                }
                components?.queryItems?.append(URLQueryItem(name: itemName, value: itemValue))
            }
        }
        return components!
    }
}


extension MangaEpisodeViewController: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return episodeArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let episodeCell = tableView.dequeueReusableCell(withIdentifier: "EpisodeCell") as! MangaEpisodeCell
        
        episodeCell.episodeTitleLabel.text = episodeArr[indexPath.row].title
        episodeCell.episodeDescLabel.text = episodeArr[indexPath.row].description
        episodeCell.episodeIndexLabel.text = String(episodeArr.count - indexPath.row)
        episodeCell.previewImage.image = nil
        
        
        if let previewImageUrl = episodeArr[indexPath.row].previewImageUrl{
            if let url = URL(string: previewImageUrl){
                let token = self.networkHandler.getImage(url){ result in
                    DispatchQueue.global(qos: .background).async {
                        do{
                            let image = try result.get()
                            
                            DispatchQueue.main.async {
                                episodeCell.previewImage.image = image
                                
                                // fade in image animation
                                episodeCell.previewImage.alpha = 0
                                UIView.animate(withDuration: 0.5) {
                                    episodeCell.previewImage.alpha = 1
                                }
                            }
                        }catch{
                            print(error.localizedDescription)
                        }
                    }
                }
                
                episodeCell.onReuse = {
                    if let token = token{
                        self.networkHandler.cancelLoadImage(token)
                    }
                }
            }
        }
        
        
        return episodeCell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let destStoryboard = mainStoryboard.instantiateViewController(identifier: "ViewMangaStoryboard") as! ViewMangaViewController
        
        destStoryboard.modalPresentationStyle = .fullScreen
        
        var link = episodeArr[indexPath.row].link
        
        if !link.contains(baseUrl){
            link = "\(baseUrl)\(link)"
        }
        
        destStoryboard.mangaUrl = link
        
        print(episodeArr[indexPath.row].previewImage)
        
        // save to history
        if indexPath.row < episodeArr.count{
            let manga = episodeArr[indexPath.row]

            var previewImageUrl: String? = nil
            var previewImage: UIImage? = nil


            if let unwrappedPreviewImage = manga.previewImage{
                previewImage = unwrappedPreviewImage
            }

            if let unwrappedPreviewImageUrl = manga.previewImageUrl{
                previewImageUrl = unwrappedPreviewImageUrl
            }

            saveToMangaHistory(mangaTitle: manga.title, mangaLink: manga.link, mangaPreviewImageUrl: previewImageUrl, mangaPreviewImage: previewImage)
        }
        
        present(destStoryboard, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let lastElement = episodeArr.count - 1
        
        if indexPath.row == lastElement{
            print("load more")
        }
    }
    
}



