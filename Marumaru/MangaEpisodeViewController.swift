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
import Hero
import RxSwift
import RxCocoa

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
    var disposeBag = DisposeBag()
    
    var infoTitle = ""
    var infoDesc1 = ""
    var infoDesc2 = ""
    var infoPreviewImageUrl = ""
    
    let networkHandler = NetworkHandler()
    var episodeArr = [Episode]()
    
    var loadingEpisodeAnimView = AnimationView()
    
    @IBOutlet weak var appbarView: UIView!
    @IBOutlet weak var infoContentView: UIView!
    @IBOutlet weak var infoPreviewImage: UIImageView!
    @IBOutlet weak var mangaTitleLabel: UILabel!
    @IBOutlet weak var infoDesc1Label: UILabel!
    @IBOutlet weak var infoDesc2Label: UILabel!
    @IBOutlet weak var episodeSizeLabel: UILabel!
    @IBOutlet weak var scrollToBottomButton: UIButton!
    @IBOutlet weak var mangaEpisodeTableView: UITableView!
    @IBOutlet weak var backButton: UIButton!
    
    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()

        initView()
        initInstance()
        
        getData()
        setMangaInfo()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .darkContent
    }
    
    // MARK: - Initializations
    func initView() {
        // hero enable
        self.hero.isEnabled = true
        
        // appbar View
        appbarView.hero.id = "appbar"
        appbarView.layer.cornerRadius = 40
        appbarView.layer.maskedCorners = [.layerMinXMaxYCorner]
        
        // back Button
        backButton.hero.id = "appbarButton"
        backButton.imageEdgeInsets(with: 10)
        backButton.layer.masksToBounds = true
        backButton.layer.cornerRadius = 13
        
        // manga info View
        infoContentView.hero.id = "infoContentView"
        infoContentView.layer.cornerRadius = 15
        infoContentView.layer.shadowColor = ColorSet.shadowColor?.cgColor
        infoContentView.layer.shadowOffset = .zero
        infoContentView.layer.shadowRadius = 8
        infoContentView.layer.shadowOpacity = 0.5
        
        // manga info Preview ImageView
        infoPreviewImage.hero.id = "previewImage"
        infoPreviewImage.layer.masksToBounds = true
        infoPreviewImage.layer.cornerRadius = 10
        infoPreviewImage.layer.borderWidth = 1
        infoPreviewImage.layer.borderColor = ColorSet.imageBorderColor?.cgColor
        
        // manga title Label
        mangaTitleLabel.hero.id = "mangaTitleLabel"
        
        // scrollToBottom Button
        scrollToBottomButton.layer.cornerRadius = 13
        scrollToBottomButton.imageEdgeInsets(with: 10)
        scrollToBottomButton.hero.modifiers = [.translate(y: 100)]
        
        // Loading Episode AnimView
        loadingEpisodeAnimView = AnimationView(name: "loading_square")
        loadingEpisodeAnimView.frame = CGRect(x: 0, y: 0, width: 300, height: 300)
        self.view.addSubview(loadingEpisodeAnimView)
        loadingEpisodeAnimView.translatesAutoresizingMaskIntoConstraints = false
        loadingEpisodeAnimView.centerXAnchor.constraint(equalTo: mangaEpisodeTableView.centerXAnchor).isActive = true
        loadingEpisodeAnimView.centerYAnchor.constraint(equalTo: mangaEpisodeTableView.centerYAnchor, constant: -50).isActive = true
        loadingEpisodeAnimView.isHidden = true
    }
    
    func initInstance() {
        mangaEpisodeTableView.delegate = self
        mangaEpisodeTableView.dataSource = self
    }
    
    // MARK: - Methods
    func startLoadingEpisodeAnim() {
        DispatchQueue.main.async {
            self.loadingEpisodeAnimView.isHidden = false
            self.loadingEpisodeAnimView.play()
        }
    }
    
    func stopLoadingEpisodeAnim() {
        DispatchQueue.main.async {
            self.loadingEpisodeAnimView.isHidden = true
            self.loadingEpisodeAnimView.stop()
        }
    }
    
    func getData() {
        if episodeArr.count > 0 {
            return
        }
        
        startLoadingEpisodeAnim()
        
        DispatchQueue.global(qos: .background).async {
            if let serialNumber = self.mangaSN {
                do {
                    let completeUrl = "\(self.baseUrl)/bbs/cmoic/\(serialNumber)"
                    
                    print(completeUrl)
                    guard let url = URL(string: completeUrl) else {return}
                    let htmlContent = try String(contentsOf: url, encoding: .utf8)
                    let doc = try SwiftSoup.parse(htmlContent)
                    
                    // Getting Infos
                    let headElement = try doc.getElementsByClass("list-wrap")
                    
                    if let superElement = headElement.first() {
                        let tbody = try superElement.getElementsByTag("tbody")
                        
                        if let tbody = tbody.first() {
                            let episodeElement = try tbody.getElementsByTag("tr")
                            
                            try episodeElement.forEach { (Element) in
                                let title = try Element.select("a").text().trimmingCharacters(in: .whitespaces)
                                let description = try Element.getElementsByTag("span").text()
                                
                                var link = String(try Element.select("a").attr("href"))
                                if link != "" && !link.contains(self.baseUrl) {
                                    link = "\(self.baseUrl)\(link)"
                                }
                                
                                var previewImageUrl = String(try Element.select("img").attr("src"))
                                if !previewImageUrl.isEmpty && !previewImageUrl.contains(self.baseImgUrl) {
                                    previewImageUrl = "\(self.baseImgUrl)\(previewImageUrl)"
                                }
                                
                                self.episodeArr.append(Episode(title: title, description: description, previewImageUrl: previewImageUrl, link: link))
                            }
                        }
                        
                        DispatchQueue.main.async {
                            self.mangaEpisodeTableView.reloadData()
                            self.episodeSizeLabel.text = "총 \(self.episodeArr.count)화"
                            
                            self.stopLoadingEpisodeAnim()
                        }
                        
                    } else {
                        // no episodes
                        self.stopLoadingEpisodeAnim()
                    }
                    
                } catch {
                    print(error.localizedDescription)
                }
            } else {
                DispatchQueue.main.async {
                    self.mangaTitleLabel.text = "Fail to load"
                    self.infoPreviewImage.image = UIImage(named: "empty-image")!
                }
            }
        }
    }
    
    func setMangaInfo() {
        mangaTitleLabel.text = infoTitle
        infoDesc1Label.text = infoDesc1
        infoDesc2Label.text = infoDesc2
        
        if infoDesc2.contains("미분류") {
            infoDesc2Label.textColor = ColorSet.subTextColor
        } else {
            infoDesc2Label.textColor = ColorSet.subTextColor
        }
        
        DispatchQueue.global(qos: .background).async {
            if self.infoPreviewImageUrl != ""{
                if let url = URL(string: self.infoPreviewImageUrl) {
                    self.networkHandler.getImage(url) { result in
                        do {
                            let result = try result.get()
                            
                            DispatchQueue.main.async {
                                self.infoPreviewImage.contentMode = .scaleAspectFill
                                self.infoPreviewImage.image = result.imageCache.image
                                
                                print("image has loaded")
                                if result.animate {
                                    self.infoPreviewImage.startFadeInAnim(duration: 0.3)
                                }
                                
                                // change preview image's border color as average color of image
                                self.infoPreviewImage.layer.borderColor = result.imageCache.averageColor.cgColor
                            }
                        } catch {
                            DispatchQueue.main.async {
                                self.infoPreviewImage.image = UIImage(named: "empty-image")!
                                self.infoPreviewImage.contentMode = .scaleAspectFit
                            }
                            print(error.localizedDescription)
                        }
                    }
                }
            } else {
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
    
    func fadeScrollToBottomButton(bool: Bool) {
        if bool {
            // fade out
            UIView.animate(withDuration: 0.3) {
                self.scrollToBottomButton.alpha = 0
            }
        } else {
            // fade in
            UIView.animate(withDuration: 0.3) {
                self.scrollToBottomButton.alpha = 1
            }
        }
    }
    
    // MARK: - Actions
    @IBAction func scrollToBottomButtonAction(_ sender: Any) {
        DispatchQueue.main.async {

            if self.mangaEpisodeTableView.contentSize.height > 0 {
                let indexPath = IndexPath(row: self.episodeArr.count - 1, section: 0)
                
                self.mangaEpisodeTableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
            }
        }
    }
    
    @IBAction func backButtonAction(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
}

// MARK: - Extenstions
extension MangaEpisodeViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return episodeArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let episodeCell = tableView.dequeueReusableCell(withIdentifier: "EpisodeCell") as! MangaEpisodeCell
        
        if indexPath.row > episodeArr.count - 1 {
            return UITableViewCell()
        }
        
        episodeCell.episodeTitleLabel.text = episodeArr[indexPath.row].title
        episodeCell.episodeDescLabel.text = episodeArr[indexPath.row].description
        episodeCell.episodeIndexLabel.text = String(episodeArr.count - indexPath.row)
        episodeCell.previewImage.image = nil
        
        if let previewImageUrl = episodeArr[indexPath.row].previewImageUrl {
            if let url = URL(string: previewImageUrl) {
                let token = self.networkHandler.getImage(url) { result in
                    DispatchQueue.global(qos: .background).async {
                        do {
                            let result = try result.get()
                            
                            DispatchQueue.main.async {
                                episodeCell.previewImage.image = result.imageCache.image
                                
                                if result.animate {
                                    episodeCell.previewImage.startFadeInAnim(duration: 0.5)
                                }
                            }
                        } catch {
                            print(error.localizedDescription)
                        }
                    }
                }
                
                // stop loading image on reuse State
                episodeCell.onReuse = {
                    if let token = token {
                        self.networkHandler.cancelLoadImage(token)
                    }
                }
            }
        }
        
        return episodeCell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if episodeArr.count > indexPath.row {
            let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
            let destStoryboard = mainStoryboard.instantiateViewController(identifier: "ViewMangaStoryboard") as! ViewMangaViewController
            
            destStoryboard.modalPresentationStyle = .fullScreen
            
            var mangaLink = episodeArr[indexPath.row].link
            let mangaTitle = episodeArr[indexPath.row].title.trimmingCharacters(in: .whitespaces)
            
            if !mangaLink.contains(baseUrl) {
                mangaLink = "\(baseUrl)\(mangaLink)"
            }
            
            destStoryboard.mangaUrl = mangaLink
            destStoryboard.mangaTitle = mangaTitle
            
            present(destStoryboard, animated: true, completion: nil)
        }
    }
}

extension MangaEpisodeViewController: UIScrollViewDelegate {
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        let actualPosition = scrollView.panGestureRecognizer.translation(in: scrollView.superview)
        
        if actualPosition.y > 0 {
            // Scrolling up
            fadeScrollToBottomButton(bool: true)
        } else {
            // Scrolling down
            fadeScrollToBottomButton(bool: false)
        }
    }
}
