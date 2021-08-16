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
    struct Manga {
        var title: String
        var desc1: String
        var desc2: String
        var previewImageUrl: String?
        var serialNumber: String
    }
    
    var disposeBag = DisposeBag()
    let baseUrl = "https://marumaru.cloud"
    let searchUrl = "/bbs/search.php?url=%2Fbbs%2Fsearch.php&stx="
    let networkHandler = NetworkHandler()
    var resultMangaArr: [Manga] = []
    var loadingSearchAnimView = AnimationView()
    var isSearching = false
    
    @IBOutlet weak var appbarView: UIView!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var resultMangaTableView: UITableView!
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
        loadingSearchAnimView.centerXAnchor.constraint(equalTo: self.resultMangaTableView.centerXAnchor).isActive = true
        loadingSearchAnimView.centerYAnchor.constraint(equalTo: self.resultMangaTableView.centerYAnchor, constant: -50).isActive = true
        loadingSearchAnimView.isHidden = true
        
        // result manga Tableview
        resultMangaTableView.contentInset = UIEdgeInsets(top: 60,
                                                         left: 0,
                                                         bottom: 40,
                                                         right: 0)
    }
    
    func initInstance() {
        // result manga TableView
        resultMangaTableView.delegate = self
        resultMangaTableView.dataSource = self
    }
    
    func initEventListener() {}
    
    // MARK: - Methods
    func search(title: String) {
        
        resultMangaArr.removeAll()
        resultMangaTableView.reloadData()
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
                            
                            // Append to array
                            self.resultMangaArr.append(Manga(title: title, desc1: descs[0], desc2: descs[1], previewImageUrl: imgUrl, serialNumber: SN))
                            
                            print(title)
                        } catch {
                            print(error.localizedDescription)
                        }
                    }
                    
                    DispatchQueue.main.async {
                        self.resultMangaTableView.reloadData()
                        self.stopLoadingSearchResultAnimation()
                        self.isSearching = false
                        
                        if self.resultMangaArr.count == 0 {
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
        searchTextField.becomeFirstResponder()
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
    
    private func presentEpisdoeVC() {
        
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
        return resultMangaArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ResultMangaCell") as! ResultMangaCell
        
        if indexPath.row > resultMangaArr.count - 1 {
            return UITableViewCell()
        }
        
        cell.mangaTitleLabel.text = resultMangaArr[indexPath.row].title
        cell.desc1Label.text = resultMangaArr[indexPath.row].desc1
        cell.desc2Label.text = resultMangaArr[indexPath.row].desc2
        cell.previewImagePlaceholderLabel.text = resultMangaArr[indexPath.row].title
        cell.previewImagePlaceholderLabel.isHidden = false
        cell.previewImage.image = UIImage()
        
        if resultMangaArr[indexPath.row].desc2.contains("미분류") {
            cell.desc2Label.textColor = ColorSet.subTextColor
        } else {
            cell.desc2Label.textColor = ColorSet.subTextColor
        }
        
        if let previewImageUrl = resultMangaArr[indexPath.row].previewImageUrl {
            if let url = URL(string: previewImageUrl) {
                let token = networkHandler.getImage(url) { result in
                    DispatchQueue.global(qos: .background).async {
                        do {
                            let result = try result.get()
                            DispatchQueue.main.async {
                                cell.previewImage.image = result.imageCache.image
                                cell.previewImagePlaceholderLabel.isHidden = true
                                
                                if result.animate {
                                    cell.previewImage.startFadeInAnim(duration: 0.5)
                                }
                                
                                // Set preview image shadow with average color of preview image
                                cell.previewImageBaseView.layer.shadowColor = result.imageCache.averageColor.cgColor
                                cell.previewImageBaseView.layer.shadowOffset = .zero
                                cell.previewImageBaseView.layer.shadowRadius = 7
                                cell.previewImageBaseView.layer.shadowOpacity = 30
                                cell.previewImageBaseView.layer.masksToBounds = false
                                cell.previewImageBaseView.layer.borderWidth = 0
                                cell.previewImageBaseView.layer.shouldRasterize = true
                            }
                        } catch {
                            DispatchQueue.main.async {
                                cell.previewImagePlaceholderLabel.isHidden = false
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
        let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let destStoryboard = mainStoryboard.instantiateViewController(identifier: "MangaEpisodeStoryboard") as! MangaEpisodeViewController
        
        // Pass datas
        destStoryboard.modalPresentationStyle = .fullScreen
        let currentManga = resultMangaArr[indexPath.row]
        destStoryboard.mangaSN = currentManga.serialNumber
        destStoryboard.infoTitle = currentManga.title
        destStoryboard.infoDesc1 = currentManga.desc1
        destStoryboard.infoDesc2 = currentManga.desc2
        destStoryboard.infoPreviewImageUrl = currentManga.previewImageUrl ?? ""
        
        present(destStoryboard, animated: true, completion: nil)
    }
}

extension SearchViewController: UIScrollViewDelegate {
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        self.view.endEditing(true)
    }
}
