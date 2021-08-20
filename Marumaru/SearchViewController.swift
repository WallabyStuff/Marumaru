//
//  SearchViewController.swift
//  Marumaru
//
//  Created by 이승기 on 2021/04/12.
//

import UIKit

import SwiftSoup
import Lottie
import Hero
import RxSwift
import RxCocoa

class SearchViewController: UIViewController {

    // MARK: - Declarations
    var disposeBag = DisposeBag()
    let baseUrl = "https://marumaru.cloud"
    let searchUrl = "/bbs/search.php?url=%2Fbbs%2Fsearch.php&stx="
    let networkHandler = NetworkHandler()
    var searchResultMangaArr: [MangaInfo] = []
    var loadingSearchAnimView = AnimationView()
    var isSearching = false
    
    @IBOutlet weak var appbarView: UIView!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var searchResultMangaTableView: UITableView!
    @IBOutlet weak var noResultsLabel: UILabel!
    @IBOutlet weak var backButton: UIButton!
    
    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()

        initView()
        initInstance()
        initEventListener()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        focusToSearchTextField()
    }

    // MARK: - Overrides
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .darkContent
    }
    
    // MARK: - Initializations
    func initView() {
        // hero enable
        self.hero.isEnabled = true
        
        // appbarView
        appbarView.hero.id = "appbar"
        appbarView.layer.cornerRadius = 40
        appbarView.layer.maskedCorners = CACornerMask([.layerMaxXMaxYCorner, .layerMinXMaxYCorner])
        
        // search TextField
        searchTextField.layer.cornerRadius = 15
        searchTextField.layer.borderWidth = 2
        searchTextField.layer.borderColor = ColorSet.accentColor?.cgColor
        
        // Add padding to search textfield
        let paddingView = UIView(frame: CGRect(x: 0,
                                               y: 0,
                                               width: 15,
                                               height: self.searchTextField.frame.height))
        searchTextField.leftView = paddingView
        searchTextField.leftViewMode = .always
        
        // Textfield keyboard return type to search
        searchTextField.returnKeyType = .search
        searchTextField.delegate = self
        
        // back Button
        backButton.hero.id = "appbarButton"
        backButton.imageEdgeInsets(with: 10)
        backButton.layer.masksToBounds = true
        backButton.layer.cornerRadius = 13
        
        // search loading AnimView
        loadingSearchAnimView = AnimationView(name: "loading_square")
        loadingSearchAnimView.frame = CGRect(x: 0,
                                             y: 0,
                                             width: 300,
                                             height: 300)
        loadingSearchAnimView.loopMode = .loop
        view.addSubview(self.loadingSearchAnimView)
        loadingSearchAnimView.translatesAutoresizingMaskIntoConstraints = false
        loadingSearchAnimView.centerXAnchor.constraint(equalTo: self.searchResultMangaTableView.centerXAnchor).isActive = true
        loadingSearchAnimView.centerYAnchor.constraint(equalTo: self.searchResultMangaTableView.centerYAnchor, constant: -50).isActive = true
        loadingSearchAnimView.isHidden = true
        
        // result manga Tableview
        searchResultMangaTableView.contentInset = UIEdgeInsets(top: 60,
                                                         left: 0,
                                                         bottom: 40,
                                                         right: 0)
    }
    
    func initInstance() {
        // result manga TableView
        let searchResultMangaTableCellNib = UINib(nibName: "MangaThumbnailTableViewCell", bundle: nil)
        searchResultMangaTableView.register(searchResultMangaTableCellNib, forCellReuseIdentifier: "mangaThumbnailTableCell")
        searchResultMangaTableView.delegate = self
        searchResultMangaTableView.dataSource = self
        searchResultMangaTableView.keyboardDismissMode = .onDrag
    }
    
    func initEventListener() { }
    
    // MARK: - Methods
    func search(title: String) {
        
        searchResultMangaArr.removeAll()
        searchResultMangaTableView.reloadData()
        noResultsLabel.isHidden = true
        startLoadingSearchResultAnimation()
        isSearching = true
        view.endEditing(true)
        
        if title.count < 1 {
            stopLoadingSearchResultAnimation()
            noResultsLabel.isHidden = false
            self.view.makeToast("최소 한 글자 이상의 단어로 검색해주세요")
            
            return
        }
        
        DispatchQueue.global(qos: .background).async {
            let modifiedTitle = title.replacingOccurrences(of: " ", with: "+")
            let fullPath = "\(self.baseUrl)\(self.searchUrl)\(modifiedTitle)"
            
            let transformedUrl = self.transformURLString(fullPath)
            
            if let url = transformedUrl?.string {
                guard let searchUrl = URL(string: url) else {return}
                
                do {
                    let htmlContent = try String(contentsOf: searchUrl, encoding: .utf8)
                    let doc = try SwiftSoup.parse(htmlContent)
                    let resultElements = try doc.getElementsByClass("media")
                    
                    resultElements.forEach { (Element) in
                        do {
                            // get Title
                            let title = try Element.getElementsByClass("media-heading").text()
                            
                            // get Descriptions
                            var descs: [String] = []
                            let descElement = try Element.getElementsByClass("text-muted")
                            descElement.forEach { (Element) in
                                do {
                                    descs.append(try Element.text())
                                } catch {
                                    descs.append("")
                                    print(error.localizedDescription)
                                }
                            }
                            
                            // get Image
                            var imgUrl = String(try Element.select("img").attr("src"))
                            if !imgUrl.contains(self.baseUrl) && !imgUrl.isEmpty {
                                imgUrl = "\(self.baseUrl)\(imgUrl)"
                            }
                            
                            // get Link
                            var SN = ""
                            let link = String(try Element.select("a").attr("href"))
                            if let range = link.range(of: "sca=") {
                                SN = String(link[range.upperBound...])
                            }
                            
                            // Append to result array
                            let mangaInfo = MangaInfo(title: title,
                                                      author: descs[0],
                                                      updateCycle: descs[1],
                                                      thumbnailImage: nil,
                                                      thumbnailImageURL: imgUrl,
                                                      mangaSN: SN)
                            self.searchResultMangaArr.append(mangaInfo)
                            
                            print(title)
                        } catch {
                            print(error.localizedDescription)
                        }
                    }
                    
                    DispatchQueue.main.async {
                        self.searchResultMangaTableView.reloadData()
                        self.stopLoadingSearchResultAnimation()
                        self.isSearching = false
                        
                        if self.searchResultMangaArr.count == 0 {
                            self.noResultsLabel.isHidden = false
                        } else {
                            self.noResultsLabel.isHidden = true
                        }
                    }
                    
                } catch {
                    print(error.localizedDescription)
                }
            } else {
                // fail to transform the url
                return
            }
        }
    }
    
    func startLoadingSearchResultAnimation() {
        DispatchQueue.main.async {
            self.loadingSearchAnimView.isHidden = false
            self.loadingSearchAnimView.play()
        }
    }
    
    func stopLoadingSearchResultAnimation() {
        DispatchQueue.main.async {
            self.loadingSearchAnimView.isHidden = true
            self.loadingSearchAnimView.stop()
        }
    }
    
    func focusToSearchTextField() {
        // focus to search textField and show up the keyboard
        if searchResultMangaArr.count == 0 {
            searchTextField.becomeFirstResponder()
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
    
    private func presentEpisdoeVC(_ mangaInfo: MangaInfo) {
        guard let episodeVC = storyboard?.instantiateViewController(identifier: "MangaEpisodeStoryboard") as? MangaEpisodeViewController else { return }
        
        episodeVC.modalPresentationStyle = .fullScreen
        print("-------\(mangaInfo.mangaSN)=========")
        episodeVC.currentManga = mangaInfo
        
        present(episodeVC, animated: true, completion: nil)
    }
    
    // MARK: - Actions
    @IBAction func backButtonAction(_ sender: Any) {
        self.dismiss(animated: true)
    }
}

// MARK: - Extensions
extension SearchViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        // Seach action on keyboard
        if let title = textField.text?.trimmingCharacters(in: .whitespaces) {
            if isSearching {
                self.view.makeToast("please wait for searching")
                return true
            }
            
            search(title: title)
        }
        
        return true
    }
}

extension SearchViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResultMangaArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "mangaThumbnailTableCell") as? MangaThumbnailTableCell else { return UITableViewCell() }
        
        if indexPath.row > searchResultMangaArr.count - 1 {
            return UITableViewCell()
        }
        
        cell.titleLabel.text = searchResultMangaArr[indexPath.row].title
        cell.thumbnailImagePlaceholderLabel.text = searchResultMangaArr[indexPath.row].title
        cell.authorLabel.text = searchResultMangaArr[indexPath.row].author
        cell.updateCycleLabel.text = searchResultMangaArr[indexPath.row].updateCycle
        
        if !searchResultMangaArr[indexPath.row].updateCycle.contains("미분류") {
            cell.setUpdateCycleLabelBackgroundTint()
        }
        
        if let previewImageUrl = searchResultMangaArr[indexPath.row].thumbnailImageURL {
            if let url = URL(string: previewImageUrl) {
                let token = networkHandler.getImage(url) { result in
                    DispatchQueue.global(qos: .background).async {
                        do {
                            let result = try result.get()
                            DispatchQueue.main.async {
                                // image loaded
                                cell.thumbnailImageView.image = result.imageCache.image
                                cell.thumbnailImagePlaceholderLabel.isHidden = true
                                cell.thumbnailImageBaseView.setThumbnailShadow(with: result.imageCache.averageColor.cgColor)
                                self.searchResultMangaArr[indexPath.row].thumbnailImage = result.imageCache.image
                                
                                if result.animate {
                                    cell.thumbnailImageView.startFadeInAnim(duration: 0.5)
                                }
                            }
                        } catch {
                            DispatchQueue.main.async {
                                cell.thumbnailImagePlaceholderLabel.isHidden = false
                            }
                            print(error.localizedDescription)
                        }
                    }
                }
                
                cell.onReuse = {
                    if let token = token {
                        self.networkHandler.cancelLoadImage(token)
                    }
                }
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let manga = searchResultMangaArr[indexPath.row]
        
        let mangaInfo = MangaInfo(title: manga.title,
                                  author: manga.author,
                                  updateCycle: manga.updateCycle,
                                  thumbnailImage: manga.thumbnailImage,
                                  thumbnailImageURL: manga.thumbnailImageURL,
                                  mangaSN: manga.mangaSN)
        
        presentEpisdoeVC(mangaInfo)
    }
}

extension SearchViewController: UIScrollViewDelegate {
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        self.view.endEditing(true)
    }
}
