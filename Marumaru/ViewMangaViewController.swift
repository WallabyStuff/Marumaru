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
import Hero
import RxSwift
import RxCocoa

class ViewMangaViewController: UIViewController {

    // MARK: - Declarations
    struct Scene {
        var sceneUrl: String
    }
    
    var disposeBag = DisposeBag()
    let networkHandler = NetworkHandler()
    let coredataHandler = HistoryHandler()
    
    var currentEpisodeIndex: Int?
    var baseUrl = "https://marumaru.cloud/"
    var baseDocument: Document?
    var mangaTitle: String = ""
    var mangaUrl: String = ""
    var episodeArr = [Episode]()
    var sceneArr = [Scene]()
    var cellHeightDictionary: NSMutableDictionary = [:]
    let safeAreaInsets = UIApplication.shared.windows[0].safeAreaInsets
    
    var loadingSceneAnimView = AnimationView()
    var detailInfoView = UIView()
    var detailInfoTitleLabel = UILabel()
    var detailInfoEpisodeSizeLabel = UILabel()
    var detailInfoEpisodeTableView = UITableView()

    @IBOutlet weak var episodeListButton: UIButton!
    @IBOutlet weak var nextEpisodeButton: UIButton!
    @IBOutlet weak var previousEpisodeButton: UIButton!
    @IBOutlet weak var appbarView: UIView!
    @IBOutlet weak var bottomIndicatorView: UIView!
    @IBOutlet weak var mangaTitleLabel: UILabel!
    @IBOutlet weak var mangaSceneTableView: UITableView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var scrollContentView: UIView!
    @IBOutlet weak var backButton: UIButton!
    
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
        loadMangaScenes(mangaUrl)
    }
    
    // MARK: - Overrides
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .darkContent
    }
    
    // MARK: - Initializations
    func initView() {
        // hero enable
        self.hero.isEnabled = true
        
        // loading scene AnimView
        loadingSceneAnimView = AnimationView(name: "loading_square")
        loadingSceneAnimView.frame = CGRect(x: 0, y: 0, width: 300, height: 300)
        loadingSceneAnimView.loopMode = .loop
        view.addSubview(loadingSceneAnimView)
        loadingSceneAnimView.translatesAutoresizingMaskIntoConstraints = false
        loadingSceneAnimView.centerXAnchor.constraint(equalTo: mangaSceneTableView.centerXAnchor).isActive = true
        loadingSceneAnimView.centerYAnchor.constraint(equalTo: mangaSceneTableView.centerYAnchor).isActive = true
        loadingSceneAnimView.isHidden = true
        
        // appbar View
        appbarView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        appbarView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        appbarView.layer.cornerRadius = 40
        appbarView.layer.maskedCorners = CACornerMask([.layerMinXMaxYCorner])
        appbarView.hero.modifiers = [.translate(y: -appbarView.frame.height)]
        
        // bottom Indicator View
        bottomIndicatorView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        bottomIndicatorView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        bottomIndicatorView.hero.modifiers = [.translate(y: bottomIndicatorView.frame.height)]
        
        // detail Info View
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
        
        // back Button
        backButton.layer.cornerRadius = 13
        backButton.imageEdgeInsets(with: 10)
        
        // next episode Button
        nextEpisodeButton.layer.cornerRadius = 10
        nextEpisodeButton.imageEdgeInsets(with: 6)
        
        // previous episode Button
        previousEpisodeButton.layer.cornerRadius = 10
        previousEpisodeButton.imageEdgeInsets(with: 6)
        
        // episodes Button
        episodeListButton.layer.cornerRadius = 10
        episodeListButton.imageEdgeInsets(with: 8)
        
        // detail info blur background View
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
        
        // detail info title Label
        detailInfoTitleLabel = UILabel(frame: CGRect(x: 0, y: 0, width: blurView.contentView.frame.width, height: 300))
        detailInfoTitleLabel.textColor = ColorSet.textColor
        detailInfoTitleLabel.font = UIFont.boldSystemFont(ofSize: 24)
        detailInfoTitleLabel.numberOfLines = 7
        detailInfoTitleLabel.text = mangaTitle
        blurView.contentView.addSubview(detailInfoTitleLabel)
        detailInfoTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            detailInfoTitleLabel.topAnchor.constraint(equalTo: blurView.contentView.topAnchor, constant: 70 + safeAreaInsets.top),
            detailInfoTitleLabel.leftAnchor.constraint(equalTo: blurView.contentView.leftAnchor, constant: 30 + safeAreaInsets.left),
            detailInfoTitleLabel.rightAnchor.constraint(equalTo: blurView.contentView.rightAnchor, constant: -30 - safeAreaInsets.right)
        ])
        
        // detail info episode size Label
        detailInfoEpisodeSizeLabel = UILabel(frame: CGRect(x: 0, y: 0, width: blurView.contentView.frame.width, height: 30))
        detailInfoEpisodeSizeLabel.textColor = ColorSet.textColor
        detailInfoEpisodeSizeLabel.text = "총 --화"
        blurView.contentView.addSubview(detailInfoEpisodeSizeLabel)
        detailInfoEpisodeSizeLabel.translatesAutoresizingMaskIntoConstraints = false
        detailInfoEpisodeSizeLabel.topAnchor.constraint(equalTo: detailInfoTitleLabel.bottomAnchor, constant: 15).isActive = true
        detailInfoEpisodeSizeLabel.leftAnchor.constraint(equalTo: blurView.contentView.leftAnchor, constant: 35).isActive = true
        detailInfoEpisodeSizeLabel.rightAnchor.constraint(equalTo: blurView.contentView.rightAnchor, constant: -35).isActive = true
        
        // detail info episode TableView
        detailInfoEpisodeTableView = UITableView(frame: CGRect(x: 0, y: 0, width: 200, height: 300))
        detailInfoEpisodeTableView.backgroundColor = ColorSet.transparentColor
        blurView.contentView.addSubview(detailInfoEpisodeTableView)
        detailInfoEpisodeTableView.translatesAutoresizingMaskIntoConstraints = false
        detailInfoEpisodeTableView.topAnchor.constraint(equalTo: detailInfoEpisodeSizeLabel.bottomAnchor, constant: 40).isActive = true
        detailInfoEpisodeTableView.bottomAnchor.constraint(equalTo: blurView.contentView.bottomAnchor, constant: -80).isActive = true
        detailInfoEpisodeTableView.trailingAnchor.constraint(equalTo: blurView.contentView.trailingAnchor, constant: -30).isActive = true
        detailInfoEpisodeTableView.leadingAnchor.constraint(equalTo: blurView.contentView.leadingAnchor, constant: 30).isActive = true
    }
    
    func initInstance() {
        mangaSceneTableView.delegate = self
        mangaSceneTableView.dataSource = self
        
        scrollView.delegate = self
        scrollView.maximumZoomScale = 3.0
        scrollView.minimumZoomScale = 1.0
        
        detailInfoEpisodeTableView.register(MangaEpisodePopoverCell.self, forCellReuseIdentifier: "EpisodeCell")
        detailInfoEpisodeTableView.dataSource = self
        detailInfoEpisodeTableView.delegate = self
        
    }
    
    func initEventListener() {
        scrollView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:))))
        
        appbarView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(topBarTap(sender:))))
        
        let detailInfoViewGesture = UITapGestureRecognizer(target: self, action: #selector(detailInfoViewTap(sender:)))
        detailInfoViewGesture.delegate = self
        detailInfoView.addGestureRecognizer(detailInfoViewGesture)
    }
    
    // MARK: - Methods
    func checkIntegrity() {
        if mangaUrl.isEmpty {
            dismiss(animated: true, completion: nil)
        }
        
        if mangaTitle.isEmpty {
            dismiss(animated: true, completion: nil)
        } else {
            mangaTitleLabel.text = mangaTitle
        }
    }
    
    func startLoadingSceneAnim() {
        DispatchQueue.main.async {
            self.loadingSceneAnimView.isHidden = false
            self.loadingSceneAnimView.play()
        }
    }
    
    func stopLoadingSceneAnim() {
        DispatchQueue.main.async {
            self.loadingSceneAnimView.isHidden = true
            self.loadingSceneAnimView.stop()
        }
    }
    
    func loadMangaScenes(_ mangaUrl: String) {
        startLoadingSceneAnim()
        sceneArr.removeAll()
        mangaSceneTableView.reloadData()
        indicatorState(false)
        
        DispatchQueue.global(qos: .background).async {
            if !self.mangaUrl.isEmpty {
                do {
                    guard let url = URL(string: mangaUrl) else {return}
                    let htmlContent = try String(contentsOf: url, encoding: .utf8)
                    self.baseDocument = try SwiftSoup.parse(htmlContent)
                    
                    if let doc = self.baseDocument {
                        let elements = try doc.getElementsByClass("img-tag")
                        
                        // Append manga scenes
                        try elements.forEach { element in
                            var imgUrl = try element.select("img").attr("src")
                            if !imgUrl.contains(self.baseUrl) {
                                imgUrl = "\(self.baseUrl)\(imgUrl)"
                            }
                         
                            self.sceneArr.append(Scene(sceneUrl: imgUrl))
                        }
                        
                        // if successfuly appending scenes
                        DispatchQueue.main.sync {
                            self.stopLoadingSceneAnim()
                            self.mangaSceneTableView.reloadData()
                            self.saveToHistory()
                            self.getEpisodes()
                        }
                        
                    } else {
                        // document is nil
                        self.view.makeToast("불러오기에 실패하였습니다. 다시 시도해주시기 바랍니다.")
                    }
                            
                } catch {
                    print("Log error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func saveToHistory() {
        // save to watch history
        if self.sceneArr.count > 0 {
            
            // check is exists already
            if let url = URL(string: self.sceneArr[0].sceneUrl) {
                self.networkHandler.getImage(url) { result in
                    do {
                        // success to get image
                        print("Log : Successfully load image")
                        let result = try result.get()
                        
                        if self.sceneArr.count > 0 { // sceneArr.count > 0 로 감싸져 있음에도 index out of range 에러가 나서 다시 한 번 확인
                            self.coredataHandler.saveToWatchHistory(mangaTitle: self.mangaTitle, mangaLink: self.mangaUrl, mangaPreviewImageUrl: self.sceneArr[0].sceneUrl, mangaPreviewImage: result.imageCache.image)
                        } else {
                            self.coredataHandler.saveToWatchHistory(mangaTitle: self.mangaTitle, mangaLink: self.mangaUrl, mangaPreviewImageUrl: nil, mangaPreviewImage: nil)
                        }
                    } catch {
                        // fail to get image
                        print("Log : fail to get image")
                        self.coredataHandler.saveToWatchHistory(mangaTitle: self.mangaTitle, mangaLink: self.mangaUrl, mangaPreviewImageUrl: self.sceneArr[0].sceneUrl, mangaPreviewImage: nil)
                        print(error)
                    }
                }
            } else {
                // fail to convert string to url
                print("Log : fail to convert image to url")
                self.coredataHandler.saveToWatchHistory(mangaTitle: self.mangaTitle, mangaLink: mangaUrl, mangaPreviewImageUrl: self.sceneArr[0].sceneUrl, mangaPreviewImage: nil)
            }
        } else {
            // first scene image is not exists
            print("Log : scene iamge is not exists")
            self.coredataHandler.saveToWatchHistory(mangaTitle: self.mangaTitle, mangaLink: mangaUrl, mangaPreviewImageUrl: nil, mangaPreviewImage: nil)
        }
    }
    
    func getEpisodes() {
        episodeArr.removeAll()
        
        DispatchQueue.global(qos: .background).async {
            
            do {
                if let doc = self.baseDocument {
                    let chartDoc = try doc.getElementsByClass("chart").first()
                    if let chart = try chartDoc?.select("option") {
                        
                        // append items
                        for (index, Element) in chart.enumerated() {
                            
                            let episodeTitle = try Element.text().trimmingCharacters(in: .whitespaces)
                            let episodeSN = try Element.attr("value")
                            
                            if chart.count - 1 != index { // 마지막 인덱스는 항상 비어서 마지막 인덱스 저장 안되도록
                                self.episodeArr.append(Episode(episodeTitle, episodeSN))
                            }
                            
                            // get current episode index
                            if self.mangaUrl.contains(episodeSN) {
                                self.mangaTitle = episodeTitle
                                self.currentEpisodeIndex = index
                            }
                        }
                        
                        // finish to load episodes
                        DispatchQueue.main.async {
                            self.indicatorState(true)
                            self.detailInfoEpisodeTableView.reloadData()
                            self.detailInfoEpisodeSizeLabel.text = "총 \(self.episodeArr.count)화"
                            self.scrollToCurrentEpisodeOnInfoView()
                        }
                    }
                }
                
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    func setIndicator() {
        getEpisodes()
    }
    
    func showEpisodePopoverView() {
        let episodePopoverVC = storyboard?.instantiateViewController(identifier: "EpisodePopoverStoryboard") as! EpisodePopoverViewController
        
        episodePopoverVC.modalPresentationStyle = .popover
        episodePopoverVC.preferredContentSize = CGSize(width: 200, height: 300)
        episodePopoverVC.popoverPresentationController?.permittedArrowDirections = .down
        episodePopoverVC.popoverPresentationController?.sourceRect = episodeListButton.bounds
        episodePopoverVC.popoverPresentationController?.sourceView = episodeListButton
        episodePopoverVC.presentationController?.delegate = self
        episodePopoverVC.selectItemDelegate = self
        
        episodePopoverVC.episodeArr = episodeArr
        episodePopoverVC.currentEpisodeIndex = currentEpisodeIndex
        
        if let index = currentEpisodeIndex {
            if let episodeTitle = episodeArr[index].episodeTitle {
                episodePopoverVC.currentEpisodeTitle = episodeTitle
            }
        } else {
            episodePopoverVC.currentEpisodeTitle = mangaTitle
        }
        
        present(episodePopoverVC, animated: true, completion: nil)
    }
    
    func loadNextEpisode() {
        if !episodeArr.isEmpty {
            if let currentEpisodeIndex = currentEpisodeIndex {
                if 0 <= currentEpisodeIndex - 1 {
                    
                    let nextEpisode = episodeArr[currentEpisodeIndex - 1]
                    
                    guard let nextEpisodeTitle = nextEpisode.episodeTitle, let nextEpisodeSN = nextEpisode.episodeSN else {
                        return
                    }
                    
                    let url = replaceSerialNumber(nextEpisodeSN)
                    
                    mangaTitle = nextEpisodeTitle
                    mangaTitleLabel.text = nextEpisodeTitle
                    loadMangaScenes(url)
                    
                    startLoadingSceneAnim()
                } else {
                    self.view.makeToast("마지막 화 입니다")
                }
            }
        }
    }
    
    func loadPreviousEpisode() {
        if !episodeArr.isEmpty {
            if let currentEpisodeIndex = currentEpisodeIndex {
                if episodeArr.count > currentEpisodeIndex + 1 {
                    
                    let prevEpisode = episodeArr[currentEpisodeIndex + 1]
                    
                    guard let prevEpisodeTitle = prevEpisode.episodeTitle, let prevEpisodeSN = prevEpisode.episodeSN else {
                        return
                    }
                    
                    let url = replaceSerialNumber(prevEpisodeSN)
                    
                    mangaTitle = prevEpisodeTitle
                    mangaTitleLabel.text = prevEpisodeTitle
                    loadMangaScenes(url)
                    
                    startLoadingSceneAnim()
                } else {
                    self.view.makeToast("첫 화 입니다")
                }
            }
        }
    }
    
    func showDetailInfoView() {
        
        detailInfoTitleLabel.text = mangaTitle
        detailInfoEpisodeSizeLabel.text = "총 \(episodeArr.count)화"
        
        detailInfoView.alpha = 0
        UIView.animate(withDuration: 0.2) {
            self.detailInfoView.alpha = 1.0
        }
        
        scrollToCurrentEpisodeOnInfoView()
    }
    
    func scrollToCurrentEpisodeOnInfoView() {
        if let index = currentEpisodeIndex {
            let indexPath = IndexPath(row: index, section: 0)
            detailInfoEpisodeTableView.scrollToRow(at: indexPath, at: .middle, animated: true)
        }
    }
    
    func hideDetailInfoView() {
        UIView.animate(withDuration: 0.2) {
            self.detailInfoView.alpha = 0
        }
    }
    
    func fadeTopbarView(bool: Bool) {
        if bool {
            UIView.animate(withDuration: 0.3) {
                self.appbarView.alpha = 0
            } completion: { _ in
                self.appbarView.isHidden = true
            }
        } else {
            self.appbarView.isHidden = false
            
            UIView.animate(withDuration: 0.3) {
                self.appbarView.alpha = 1
            }
        }
    }
    
    func fadeIndicatorView(bool: Bool) {
        if bool {
            UIView.animate(withDuration: 0.3) {
                self.bottomIndicatorView.alpha = 0
            } completion: { _ in
                self.bottomIndicatorView.isHidden = true
            }
        } else {
            self.bottomIndicatorView.isHidden = false
            
            UIView.animate(withDuration: 0.3) {
                self.bottomIndicatorView.alpha = 1
            }
        }
    }
    
    func replaceSerialNumber(_ newSerialNumber: String) -> String {
        
        var separatedUrl = mangaUrl.split(separator: "/")
        separatedUrl = separatedUrl.dropLast()
        
        var completeUrl = ""
        
        separatedUrl.forEach { Substring in
            if Substring == "https:"{
                completeUrl = completeUrl.appending(Substring).appending("//")
            } else {
                completeUrl = completeUrl.appending(Substring).appending("/")
            }
        }
        completeUrl = completeUrl.appending(newSerialNumber)
        
        self.mangaUrl = completeUrl
        
        return completeUrl
    }
    
    func indicatorState(_ bool: Bool) {
        if bool {
            nextEpisodeButton.isEnabled = true
            previousEpisodeButton.isEnabled = true
            episodeListButton.isEnabled = true
        } else {
            nextEpisodeButton.isEnabled = false
            previousEpisodeButton.isEnabled = false
            episodeListButton.isEnabled = false
        }
    }
    
    // MARK: - Actions
    @objc func handleTap(sender: UITapGestureRecognizer) {
        if sender.state == .ended {
            if appbarView.isHidden {
                fadeTopbarView(bool: false)
            } else {
                fadeTopbarView(bool: true)
            }
            
            if bottomIndicatorView.isHidden {
                fadeIndicatorView(bool: false)
            } else {
                fadeIndicatorView(bool: true)
            }
        }
        
    }
    
    @objc func topBarTap(sender: UITapGestureRecognizer) {
        if sender.state == .ended {
            showDetailInfoView()
        }
    }
    
    @objc func detailInfoViewTap(sender: UIGestureRecognizer) {
        if sender.state == .ended {
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
extension ViewMangaViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch tableView {
        case mangaSceneTableView:
            return sceneArr.count
        case detailInfoEpisodeTableView:
            return episodeArr.count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch tableView {
        case mangaSceneTableView:
            guard let sceneCell = tableView.dequeueReusableCell(withIdentifier: "MangaSceneCell") as? MangaSceneCell else {return UITableViewCell()}
            
            sceneCell.selectionStyle = .none
            
            // save cell height
            cellHeightDictionary.setObject(sceneCell.frame.height, forKey: indexPath as NSCopying)
            
            if indexPath.row > sceneArr.count - 1 {
                return UITableViewCell()
            }
            
            // set background tile
            let tileImage = UIImage(named: "Tile")!
            let patternBackground = UIColor(patternImage: tileImage)
            sceneCell.backgroundColor = patternBackground
            sceneCell.sceneDividerView.backgroundColor = patternBackground
            sceneCell.sceneImageView.image = UIImage()

            // set scene
            if let url = URL(string: sceneArr[indexPath.row].sceneUrl) {
                let token = networkHandler.getImage(url) { result in
                    DispatchQueue.global(qos: .background).async {
                        do {
                            let result = try result.get()
                            DispatchQueue.main.async {
                                sceneCell.sceneImageView.image = result.imageCache.image
                                sceneCell.backgroundColor = ColorSet.backgroundColor
                                sceneCell.sceneDividerView.backgroundColor = ColorSet.backgroundColor
                            }
                        } catch {
                            DispatchQueue.main.async {
                                sceneCell.backgroundColor = patternBackground
                            }
                            print(error.localizedDescription)
                        }
                    }
                }
                
                sceneCell.onReuse = {
                    if let token = token {
                        self.networkHandler.cancelLoadImage(token)
                    }
                }
            }
            
            return sceneCell
        case detailInfoEpisodeTableView:
            let episodeCell = tableView.dequeueReusableCell(withIdentifier: "EpisodeCell") as! MangaEpisodePopoverCell
            
            if indexPath.row > episodeArr.count - 1 {
                return UITableViewCell()
            }
            
            // Accent text color to current episode
            if let index = currentEpisodeIndex {
                if let currentEpisodeTitle = episodeArr[index].episodeTitle {
                    if episodeArr[indexPath.row].episodeTitle?.lowercased().trimmingCharacters(in: .whitespaces) == currentEpisodeTitle.lowercased().trimmingCharacters(in: .whitespaces) {
                        episodeCell.textLabel?.textColor = ColorSet.accentColor
                    } else {
                        episodeCell.textLabel?.textColor = ColorSet.textColor
                    }
                }
            }
            
            episodeCell.textLabel?.text = episodeArr[indexPath.row].episodeTitle
            episodeCell.textLabel?.lineBreakMode = .byTruncatingMiddle
            episodeCell.backgroundColor = ColorSet.transparentColor
            episodeCell.separatorInset = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
            
            return episodeCell
        default:
            return UITableViewCell()
        }
        
    }
    
    // Scroll to current position when orientation changed
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if let height = cellHeightDictionary.object(forKey: indexPath) as? Double {
            return CGFloat(height)
        }
        
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == detailInfoEpisodeTableView {
            
            let url = replaceSerialNumber(episodeArr[indexPath.row].episodeSN!)
            
            mangaTitle = episodeArr[indexPath.row].episodeTitle!
            mangaTitleLabel.text = episodeArr[indexPath.row].episodeTitle!
            
            hideDetailInfoView()
            
            loadMangaScenes(url)
        }
    }
}

extension ViewMangaViewController: UIScrollViewDelegate {
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        
        let actualPosition = scrollView.panGestureRecognizer.translation(in: scrollView.superview)
        
        if actualPosition.y > 0 {
            // scrolling up
            fadeTopbarView(bool: false)
            fadeIndicatorView(bool: false)
        } else {
            // scrolling down
            fadeTopbarView(bool: true)
            fadeIndicatorView(bool: true)
        }
        
        let height = scrollView.frame.height
        let contentYoffset = scrollView.contentOffset.y
        let distanceFromBottom = scrollView.contentSize.height - contentYoffset
        
        // scroll over down
        if distanceFromBottom <= height {
            UIView.animate(withDuration: 0.3) {
                self.appbarView.alpha = 1
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

extension ViewMangaViewController: SelectItemDelegate {
    func loadSelectedEpisode(_ episode: Episode) {
    
        let url = replaceSerialNumber(episode.episodeSN!)
        
        mangaTitle = episode.episodeTitle!
        mangaTitleLabel.text = episode.episodeTitle
        loadMangaScenes(url)
        
        startLoadingSceneAnim()
    }
}

extension ViewMangaViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return !self.detailInfoEpisodeTableView.frame.contains(touch.location(in: self.view))
    }
}
