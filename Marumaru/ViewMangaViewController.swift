//
//  ViewMangaViewController.swift
//  Marumaru
//
//  Created by 이승기 on 2021/04/08.
//

import UIKit

import SwiftSoup
import Lottie
import Toast
import Hero
import RxSwift
import RxCocoa
import RxGesture

class ViewMangaViewController: UIViewController {
    
    // MARK: - Declarations
    var disposeBag = DisposeBag()
    let networkHandler = NetworkHandler()
    let watchHistoryHandler = WatchHistoryHandler()
    
    var currentEpisodeIndex: Int?
    var sharedDoc: Document?
    var mangaTitle: String = ""
    var mangaUrl: String = ""
    var episodeArr = [Episode]()
    var sceneArr = [MangaScene]()
    var cellHeightDictionary: NSMutableDictionary = [:]
    let safeAreaInsets = UIApplication.shared.windows[0].safeAreaInsets
    var isSceneZoomed = false
    
    var loadingSceneAnimView = AnimationView()
    var detailInfoView = UIView()
    var detailInfoTitleLabel = UILabel()
    var detailInfoEpisodeSizeLabel = UILabel()
    var detailInfoEpisodeTableView = UITableView()
    
    @IBOutlet weak var showEpisodeListButton: UIButton!
    @IBOutlet weak var nextEpisodeButton: UIButton!
    @IBOutlet weak var previousEpisodeButton: UIButton!
    @IBOutlet weak var appbarView: UIView!
    @IBOutlet weak var bottomIndicatorView: UIView!
    @IBOutlet weak var mangaTitleLabel: UILabel!
    @IBOutlet weak var sceneScrollView: UIScrollView!
    @IBOutlet weak var sceneScrollContentView: UIView!
    @IBOutlet weak var sceneTableView: UITableView!
    @IBOutlet weak var backButton: UIButton!
    
    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initData()
        initView()
        initInstance()
        initEventListener()
        
        indicatorState(false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        setMangaScene(mangaUrl)
    }
    
    // MARK: - Overrides
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .darkContent
    }
    
    // MARK: - Initializations
    func initData() {
        if mangaUrl.isEmpty {
            dismiss(animated: true, completion: nil)
        }
        
        if mangaTitle.isEmpty {
            dismiss(animated: true, completion: nil)
        } else {
            mangaTitleLabel.text = mangaTitle
        }
    }
    
    func initView() {
        // hero enable
        self.hero.isEnabled = true
        
        // loading scene AnimView
        loadingSceneAnimView = AnimationView(name: "loading_square")
        loadingSceneAnimView.frame = CGRect(x: 0, y: 0, width: 300, height: 300)
        loadingSceneAnimView.loopMode = .loop
        view.addSubview(loadingSceneAnimView)
        loadingSceneAnimView.translatesAutoresizingMaskIntoConstraints = false
        loadingSceneAnimView.centerXAnchor.constraint(equalTo: sceneTableView.centerXAnchor).isActive = true
        loadingSceneAnimView.centerYAnchor.constraint(equalTo: sceneTableView.centerYAnchor).isActive = true
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
        
        // scene ScrollView
        sceneScrollView.minimumZoomScale = 1
        sceneScrollView.maximumZoomScale = 3
        
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
        showEpisodeListButton.layer.cornerRadius = 10
        showEpisodeListButton.imageEdgeInsets(with: 8)
        
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
        // manga Scene TableView
        sceneTableView.delegate = self
        sceneTableView.dataSource = self
        
        // detail info episode TableView
        detailInfoEpisodeTableView.register(MangaEpisodePopoverCell.self, forCellReuseIdentifier: "EpisodeCell")
        detailInfoEpisodeTableView.dataSource = self
        detailInfoEpisodeTableView.delegate = self
        
        // scene ScrollView
        sceneScrollView.delegate = self
    }
    
    func initEventListener() {
        // appbar tap gesture
        appbarView.rx.tapGesture()
            .when(.recognized)
            .subscribe(onNext: { _ in
                self.showDetailInfoView()
            })
            .disposed(by: disposeBag)
        
        // detail info View tap gesture
        detailInfoView.rx.tapGesture()
            .when(.recognized)
            .subscribe(onNext: { gestureRecognizer in
                gestureRecognizer.delegate = self
                self.hideDetailInfoView()
            })
            .disposed(by: disposeBag)
        
        // back Button Action
        backButton.rx.tap
            .asDriver()
            .drive(onNext: {
                self.dismiss(animated: true, completion: nil)
            })
            .disposed(by: disposeBag)
        
        // previousEpisode Butotn Action
        previousEpisodeButton.rx.tap
            .asDriver()
            .drive(onNext: {
                self.loadPreviousEpisode()
            })
            .disposed(by: disposeBag)
        
        // nextEpisode Button Action
        nextEpisodeButton.rx.tap
            .asDriver()
            .drive(onNext: {
                self.loadNextEpisode()
            })
            .disposed(by: disposeBag)
        
        // showEpisode List Button Action
        showEpisodeListButton.rx.tap
            .asDriver()
            .drive(onNext: {
                self.presentEpisodePopoverVC()
            })
            .disposed(by: disposeBag)
        
        // Scene Double Tap Action
        let sceneDoubleTapGestureRecognizer = UITapGestureRecognizer()
        sceneDoubleTapGestureRecognizer.numberOfTapsRequired = 2
        sceneTableView.addGestureRecognizer(sceneDoubleTapGestureRecognizer)
        sceneTableView.rx
            .gesture(sceneDoubleTapGestureRecognizer)
            .when(.recognized)
            .subscribe(onNext: { recognizer in
                let tapPoint = recognizer.location(in: self.view)
                self.zoom(point: tapPoint)
            })
            .disposed(by: disposeBag)

        // Scene Single Tap Action
        let sceneTapGestureRocognizer = UITapGestureRecognizer()
        sceneTapGestureRocognizer.numberOfTapsRequired = 1
        sceneTapGestureRocognizer.require(toFail: sceneDoubleTapGestureRecognizer)
        sceneTableView.rx
            .gesture(sceneTapGestureRocognizer)
            .when(.recognized)
            .subscribe(onNext: { _ in
                if self.appbarView.alpha == 0 {
                    self.showNavigationBar()
                } else {
                    self.hideNavigationBar()
                }
            })
            .disposed(by: disposeBag)
        
        // when scene TableView reached the bottom & top
        sceneTableView.rx.contentOffset
            .subscribe(onNext: { offset in
                // reached the top
                if offset.y < -50 {
                    self.showNavigationBar()
                }
                
                // reached the bottom
                if offset.y + 700 > self.sceneTableView.contentSize.height {
                    self.showNavigationBar()
                }
            })
            .disposed(by: disposeBag)
        
        // scene TableView start Scrolling
        sceneTableView.rx.panGesture()
            .when(.began)
            .subscribe(onNext: { _ in
                self.hideNavigationBar()
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Methods
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
    
    func setMangaScene(_ mangaUrl: String) {
        startLoadingSceneAnim()
        sceneArr.removeAll()
        sceneTableView.reloadData()
        indicatorState(false)
        
        DispatchQueue.global(qos: .background).async {
            self.networkHandler.getDocument(urlString: mangaUrl) { result in
                do {
                    let doc = try result.get()
                    self.sharedDoc = doc
                    
                    self.networkHandler.getMangaScene(doc: doc) { result in
                        do {
                            let result = try result.get()
                            self.sceneArr = result
                            
                            DispatchQueue.main.sync {
                                self.stopLoadingSceneAnim()
                                self.sceneTableView.reloadData()
                                self.saveToHistory()
                                self.prepareMangaScene()
                                self.setMangaEpisode()
                            }
                        } catch {
                            // failure State
                            print(error)
                        }
                    }
                } catch {
                    print(error)
                }
            }
        }
    }
    
    func setMangaEpisode() {
        episodeArr.removeAll()
        
        DispatchQueue.global(qos: .background).async {
            if let doc = self.sharedDoc {
                self.networkHandler.getEpisode(doc: doc) { result in
                    do {
                        let episodeArr = try result.get()
                        self.episodeArr = episodeArr
                        
                        for (index, episode) in episodeArr.enumerated() {
                            // get current episode index
                            if self.mangaUrl.contains(episode.serialNumber) {
                                self.mangaTitle = episode.title
                                self.currentEpisodeIndex = index
                                // replace with full manga title
                                DispatchQueue.main.async {
                                    self.mangaTitleLabel.text = episode.title
                                }
                            }
                        }
                        
                        DispatchQueue.main.async {
                            self.indicatorState(true)
                            self.detailInfoEpisodeTableView.reloadData()
                            self.detailInfoEpisodeSizeLabel.text = "총 \(self.episodeArr.count)화"
                            self.scrollToCurrentEpisodeOnInfoView()
                        }
                    } catch {
                        // failure state
                        print(error)
                    }
                }
            } else {
                // shared document is nil State
            }
        }
    }
    
    func saveToHistory() {
        // save to watch history
        if self.sceneArr.count > 0 {
            self.watchHistoryHandler.addData(mangaUrl: self.mangaUrl,
                                             mangaTitle: self.mangaTitle,
                                             thumbnailImageUrl: self.sceneArr[0].sceneImageUrl)
                .subscribe()
                .disposed(by: self.disposeBag)
        } else {
            // first scene image is not exists
            self.watchHistoryHandler.addData(mangaUrl: self.mangaUrl,
                                             mangaTitle: self.mangaTitle,
                                             thumbnailImageUrl: "")
                .subscribe()
                .disposed(by: self.disposeBag)
        }
    }
    
    func presentEpisodePopoverVC() {
        guard let episodePopoverVC = storyboard?.instantiateViewController(identifier: "EpisodePopoverStoryboard") as? EpisodePopoverViewController else { return }
        
        episodePopoverVC.modalPresentationStyle = .popover
        episodePopoverVC.preferredContentSize = CGSize(width: 200, height: 300)
        episodePopoverVC.popoverPresentationController?.permittedArrowDirections = .down
        episodePopoverVC.popoverPresentationController?.sourceRect = showEpisodeListButton.bounds
        episodePopoverVC.popoverPresentationController?.sourceView = showEpisodeListButton
        episodePopoverVC.presentationController?.delegate = self
        episodePopoverVC.selectItemDelegate = self
        
        episodePopoverVC.episodeArr = episodeArr
        
        if let index = currentEpisodeIndex {
            episodePopoverVC.currentEpisode = episodeArr[index]
            episodePopoverVC.currentEpisodeIndex = index
            present(episodePopoverVC, animated: true, completion: nil)
        }
    }
    
    func loadNextEpisode() {
        if !episodeArr.isEmpty {
            if let currentEpisodeIndex = currentEpisodeIndex {
                if 0 <= currentEpisodeIndex - 1 {
                    
                    let nextEpisode = episodeArr[currentEpisodeIndex - 1]
                    
                    mangaTitle = nextEpisode.title
                    mangaTitleLabel.text = nextEpisode.title
                    
                    let url = replaceSerialNumber(nextEpisode.serialNumber)
                    setMangaScene(url)
                    
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
                    
                    mangaTitle = prevEpisode.title
                    mangaTitleLabel.text = prevEpisode.title
                    
                    let url = replaceSerialNumber(prevEpisode.serialNumber)
                    setMangaScene(url)
                    
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
            showEpisodeListButton.isEnabled = true
        } else {
            nextEpisodeButton.isEnabled = false
            previousEpisodeButton.isEnabled = false
            showEpisodeListButton.isEnabled = false
        }
    }
    
    func prepareMangaScene() {
        sceneArr.forEach { scene in
            if let url = URL(string: scene.sceneImageUrl) {
                self.networkHandler.getImage(url) { _ in
                    // successfully save the scene to image Cache
                }
            }
        }
    }
    
    func showNavigationBar() {
        if appbarView.alpha == 0 {
            appbarView.startFadeInAnim(duration: 0.3)
            bottomIndicatorView.startFadeInAnim(duration: 0.3)
        }
    }
    
    func hideNavigationBar() {
        if appbarView.alpha == 1 {
            appbarView.startFadeOutAnim(duration: 0.3)
            bottomIndicatorView.startFadeOutAnim(duration: 0.3)
        }
    }
    
    func zoom(point: CGPoint) {
        if isSceneZoomed {
            // zoom out
            showNavigationBar()
            sceneScrollView.zoom(to: CGRect(x: point.x, y: point.y, width: self.view.frame.width, height: self.view.frame.height), animated: true)
            isSceneZoomed = false
        } else {
            // zoom in
            hideNavigationBar()
            sceneScrollView.zoom(to: CGRect(x: point.x, y: point.y, width: self.view.frame.width / 2, height: self.view.frame.height / 2), animated: true)
            isSceneZoomed = true
        }
    }
    
    @objc
    func didTapScene(_ sender: UITapGestureRecognizer) {
        if sender.state == .recognized {
            if self.appbarView.alpha == 0 {
                self.showNavigationBar()
            } else {
                self.hideNavigationBar()
            }
        }
    }
    
    @objc
    func didDoubleTapScene(_ sender: UITapGestureRecognizer) {
        if sender.state == .recognized {
            let tapPoint = sender.location(in: self.view)
            self.zoom(point: tapPoint)
        }
    }
}

// MARK: - Extensions
extension ViewMangaViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch tableView {
        case sceneTableView:
            return sceneArr.count
        case detailInfoEpisodeTableView:
            return episodeArr.count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch tableView {
        case sceneTableView:
            guard let sceneCell = tableView.dequeueReusableCell(withIdentifier: "MangaSceneCell") as? MangaSceneCell else { return UITableViewCell() }
            
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
            if let url = URL(string: sceneArr[indexPath.row].sceneImageUrl) {
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
                            print(error)
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
            guard let episodeCell = tableView.dequeueReusableCell(withIdentifier: "EpisodeCell") as? MangaEpisodePopoverCell else { return UITableViewCell() }
            
            if indexPath.row > episodeArr.count - 1 {
                return UITableViewCell()
            }
            
            // Accent text color to current episode
            if let currentEpisodeIndex = currentEpisodeIndex {
                if episodeArr[indexPath.row].title.lowercased().trimmingCharacters(in: .whitespaces) == episodeArr[currentEpisodeIndex].title.lowercased().trimmingCharacters(in: .whitespaces) {
                    episodeCell.textLabel?.textColor = ColorSet.accentColor
                } else {
                    episodeCell.textLabel?.textColor = ColorSet.textColor
                }
            }
            
            // selection View
            let selectionView = UIView(frame: episodeCell.frame)
            selectionView.backgroundColor = ColorSet.cellSelectionColor?.withAlphaComponent(0.5)
            selectionView.layer.cornerRadius = 12
            episodeCell.selectedBackgroundView = selectionView
            
            episodeCell.textLabel?.text = episodeArr[indexPath.row].title
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
            if episodeArr.count > 0 {
                mangaTitle = episodeArr[indexPath.row].title
                mangaTitleLabel.text = episodeArr[indexPath.row].title
                
                hideDetailInfoView()
                
                let url = replaceSerialNumber(episodeArr[indexPath.row].serialNumber)
                setMangaScene(url)
            }
        }
    }
}

extension ViewMangaViewController: UIScrollViewDelegate {
    
    // Set scene scrollview zoomable
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.sceneScrollContentView
    }
}

extension UIViewController: UIPopoverPresentationControllerDelegate {
    public func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
}

extension ViewMangaViewController: SelectItemDelegate {
    func loadSelectedEpisode(_ episode: Episode) {
        mangaTitle = episode.title
        mangaTitleLabel.text = episode.title
        
        let url = replaceSerialNumber(episode.serialNumber)
        setMangaScene(url)
        
        startLoadingSceneAnim()
    }
}

extension ViewMangaViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return !self.detailInfoEpisodeTableView.frame.contains(touch.location(in: self.view))
    }
}
