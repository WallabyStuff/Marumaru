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
    let baseUrl = "https://marumaru.cloud"
    let baseImgUrl = "https://marumaru.cloud"
    public var mangaSN: String?
    var disposeBag = DisposeBag()
    
    var currentManga: MangaInfo?
    
    let networkHandler = NetworkHandler()
    var episodeArr = [MangaEpisode]()
    
    var loadingEpisodeAnimView = AnimationView()
    
    @IBOutlet weak var appbarView: UIView!
    @IBOutlet weak var infoContentView: UIView!
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var mangaTitleLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var updateCycleLabel: UILabel!
    @IBOutlet weak var episodeSizeLabel: UILabel!
    @IBOutlet weak var scrollToBottomButton: UIButton!
    @IBOutlet weak var mangaEpisodeTableView: UITableView!
    @IBOutlet weak var backButton: UIButton!
    
    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()

        initView()
        initInstance()
        initMangaInfo()
        
        getData()
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
        thumbnailImageView.hero.id = "previewImage"
        thumbnailImageView.layer.masksToBounds = true
        thumbnailImageView.layer.cornerRadius = 10
        thumbnailImageView.layer.borderWidth = 1
        thumbnailImageView.layer.borderColor = ColorSet.floatingViewBackgroundColor?.cgColor
        thumbnailImageView.backgroundColor = ColorSet.floatingViewBackgroundColor
        
        // manga title Label
        mangaTitleLabel.hero.id = "mangaTitleLabel"
        
        // episode size Label
        episodeSizeLabel.hero.modifiers = [.translate(x: -150)]
        
        // scrollToBottom Button
        scrollToBottomButton.layer.cornerRadius = 13
        scrollToBottomButton.imageEdgeInsets(with: 10)
        scrollToBottomButton.hero.modifiers = [.translate(y: 100)]
        
        // Loading Episode AnimView
        loadingEpisodeAnimView = AnimationView(name: "loading_square")
        loadingEpisodeAnimView.frame = CGRect(x: 0, y: 0, width: 300, height: 300)
        loadingEpisodeAnimView.loopMode = .loop
        loadingEpisodeAnimView.isHidden = true
        self.view.addSubview(loadingEpisodeAnimView)
        loadingEpisodeAnimView.translatesAutoresizingMaskIntoConstraints = false
        loadingEpisodeAnimView.centerXAnchor.constraint(equalTo: mangaEpisodeTableView.centerXAnchor).isActive = true
        loadingEpisodeAnimView.centerYAnchor.constraint(equalTo: mangaEpisodeTableView.centerYAnchor, constant: -50).isActive = true
    }
    
    func initInstance() {
        // manga episode TableView
        let mangaEpisodeTableCellNib = UINib(nibName: "MangaEpisodeTableViewCell", bundle: nil)
        mangaEpisodeTableView.register(mangaEpisodeTableCellNib, forCellReuseIdentifier: "mangaEpisodeTableCell")
        mangaEpisodeTableView.delegate = self
        mangaEpisodeTableView.dataSource = self
    }
    
    func initMangaInfo() {
        guard let currentManga = currentManga else {
            dismiss(animated: true, completion: nil)
            return
        }
        
        mangaTitleLabel.text = currentManga.title
        authorLabel.text = currentManga.author
        updateCycleLabel.text = currentManga.updateCycle
        
        if !currentManga.updateCycle.contains("미분류") {
            updateCycleLabel.makeRoundedBackground(cornerRadius: 8,
                                                  backgroundColor: ColorSet.labelEffectBackgroundColor!,
                                                  foregroundColor: ColorSet.labelEffectForegroundColor!)
        }
        
        if currentManga.thumbnailImage != nil {
            thumbnailImageView.image = currentManga.thumbnailImage
            thumbnailImageView.layer.borderColor = currentManga.thumbnailImage?.averageColor?.cgColor
        } else {
            // if thumbnail image was not passed from search result cell
            if let thumbnailImageURL = currentManga.thumbnailImageURL {
                if let url = URL(string: thumbnailImageURL) {
                    networkHandler.getImage(url) { result in
                        do {
                            let result = try result.get()
                            DispatchQueue.main.async {
                                self.thumbnailImageView.image = result.imageCache.image
                                self.thumbnailImageView.startFadeInAnim(duration: 0.3)
                                self.thumbnailImageView.layer.borderColor = UIColor(hexString: result.imageCache.imageAvgColorHex).cgColor
                            }
                        } catch {
                            print(error)
                        }
                    }
                }
            }
        }
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
    
    // get episode data from url
    // TODO: move function to network handler
    func getData() {
        if episodeArr.count > 0 {
            return
        }
        
        startLoadingEpisodeAnim()
        
        DispatchQueue.global(qos: .background).async {
            do {
                let completeUrl = "\(self.baseUrl)/bbs/cmoic/\(self.currentManga!.mangaSN)"
                
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
                            
                            self.episodeArr.append(MangaEpisode(title: title, description: description, thumbnailImageURL: previewImageUrl, mangaURL: link))
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
    
    func presentViewMangaVC(_ mangaTitle: String, _ mangaUrl: String) {
        guard let viewMangaVC = storyboard?.instantiateViewController(identifier: "ViewMangaStoryboard") as? ViewMangaViewController else { return }
        viewMangaVC.modalPresentationStyle = .fullScreen
        
        viewMangaVC.mangaUrl = mangaUrl
        viewMangaVC.mangaTitle = mangaTitle
        
        present(viewMangaVC, animated: true, completion: nil)
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
        guard let episodeCell = tableView.dequeueReusableCell(withIdentifier: "mangaEpisodeTableCell") as? MangaEpisodeTableCell else { return UITableViewCell() }
        
        if indexPath.row > episodeArr.count - 1 {
            return UITableViewCell()
        }
        
        episodeCell.titleLabel.text = episodeArr[indexPath.row].title
        episodeCell.descriptionLabel.text = episodeArr[indexPath.row].description
        episodeCell.indexLabel.text = String(episodeArr.count - indexPath.row)
        episodeCell.thumbnailImageView.image = nil
        
        if let previewImageUrl = episodeArr[indexPath.row].thumbnailImageURL {
            if let url = URL(string: previewImageUrl) {
                let token = self.networkHandler.getImage(url) { result in
                    DispatchQueue.global(qos: .background).async {
                        do {
                            let result = try result.get()
                            
                            DispatchQueue.main.async {
                                episodeCell.thumbnailImageView.image = result.imageCache.image
                                
                                if result.animate {
                                    episodeCell.thumbnailImageView.startFadeInAnim(duration: 0.5)
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
            var mangaUrl = episodeArr[indexPath.row].mangaURL
            let mangaTitle = episodeArr[indexPath.row].title.trimmingCharacters(in: .whitespaces)
            
            if !mangaUrl.contains(baseUrl) {
                mangaUrl = "\(baseUrl)\(mangaUrl)"
            }
            
            presentViewMangaVC(mangaTitle, mangaUrl)
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
