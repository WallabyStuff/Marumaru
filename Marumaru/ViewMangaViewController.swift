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
import Toast


class ViewMangaViewController: UIViewController {

    // MARK: - Declarations
    struct Scene {
        var sceneUrl: String
    }
    
    var baseUrl = "https://marumaru.cloud/"
    var baseDocument: Document?
    
    var mangaTitle: String = ""
    var mangaUrl: String = ""
    
    var episodeArr = Array<Episode>()
    var sceneArr = Array<Scene>()
    
    var currentEpisodeIndex: Int?
    @IBOutlet weak var viewEpisodeListButton: UIButton!
    @IBOutlet weak var nextEpisodeButton: UIButton!
    @IBOutlet weak var previousEpisodeButton: UIButton!
    
    
    let networkHandler = NetworkHandler()
    let coredataHandler = CoreDataHandler()
    
    var cellHeightDictionary: NSMutableDictionary = [:]
    
    var sceneLoadingAnim = AnimationView()
    var detailInfoView = UIView()
    var detailInfoTitleLabel = UILabel()
    var detailInfoEpisodeSizeLabel = UILabel()
    
    @IBOutlet weak var sceneLoadingView: UIView!
    @IBOutlet weak var topBarView: UIView!
    @IBOutlet weak var bottomIndicatorView: UIView!
    @IBOutlet weak var mangaTitleLabel: UILabel!
    @IBOutlet weak var mangaSceneTableView: UITableView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var scrollContentView: UIView!
    
    
    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()

        checkIntegrity()
        
        initView()
        initInstance()
        initEventListener()
        
        indicatorState(false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        setLottieAnims()
        loadMangaScenes(mangaUrl)
    }
    
    // MARK: - Overrides
    override var preferredStatusBarStyle: UIStatusBarStyle{
        return .lightContent
    }
    
    
    
    // MARK: - Initializations
    func initView(){
        NSLayoutConstraint.activate([
            topBarView.rightAnchor.constraint(equalTo: view.rightAnchor),
            topBarView.leftAnchor.constraint(equalTo: view.leftAnchor),
            
            bottomIndicatorView.rightAnchor.constraint(equalTo: view.rightAnchor),
            bottomIndicatorView.leftAnchor.constraint(equalTo: view.leftAnchor)
        ])
        
        
        detailInfoView = UIView(frame: UIScreen.main.bounds)
        view.addSubview(detailInfoView)
        detailInfoView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            detailInfoView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            detailInfoView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            detailInfoView.heightAnchor.constraint(equalTo: view.heightAnchor),
            detailInfoView.widthAnchor.constraint(equalTo: view.widthAnchor)
        ])
        detailInfoView.alpha = 0
        
        
        let blurEffect = UIBlurEffect(style: .light)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = detailInfoView.frame
        detailInfoView.addSubview(blurView)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: detailInfoView.topAnchor),
            blurView.trailingAnchor.constraint(equalTo: detailInfoView.trailingAnchor),
            blurView.leadingAnchor.constraint(equalTo: detailInfoView.leadingAnchor),
            blurView.bottomAnchor.constraint(equalTo: detailInfoView.bottomAnchor)
        ])
        
        
        
        detailInfoTitleLabel = UILabel(frame: CGRect(x: 0, y: 0, width: blurView.contentView.frame.width, height: 300))
        detailInfoTitleLabel.textColor = UIColor(named: "BasicTextColor")
        detailInfoTitleLabel.font = UIFont.boldSystemFont(ofSize: 24)
        detailInfoTitleLabel.numberOfLines = 7
        detailInfoTitleLabel.text = mangaTitle
        blurView.contentView.addSubview(detailInfoTitleLabel)
        detailInfoTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            detailInfoTitleLabel.topAnchor.constraint(equalTo: blurView.contentView.topAnchor, constant: 100),
            detailInfoTitleLabel.leftAnchor.constraint(equalTo: blurView.contentView.leftAnchor, constant: 30),
            detailInfoTitleLabel.rightAnchor.constraint(equalTo: blurView.contentView.rightAnchor, constant: -30),
        ])
        
        
        
        detailInfoEpisodeSizeLabel = UILabel(frame: CGRect(x: 0, y: 0, width: blurView.contentView.frame.width, height: 30))
        detailInfoEpisodeSizeLabel.textColor = UIColor(named: "BasicTextColor")
        detailInfoEpisodeSizeLabel.text = "총 --화"
        blurView.contentView.addSubview(detailInfoEpisodeSizeLabel)
        detailInfoEpisodeSizeLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            detailInfoEpisodeSizeLabel.topAnchor.constraint(equalTo: detailInfoTitleLabel.bottomAnchor, constant: 15),
            detailInfoEpisodeSizeLabel.leftAnchor.constraint(equalTo: blurView.contentView.leftAnchor, constant: 35),
            detailInfoEpisodeSizeLabel.rightAnchor.constraint(equalTo: blurView.contentView.rightAnchor, constant: 35)
        ])
        
        
    }
    
    func initInstance(){
        mangaSceneTableView.delegate = self
        mangaSceneTableView.dataSource = self
        
        scrollView.delegate = self
        scrollView.maximumZoomScale = 3.0
        scrollView.minimumZoomScale = 1.0
        
    }
    
    func initEventListener(){
        scrollView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:))))
        
        topBarView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(topBarTap(sender:))))
        
        detailInfoView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(detailInfoViewTap(sender:))))
    }
    
    
    // MARK: - Methods
    func checkIntegrity(){
        if mangaUrl.isEmpty{
            dismiss(animated: true, completion: nil)
        }
        
        if mangaTitle.isEmpty{
            dismiss(animated: true, completion: nil)
        }else{
            mangaTitleLabel.text = mangaTitle
        }
    }
    
    func setLottieAnims(){
        // Set scene loading animation
        sceneLoadingAnim = AnimationView(name: "loading_square")
        sceneLoadingAnim.frame = CGRect(x: 0, y: 0, width: 300, height: 300)
        sceneLoadingAnim.center = sceneLoadingView.center
        sceneLoadingAnim.loopMode = .loop
        sceneLoadingAnim.play()
        sceneLoadingView.addSubview(sceneLoadingAnim)
    }
    
    func loadMangaScenes(_ mangaUrl: String){
        self.sceneLoadingView.isHidden = false
        sceneArr.removeAll()
        mangaSceneTableView.reloadData()
        indicatorState(false)
        
        DispatchQueue.global(qos: .background).async {
            if !self.mangaUrl.isEmpty{
                do{
                    guard let url = URL(string: mangaUrl) else {return}
                    let htmlContent = try String(contentsOf: url, encoding: .utf8)
                    self.baseDocument = try SwiftSoup.parse(htmlContent)
                    
                    if let doc = self.baseDocument{
                        let elements = try doc.getElementsByClass("img-tag")
                        
                        
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
                            self.saveToHistory()
                            self.getEpisodes()
                        }
                        
                    }else{
                        // document is nil
                        self.view.makeToast("불러오기에 실패하였습니다. 다시 시도해주시기 바랍니다.")
                    }
                    
                            
                }catch{
                    print("Log error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func saveToHistory(){
        // save to watch history
        if self.sceneArr.count > 0{
            
            // check is exists already
            if let url = URL(string: self.sceneArr[0].sceneUrl){
                self.networkHandler.getImage(url){ result in
                    do{
                        // success to get image
                        print("Log : Successfully load image")
                        let image = try result.get()
                        
                        if self.sceneArr.count > 0{ // sceneArr.count > 0 로 감싸져 있음에도 index out of range 에러가 나서 다시 한 번 확인
                            self.coredataHandler.saveToWatchHistory(mangaTitle: self.mangaTitle, mangaLink: self.mangaUrl, mangaPreviewImageUrl: self.sceneArr[0].sceneUrl, mangaPreviewImage: image)
                        }else{
                            self.coredataHandler.saveToWatchHistory(mangaTitle: self.mangaTitle, mangaLink: self.mangaUrl, mangaPreviewImageUrl: nil, mangaPreviewImage: nil)
                        }
                    }catch{
                        // fail to get image
                        print("Log : fail to get image")
                        self.coredataHandler.saveToWatchHistory(mangaTitle: self.mangaTitle, mangaLink: self.mangaUrl, mangaPreviewImageUrl: self.sceneArr[0].sceneUrl, mangaPreviewImage: nil)
                        print(error)
                    }
                }
            }else{
                // fail to convert string to url
                print("Log : fail to convert image to url")
                self.coredataHandler.saveToWatchHistory(mangaTitle: self.mangaTitle, mangaLink: mangaUrl, mangaPreviewImageUrl: self.sceneArr[0].sceneUrl, mangaPreviewImage: nil)
            }
        }else{
            // first scene image is not exists
            print("Log : scene iamge is not exists")
            self.coredataHandler.saveToWatchHistory(mangaTitle: self.mangaTitle, mangaLink: mangaUrl, mangaPreviewImageUrl: nil, mangaPreviewImage: nil)
        }
    }
    
    
    func getEpisodes(){
        episodeArr.removeAll()
        
        DispatchQueue.global(qos: .background).async {
            
            do{
                if let doc = self.baseDocument{
                    let chartDoc = try doc.getElementsByClass("chart").first()
                    if let chart = try chartDoc?.select("option"){
                        
                        // append items
                        for (index, Element) in chart.enumerated(){
                            
                            let episodeTitle = try Element.text().trimmingCharacters(in: .whitespaces)
                            let episodeSN = try Element.attr("value")
                            
                            if chart.count - 1 != index{ // 마지막 인덱스는 항상 비어서 마지막 인덱스 저장 안되도록
                                self.episodeArr.append(Episode(episodeTitle, episodeSN))
                            }
                            
                            
                            // get current episode index
                            if self.mangaUrl.contains(episodeSN){
                                self.mangaTitle = episodeTitle
                                self.currentEpisodeIndex = index
                            }
                        }
                        
                        // finish to load episodes
                        DispatchQueue.main.async {
                            self.indicatorState(true)
                        }
                    }
                }
                
            }catch{
                print(error.localizedDescription)
            }
        }
    }
    
    
    func setIndicator(){
        getEpisodes()
    }
    
    func showEpisodePopoverView(){
        let episodePopoverVC = storyboard?.instantiateViewController(identifier: "EpisodePopoverStoryboard") as! EpisodePopoverViewController
        
        episodePopoverVC.modalPresentationStyle = .popover
        episodePopoverVC.preferredContentSize = CGSize(width: 200, height: 300)
        episodePopoverVC.popoverPresentationController?.permittedArrowDirections = .down
        episodePopoverVC.popoverPresentationController?.sourceRect = viewEpisodeListButton.bounds
        episodePopoverVC.popoverPresentationController?.sourceView = viewEpisodeListButton
        episodePopoverVC.presentationController?.delegate = self
        episodePopoverVC.selectItemDelegate = self
        
        episodePopoverVC.episodeArr = episodeArr
        episodePopoverVC.currentEpisodeIndex = currentEpisodeIndex
        
        if let index = currentEpisodeIndex{
            if let episodeTitle = episodeArr[index].episodeTitle{
                episodePopoverVC.currentEpisodeTitle = episodeTitle
            }
        }else{
            episodePopoverVC.currentEpisodeTitle = mangaTitle
        }
        
        
        present(episodePopoverVC, animated: true, completion: nil)
    }
    
    
    func loadNextEpisode(){
        if !episodeArr.isEmpty{
            if let currentEpisodeIndex = currentEpisodeIndex{
                if 0 <= currentEpisodeIndex - 1{
                    
                    let nextEpisode = episodeArr[currentEpisodeIndex - 1]
                    
                    guard let nextEpisodeTitle = nextEpisode.episodeTitle, let nextEpisodeSN = nextEpisode.episodeSN else{
                        return
                    }
                    
                    let url = replaceSerialNumber(nextEpisodeSN)
                    
                    mangaTitle = nextEpisodeTitle
                    mangaTitleLabel.text = nextEpisodeTitle
                    loadMangaScenes(url)
                    
                    sceneLoadingAnim.play()
                }else{
                    self.view.makeToast("마지막 화 입니다")
                }
            }
        }
    }
    
    func loadPreviousEpisode(){
        if !episodeArr.isEmpty{
            if let currentEpisodeIndex = currentEpisodeIndex{
                if episodeArr.count > currentEpisodeIndex + 1{
                    
                    let prevEpisode = episodeArr[currentEpisodeIndex + 1]
                    
                    guard let prevEpisodeTitle = prevEpisode.episodeTitle, let prevEpisodeSN = prevEpisode.episodeSN else{
                        return
                    }
                    
                    let url = replaceSerialNumber(prevEpisodeSN)
                    
                    mangaTitle = prevEpisodeTitle
                    mangaTitleLabel.text = prevEpisodeTitle
                    loadMangaScenes(url)
                    
                    sceneLoadingAnim.play()
                }else{
                    self.view.makeToast("첫 화 입니다")
                }
            }
        }
    }
    
    func showDetailInfoView(){
        
        detailInfoTitleLabel.text = mangaTitle
        detailInfoEpisodeSizeLabel.text = "총 \(episodeArr.count)화"
        
        detailInfoView.alpha = 0
        UIView.animate(withDuration: 0.2) {
            self.detailInfoView.alpha = 1.0
        }
    }
    
    func hideDetailInfoView(){
        UIView.animate(withDuration: 0.2) {
            self.detailInfoView.alpha = 0
        }
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
    
    func replaceSerialNumber(_ newSerialNumber: String) -> String{
        
        var separatedUrl = mangaUrl.split(separator: "/")
        separatedUrl = separatedUrl.dropLast()
        
        var completeUrl = ""
        
        separatedUrl.forEach { Substring in
            if Substring == "https:"{
                completeUrl = completeUrl.appending(Substring).appending("//")
            }else{
                completeUrl = completeUrl.appending(Substring).appending("/")
            }
        }
        completeUrl = completeUrl.appending(newSerialNumber)
        
        self.mangaUrl = completeUrl
        
        return completeUrl
    }
    
    func indicatorState(_ bool: Bool){
        if bool{
            nextEpisodeButton.isEnabled = true
            previousEpisodeButton.isEnabled = true
            viewEpisodeListButton.isEnabled = true
        }else{
            nextEpisodeButton.isEnabled = false
            previousEpisodeButton.isEnabled = false
            viewEpisodeListButton.isEnabled = false
        }
    }
    
    // MARK: - Actions
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
    
    @objc func topBarTap(sender: UITapGestureRecognizer){
        if sender.state == .ended{
            showDetailInfoView()
        }
    }
    
    @objc func detailInfoViewTap(sender: UIGestureRecognizer){
        if sender.state == .ended{
            hideDetailInfoView()
        }
    }

    @IBAction func backButtonAction(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func previousEpisodeButtonAction(_ sender: Any) {
        loadPreviousEpisode()
    }
    
    @IBAction func nextEpisodeButtonAction(_ sender: Any) {
        loadNextEpisode()
    }
    
    @IBAction func viewEpisodeListButtonAction(_ sender: Any) {
        showEpisodePopoverView()
    }
}





// MARK: - Extensions
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
        sceneCell.sceneDividerView.backgroundColor = patternBackground
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
                            sceneCell.sceneDividerView.backgroundColor = UIColor(named: "BackgroundColor")
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


extension UIViewController: UIPopoverPresentationControllerDelegate {
    public func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
}


extension ViewMangaViewController: SelectItemDelegate{
    func loadSelectedEpisode(_ episode: Episode) {
    
        let url = replaceSerialNumber(episode.episodeSN!)
        
        mangaTitle = episode.episodeTitle!
        mangaTitleLabel.text = episode.episodeTitle
        loadMangaScenes(url)
        
        sceneLoadingAnim.play()
    }
}
