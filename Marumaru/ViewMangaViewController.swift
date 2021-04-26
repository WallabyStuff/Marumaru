//
//  ViewMangaViewController.swift
//  Marumaru
//
//  Created by 이승기 on 2021/04/08.
//

import UIKit
import Alamofire
import SwiftSoup
import Lottie
import CoreData
import Foundation


class ViewMangaViewController: UIViewController {

    struct Scene {
        var sceneUrl: String
    }
    
    let networkHandler = NetworkHandler()
    let coredataHandler = CoreDataHandler()
    var sceneArr = Array<Scene>()
    var cellHeightDictionary: NSMutableDictionary = [:]
    
    let baseUrl = "https://marumaru.cloud/"
    var mangaUrl: String = ""
    
    @IBOutlet weak var sceneLoadingView: UIView!
    @IBOutlet weak var topBarView: UIView!
    @IBOutlet weak var bottomIndicatorView: UIView!
    @IBOutlet weak var mangaTitleLabel: UILabel!
    @IBOutlet weak var mangaSceneTableView: UITableView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var scrollContentView: UIView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        initDesign()
        initInstance()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        setLottieAnims()
        getMangaScenes()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle{
        return .lightContent
    }
    
    
    func initDesign(){
        
    }
    
    func initInstance(){
        mangaSceneTableView.delegate = self
        mangaSceneTableView.dataSource = self
        
        scrollView.delegate = self
        scrollView.maximumZoomScale = 3.0
        scrollView.minimumZoomScale = 1.0
        
        scrollView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:))))
    }
    
    func setLottieAnims(){
        // Set scene loading animation
        let sceneLoadingAnim = AnimationView(name: "loading_square")
        sceneLoadingAnim.frame = CGRect(x: 0, y: 0, width: 300, height: 300)
        sceneLoadingAnim.center = sceneLoadingView.center
        sceneLoadingAnim.loopMode = .loop
        sceneLoadingAnim.play()
        
        sceneLoadingView.addSubview(sceneLoadingAnim)
    }
    
    func getMangaScenes(){
        self.sceneLoadingView.isHidden = false
        
        DispatchQueue.global(qos: .background).async {
            if !self.mangaUrl.isEmpty{
                do{
                    guard let url = URL(string: self.mangaUrl) else {return}
                    let htmlContent = try String(contentsOf: url, encoding: .utf8)
                    let doc = try SwiftSoup.parse(htmlContent)
                    let elements = try doc.getElementsByClass("img-tag")
                    
                    // Set manga title
                    let titleDoc = try doc.getElementsByClass("view-wrap")
                    var mangaTitle = try titleDoc.select("h1").text().trimmingCharacters(in: .whitespacesAndNewlines)
                    if let index = mangaTitle.index(of: "인기 :"){
                        mangaTitle = String(mangaTitle[..<index])
                    }
                    
                    
                    
                    
                    
                    DispatchQueue.main.async {
                        self.mangaTitleLabel.text = mangaTitle
                    }
                    
                    // Append manga scenes
                    for (_, element) in elements.enumerated(){
                        var imgUrl = try element.select("img").attr("src")
                        if !imgUrl.contains(self.baseUrl){
                            imgUrl = "\(self.baseUrl)\(imgUrl)"
                        }
                        
                        self.sceneArr.append(Scene(sceneUrl: imgUrl))
                    }
                    
                    // if successfuly appending scenes
                    DispatchQueue.main.sync {
                        self.sceneLoadingView.isHidden = true
                        self.mangaSceneTableView.reloadData()
                    }
                    
                    // save to watch history
                    
                    if self.sceneArr.count > 0{
                        if let url = URL(string: self.sceneArr[0].sceneUrl){
                            self.networkHandler.getImage(url){ result in
                                do{
                                    // success to get image
                                    print("Log : Successfully load image")
                                    let image = try result.get()
                                    self.coredataHandler.saveToWatchHistory(mangaTitle: mangaTitle, mangaLink: self.mangaUrl, mangaPreviewImageUrl: self.sceneArr[0].sceneUrl, mangaPreviewImage: image)
                                }catch{
                                    // fail to get image
                                    print("Log : fail to get image")
                                    self.coredataHandler.saveToWatchHistory(mangaTitle: mangaTitle, mangaLink: self.mangaUrl, mangaPreviewImageUrl: self.sceneArr[0].sceneUrl, mangaPreviewImage: nil)
                                    print(error)
                                }
                            }
                        }else{
                            // fail to convert string to url
                            print("Log : fail to convert image to url")
                            self.coredataHandler.saveToWatchHistory(mangaTitle: mangaTitle, mangaLink: self.mangaUrl, mangaPreviewImageUrl: self.sceneArr[0].sceneUrl, mangaPreviewImage: nil)
                        }
                    }else{
                        // first scene image is not exists
                        print("Log : scene iamge is not exists")
                        self.coredataHandler.saveToWatchHistory(mangaTitle: mangaTitle, mangaLink: self.mangaUrl, mangaPreviewImageUrl: nil, mangaPreviewImage: nil)
                    }
                    
                    
                            
                }catch{
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    func loadNextEpisode(){
        
    }
    
    func loadPreviousEpisode(){
        
    }
    
    func fadeTopbarView(bool: Bool){
        if bool {
            UIView.animate(withDuration: 0.3) {
                self.topBarView.alpha = 0
            } completion: { _ in
                self.topBarView.isHidden = true
            }
        }else{
            self.topBarView.isHidden = false
            
            UIView.animate(withDuration: 0.3) {
                self.topBarView.alpha = 1
            }
        }
    }
    
    func fadeIndicatorView(bool: Bool){
        if bool {
            UIView.animate(withDuration: 0.3) {
                self.bottomIndicatorView.alpha = 0
            } completion: { _ in
                self.bottomIndicatorView.isHidden = true
            }
        }else{
            self.bottomIndicatorView.isHidden = false
            
            UIView.animate(withDuration: 0.3) {
                self.bottomIndicatorView.alpha = 1
            }
        }
    }
    
    
    @objc func handleTap(sender: UITapGestureRecognizer){
        if sender.state == .ended{
            if topBarView.isHidden {
                fadeTopbarView(bool: false)
            }else{
                fadeTopbarView(bool: true)
            }
            
            if bottomIndicatorView.isHidden{
                fadeIndicatorView(bool: false)
            }else{
                fadeIndicatorView(bool: true)
            }
        }
        
    }

    @IBAction func backButtonAction(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func previousEpisodeButtonAction(_ sender: Any) {
        
    }
    
    @IBAction func nextEpisodeButtonAction(_ sender: Any) {
        
    }
    
    @IBAction func viewEpisodeListButtonAction(_ sender: Any) {
        
    }
}






extension ViewMangaViewController: UITableViewDelegate ,UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sceneArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let sceneCell = tableView.dequeueReusableCell(withIdentifier: "MangaSceneCell") as! MangaSceneCell
        
        sceneCell.selectionStyle = .none
        
        // save cell height
        cellHeightDictionary.setObject(sceneCell.frame.height, forKey: indexPath as NSCopying)
        
        
        if indexPath.row > sceneArr.count - 1{
            return UITableViewCell()
        }
        
        // set background tile
        let tileImage = UIImage(named: "Tile")!
        let patternBackground = UIColor(patternImage: tileImage)
        sceneCell.backgroundColor = patternBackground
        sceneCell.sceneImageView.image = UIImage()

        // set scene
        if let url = URL(string: sceneArr[indexPath.row].sceneUrl){
            let token = networkHandler.getImage(url){result in
                DispatchQueue.global(qos: .background).async {
                    do{
                        let image = try result.get()
                        DispatchQueue.main.async {
                            sceneCell.sceneImageView.image = image
                            sceneCell.backgroundColor = UIColor(named: "BackgroundColor")!
                        }
                    }catch{
                        DispatchQueue.main.async {
                            sceneCell.backgroundColor = patternBackground
                        }
                        print(error.localizedDescription)
                    }
                }
            }
            
            sceneCell.onReuse = {
                if let token = token{
                    self.networkHandler.cancelLoadImage(token)
                }
            }
        }
        
        
        return sceneCell
    }
    
    // Scroll to current position when orientation changed
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if let height = cellHeightDictionary.object(forKey: indexPath) as? Double{
            return CGFloat(height)
        }
        
        return UITableView.automaticDimension
    }
}


extension ViewMangaViewController: UIScrollViewDelegate{
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        
        let actualPosition = scrollView.panGestureRecognizer.translation(in: scrollView.superview)
        
        if (actualPosition.y > 0){
            // scrolling up
            fadeTopbarView(bool: false)
            fadeIndicatorView(bool: false)
        }else{
            // scrolling down
            fadeTopbarView(bool: true)
            fadeIndicatorView(bool: true)
        }
        
        let height = scrollView.frame.height
        let contentYoffset = scrollView.contentOffset.y
        let distanceFromBottom = scrollView.contentSize.height - contentYoffset
        
        // scroll over down
        if distanceFromBottom <= height{
            UIView.animate(withDuration: 0.3){
                self.topBarView.alpha = 1
                self.bottomIndicatorView.alpha = 1
            }
        }
    }
    
    // Set scrollview zoomable
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.scrollContentView
    }
}


//https://stackoverflow.com/questions/32305891/index-of-a-substring-in-a-string-with-swift
extension StringProtocol {
    func index<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> Index? {
        range(of: string, options: options)?.lowerBound
    }
    func endIndex<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> Index? {
        range(of: string, options: options)?.upperBound
    }
    func indices<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> [Index] {
        ranges(of: string, options: options).map(\.lowerBound)
    }
    func ranges<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> [Range<Index>] {
        var result: [Range<Index>] = []
        var startIndex = self.startIndex
        while startIndex < endIndex,
            let range = self[startIndex...]
                .range(of: string, options: options) {
                result.append(range)
                startIndex = range.lowerBound < range.upperBound ? range.upperBound :
                    index(range.lowerBound, offsetBy: 1, limitedBy: endIndex) ?? endIndex
        }
        return result
    }
}
