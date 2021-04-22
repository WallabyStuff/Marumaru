//
//  SearchViewController.swift
//  Marumaru
//
//  Created by 이승기 on 2021/04/12.
//

import UIKit
import SwiftSoup
import Lottie

class SearchViewController: UIViewController {

    struct Manga {
        var title: String
        var desc1: String
        var desc2: String
        var previewImageUrl: String?
        var previewImage: UIImage?
        var serialNumber: String
    }
    
    let baseUrl = "https://marumaru.cloud"
    let searchUrl = "/bbs/search.php?url=%2Fbbs%2Fsearch.php&stx="
    
    let networkHandler = NetworkHandler()
    var resultMangaArr = Array<Manga>()
    
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var resultMangaTableView: UITableView!
    @IBOutlet weak var loadingResultView: UIView!
    @IBOutlet weak var noResultsLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        initDesign()
        initInstance()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        setLottieAnims()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle{
        return .darkContent
    }

    func initDesign(){
        searchTextField.layer.cornerRadius = 15
        searchTextField.layer.borderWidth = 2
        searchTextField.layer.borderColor = UIColor(named: "PointColor")?.cgColor
        searchTextField.attributedPlaceholder = NSAttributedString(string: "find by manga title", attributes: [NSAttributedString.Key.foregroundColor: UIColor(named: "TextFieldPlaceHolderColor") ?? .gray])
        
        // Add padding to search textfield
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: self.searchTextField.frame.height))
        searchTextField.leftView = paddingView
        searchTextField.leftViewMode = .always
        
        // Textfield keyboard return type to search
        searchTextField.returnKeyType = .search
        searchTextField.delegate = self
    }
    
    func initInstance(){
        searchTextField.becomeFirstResponder()
        
        resultMangaTableView.delegate = self
        resultMangaTableView.dataSource = self
    }
    
    func setLottieAnims(){
        // set search loading anim -lottie-
        let loadingSqaureAnimView = AnimationView(name: "loading_square")
        loadingSqaureAnimView.frame = CGRect(x: 0, y: 0, width: 300, height: 300)
        loadingSqaureAnimView.center = loadingResultView.center
        loadingSqaureAnimView.play()
        loadingSqaureAnimView.loopMode = .loop
        loadingResultView.addSubview(loadingSqaureAnimView)
    }
    
    
    func search(title: String){
        
        DispatchQueue.global(qos: .background).async {
            let modifiedTitle = title.replacingOccurrences(of: " ", with: "+")
            let fullPath = "\(self.baseUrl)\(self.searchUrl)\(modifiedTitle)"
            
            let transformedUrl = self.transformURLString(fullPath)
            
            if let url = transformedUrl?.string{
                guard let searchUrl = URL(string: url) else {return}
                
                do{
                    let htmlContent = try String(contentsOf: searchUrl, encoding: .utf8)
                    let doc = try SwiftSoup.parse(htmlContent)
                    let resultElements = try doc.getElementsByClass("media")
                    
                    resultElements.forEach { (Element) in
                        do{
                            // get Title
                            let title = try Element.getElementsByClass("media-heading").text()
                            
                            // get Descriptions
                            var descs = Array<String>()
                            let descElement = try Element.getElementsByClass("text-muted")
                            descElement.forEach { (Element) in
                                do{
                                    descs.append(try Element.text())
                                }catch{
                                    descs.append("")
                                    print(error.localizedDescription)
                                }
                            }
                            
                            // get Image
                            var imgUrl = String(try Element.select("img").attr("src"))
                            if !imgUrl.contains(self.baseUrl) && !imgUrl.isEmpty{
                                imgUrl = "\(self.baseUrl)\(imgUrl)"
                            }
                            
                            // get Link
                            var SN = ""
                            let link = String(try Element.select("a").attr("href"))
                            if let range = link.range(of: "sca="){
                                SN = String(link[range.upperBound...])
                            }
                            
                            
                            // Append to array
                            self.resultMangaArr.append(Manga(title: title, desc1: descs[0] , desc2: descs[1], previewImageUrl: imgUrl, previewImage: nil, serialNumber: SN))
                            
                            
                            print(title)
                        }catch{
                            print(error.localizedDescription)
                        }
                    }
                    
                    DispatchQueue.main.async {
                        self.resultMangaTableView.reloadData()
                        
                        if self.resultMangaArr.count == 0{
                            self.noResultsLabel.isHidden = false
                            self.loadingResultView.isHidden = true
                        }else{
                            self.loadingResultView.isHidden = true
                        }
                    }
                    
                }catch{
                    print(error.localizedDescription)
                }
            }else{
                // fail to transform the url
                return
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
    
    @IBAction func backButtonAction(_ sender: Any) {
        self.dismiss(animated: true)
    }
}


extension SearchViewController: UITextFieldDelegate{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        // Seach action on keyboard
        if let title = textField.text?.trimmingCharacters(in: .whitespaces){
            resultMangaArr.removeAll()
            resultMangaTableView.reloadData()
            loadingResultView.isHidden = false
            noResultsLabel.isHidden = true
            
            search(title: title)
        }
        
        return true
    }
    
}

extension SearchViewController: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return resultMangaArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ResultMangaCell") as! ResultMangaCell
        
        cell.titleLabel.text = resultMangaArr[indexPath.row].title
        cell.desc1Label.text = resultMangaArr[indexPath.row].desc1
        cell.desc2Label.text = resultMangaArr[indexPath.row].desc2
        cell.previewImagePlaceholderLabel.text = resultMangaArr[indexPath.row].title
        cell.previewImagePlaceholderLabel.isHidden = false
        cell.previewImage.image = UIImage()
        
        
        if let previewImageUrl = resultMangaArr[indexPath.row].previewImageUrl{
            if let url = URL(string: previewImageUrl){
                let token = networkHandler.getImage(url){ result in
                    DispatchQueue.global(qos: .background).async {
                        do{
                            let image = try result.get()
                            DispatchQueue.main.async {
                                cell.previewImage.image = image
                                cell.previewImagePlaceholderLabel.isHidden = true
                                
                                cell.previewImage.alpha = 0
                                UIView.animate(withDuration: 0.5) {
                                    cell.previewImage.alpha = 1
                                }
                            }
                        }catch{
                            DispatchQueue.main.async {
                                cell.previewImagePlaceholderLabel.isHidden = false
                            }
                            print(error.localizedDescription)
                        }
                    }
                }
                
                cell.onReuse = {
                    if let token = token{
                        self.networkHandler.cancelLoadImage(token)
                    }
                }
            }
        }
//
//
//        // Check preview image did loaded
//        if resultMangaArr[indexPath.row].previewImage != nil{
//            // preview image is already loaded , preview image is exists
//            cell.previewImage.image = resultMangaArr[indexPath.row].previewImage
//            cell.previewImage.layer.masksToBounds = true
//            cell.previewImagePlaceholderLabel.isHidden = true
//
//        }else{
//            // Preview image has not been loaded
//            DispatchQueue.global(qos: .background).async {
//                if self.resultMangaArr[indexPath.row].previewImageUrl != ""{
//                    do{
//                        let url = URL(string: self.resultMangaArr[indexPath.row].previewImageUrl!)
//                        let data = try Data(contentsOf: url!)
//                        self.resultMangaArr[indexPath.row].previewImage = UIImage(data: data)
//
//                        DispatchQueue.main.async {
//                            cell.previewImage.alpha = 0
//                            cell.previewImage.image = self.resultMangaArr[indexPath.row].previewImage
//                            cell.previewImagePlaceholderLabel.isHidden = true
//
//                            UIView.animate(withDuration: 0.5) {
//                                cell.previewImage.alpha = 1
//                            }
//                        }
//                    }catch{
//                        DispatchQueue.main.async {
//                            print(error.localizedDescription)
//                            cell.previewImagePlaceholderLabel.text = self.resultMangaArr[indexPath.row].title
//                            cell.previewImagePlaceholderLabel.isHidden = false
//                        }
//                    }
//                }else{
//                    DispatchQueue.main.async {
//                        cell.previewImagePlaceholderLabel.text = self.resultMangaArr[indexPath.row].title
//                        cell.previewImagePlaceholderLabel.isHidden = false
//                    }
//                }
//            }
//        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let destStoryboard = mainStoryboard.instantiateViewController(identifier: "MangaEpisodeStoryboard") as! MangaEpisodeViewController
        
        // Pass datas
        let currentManga = resultMangaArr[indexPath.row]
        destStoryboard.mangaSN = currentManga.serialNumber
        destStoryboard.infoTitle = currentManga.title
        destStoryboard.infoDesc1 = currentManga.desc1
        destStoryboard.infoDesc2 = currentManga.desc2
        destStoryboard.infoPreviewImageUrl = currentManga.previewImageUrl ?? ""
        
        present(destStoryboard, animated: true, completion: nil)
    }
}


extension SearchViewController: UIScrollViewDelegate{
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        self.view.endEditing(true)
    }
}
