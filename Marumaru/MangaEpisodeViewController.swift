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

    // MARK: - Declarations
    struct Episode {
        var title: String
        var description: String
        var previewImageUrl: String?
        var link: String
    }
    
    let baseUrl = "https://marumaru.cloud"
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
    @IBOutlet weak var episodeSizeLabel: UILabel!
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var scrollToBottomButton: UIButton!
    
    @IBOutlet weak var mangaEpisodeTableView: UITableView!
    
    
    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()

        initView()
        initInstance()
        
        getData()
        setMangaInfo()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        setLottieAnims()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle{
        return .darkContent
    }
    
    // MARK: - Initializations
    func initView(){
        infoView.layer.cornerRadius = 15
        infoView.layer.shadowColor = UIColor(named: "ShadowColor")!.cgColor
        infoView.layer.shadowOffset = .zero
        infoView.layer.shadowRadius = 8
        infoView.layer.shadowOpacity = 0.5
        
        infoPreviewImage.layer.masksToBounds = true
        infoPreviewImage.layer.cornerRadius = 10
        infoPreviewImage.layer.borderWidth = 1
        infoPreviewImage.layer.borderColor = UIColor(named: "PointColor")?.cgColor
        
        // scroll to bottom button
        scrollToBottomButton.layer.cornerRadius = 10
        scrollToBottomButton.layer.shadowColor = UIColor(named: "ShadowColor")!.cgColor
        scrollToBottomButton.layer.shadowRadius = 7
        scrollToBottomButton.layer.shadowOpacity = 0.5
        scrollToBottomButton.layer.shadowOffset = .zero
    }
    
    func initInstance(){
        mangaEpisodeTableView.delegate = self
        mangaEpisodeTableView.dataSource = self
    }
    
    // MARK: - Methods
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
                    let completeUrl = "\(self.baseUrl)/bbs/cmoic/\(serialNumber)"
//                    let completeUrl = "\(self.baseUrl)\(serialNumber)"
                    
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
                                let title = try Element.select("a").text().trimmingCharacters(in: .whitespaces)
                                let description = try Element.getElementsByTag("span").text()
                                
                                var link = String(try Element.select("a").attr("href"))
                                if link != "" && !link.contains(self.baseUrl){
                                    link = "\(self.baseUrl)\(link)"
                                }
                                
                                var previewImageUrl = String(try Element.select("img").attr("src"))
                                if !previewImageUrl.isEmpty && !previewImageUrl.contains(self.baseImgUrl){
                                    previewImageUrl = "\(self.baseImgUrl)\(previewImageUrl)"
                                }
                                
                                self.episodeArr.append(Episode(title: title, description: description, previewImageUrl: previewImageUrl, link: link))
                            }
                        }
                        
                        DispatchQueue.main.async {
                            self.mangaEpisodeTableView.reloadData()
                            self.episodeSizeLabel.text = "총 \(self.episodeArr.count)화"
                            
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
        
        if infoDesc2.contains("미분류"){
            infoDesc2Label.textColor = UIColor(named: "BasicSubTextColor")!
        }else{
            infoDesc2Label.textColor = UIColor(named: "SubPointColor")!
        }
        
        DispatchQueue.global(qos: .background).async {
            if self.infoPreviewImageUrl != ""{
                if let url = URL(string: self.infoPreviewImageUrl){
                    self.networkHandler.getImage(url){ result in
                        do{
                            let image = try result.get()
                            
                            DispatchQueue.main.async {
                                self.infoPreviewImage.contentMode = .scaleAspectFill
                                self.infoPreviewImage.image = image
                                
                                self.infoPreviewImage.alpha = 0
                                UIView.animate(withDuration: 0.3) {
                                    self.infoPreviewImage.alpha = 1
                                }
                                
                                // change preview image's border color as average color of image
                                self.infoPreviewImage.layer.borderColor = image.averageColor?.cgColor
                            }
                        }catch{
                            DispatchQueue.main.async {
                                self.infoPreviewImage.image = UIImage(named: "empty-image")!
                                self.infoPreviewImage.contentMode = .scaleAspectFit
                            }
                            print(error.localizedDescription)
                        }
                    }
                }
            }else{
                DispatchQueue.main.async {
                    self.infoPreviewImage.image = UIImage(named: "empty-image")!
                    self.infoPreviewImage.contentMode = .scaleAspectFit
                }
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
    
    
    func fadeScrollToBottomButton(bool: Bool){
        if bool {
            // fade out
            UIView.animate(withDuration: 0.3) {
                self.scrollToBottomButton.alpha = 0
            }
        }else{
            // fade in
            UIView.animate(withDuration: 0.3) {
                self.scrollToBottomButton.alpha = 1
            }
        }
    }
    
    
    // MARK: - Actions
    @IBAction func scrollToBottomButtonAction(_ sender: Any) {
        DispatchQueue.main.async {

            if self.mangaEpisodeTableView.contentSize.height > 0{
                let indexPath = IndexPath(row: self.episodeArr.count - 1, section: 0)
                
                self.mangaEpisodeTableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
            }
        }
    }
    
}


// MARK: - Extenstions
extension MangaEpisodeViewController: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return episodeArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let episodeCell = tableView.dequeueReusableCell(withIdentifier: "EpisodeCell") as! MangaEpisodeCell
        
        if indexPath.row > episodeArr.count - 1{
            return UITableViewCell()
        }
        
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
        
        if episodeArr.count > indexPath.row{
            let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
            let destStoryboard = mainStoryboard.instantiateViewController(identifier: "ViewMangaStoryboard") as! ViewMangaViewController
            
            destStoryboard.modalPresentationStyle = .fullScreen
            
            var mangaLink = episodeArr[indexPath.row].link
            let mangaTitle = episodeArr[indexPath.row].title.trimmingCharacters(in: .whitespaces)
            
            if !mangaLink.contains(baseUrl){
                mangaLink = "\(baseUrl)\(mangaLink)"
            }
            
            destStoryboard.mangaUrl = mangaLink
            destStoryboard.mangaTitle = mangaTitle
            
            present(destStoryboard, animated: true, completion: nil)
        }
    }
}



extension MangaEpisodeViewController: UIScrollViewDelegate{
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        let actualPosition = scrollView.panGestureRecognizer.translation(in: scrollView.superview)
        
        if (actualPosition.y > 0){
            // Scrolling up
            fadeScrollToBottomButton(bool: true)
        }else{
            // Scrolling down
            fadeScrollToBottomButton(bool: false)
        }
    }
}
