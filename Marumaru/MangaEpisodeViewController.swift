//
//  MangaContentViewController.swift
//  Marumaru
//
//  Created by 이승기 on 2021/04/08.
//

import UIKit

import Lottie
import Hero
import RxSwift
import RxCocoa

class MangaEpisodeViewController: UIViewController {

    // MARK: - Declarations
    var mangaSN: String?
    var currentManga: MangaInfo?
    
    var disposeBag = DisposeBag()
    let watchHistoryHandler = WatchHistoryHandler()
    var watchHistoryArr = [WatchHistory]()
    let networkHandler = NetworkHandler()
    var episodeArr = [MangaEpisode]()
    
    var loadingEpisodeAnimView = LoadingView()
    
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
        initEventListener()
        
        setMangaInfo()
        setMangaEpisode()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        getWatchHistory()
        mangaEpisodeTableView.reloadData()
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
        loadingEpisodeAnimView = LoadingView(name: "loading_cat",
                                             loopMode: .autoReverse,
                                             frame: CGRect(x: 0, y: 0, width: 150, height: 150))
        self.view.addSubview(loadingEpisodeAnimView)
        loadingEpisodeAnimView.setConstraint(width: 150, targetView: mangaEpisodeTableView)
    }
    
    func initInstance() {
        // manga episode TableView
        let mangaEpisodeTableCellNib = UINib(nibName: "MangaEpisodeTableViewCell", bundle: nil)
        mangaEpisodeTableView.register(mangaEpisodeTableCellNib, forCellReuseIdentifier: "mangaEpisodeTableCell")
        mangaEpisodeTableView.delegate = self
        mangaEpisodeTableView.dataSource = self
    }
    
    func initEventListener() {
        // back Button Action
        backButton.rx.tap
            .asDriver()
            .drive(onNext: {
                self.dismiss(animated: true, completion: nil)
            })
            .disposed(by: disposeBag)
        
        // scroll to bottom Button Action
        scrollToBottomButton.rx.tap
            .asDriver()
            .drive(onNext: {
                self.scrollToBottom()
            })
            .disposed(by: disposeBag)
    }
    
    func setMangaInfo() {
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
                            // fail to get representative Image State
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Methods
    // get episode data from url
    func setMangaEpisode() {
        if episodeArr.count > 0 {
            return
        }
        
        loadingEpisodeAnimView.play()
        
        DispatchQueue.global(qos: .background).async {
            self.networkHandler.getEpisode(serialNumber: self.currentManga!.mangaSN) { result in
                do {
                    let result = try result.get()
                    self.episodeArr = result
                    
                    DispatchQueue.main.async {
                        self.loadingEpisodeAnimView.stop { isDone in
                            if isDone {
                                self.mangaEpisodeTableView.reloadData()
                                self.episodeSizeLabel.text = "총 \(self.episodeArr.count)화"
                            }
                        }
                    }
                } catch {
                    // failure state
                    DispatchQueue.main.async {
                        self.loadingEpisodeAnimView.stop()
                    }
                }
            }
        }
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
    
    func scrollToBottom() {
        if self.mangaEpisodeTableView.contentSize.height > 0 {
            let indexPath = IndexPath(row: self.episodeArr.count - 1, section: 0)
            
            self.mangaEpisodeTableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }
    
    func presentViewMangaVC(_ mangaTitle: String, _ mangaUrl: String) {
        guard let viewMangaVC = storyboard?.instantiateViewController(identifier: "ViewMangaStoryboard") as? ViewMangaViewController else { return }
        viewMangaVC.modalPresentationStyle = .fullScreen
        
        viewMangaVC.mangaUrl = mangaUrl
        viewMangaVC.mangaTitle = mangaTitle
        
        present(viewMangaVC, animated: true, completion: nil)
    }
    
    func isAlreadyWatched(url: String) -> Bool {
        var isWatched = false
        watchHistoryArr.forEach { watchHistory in
            if watchHistory.mangaUrl.trimmingCharacters(in: .whitespaces) == url.trimmingCharacters(in: .whitespaces) {
                isWatched = true
            }
        }
        
        return isWatched
    }
    
    func getWatchHistory() {
        watchHistoryArr.removeAll()
        
        watchHistoryHandler.fetchData()
            .subscribe(onNext: { watchHistories in
                self.watchHistoryArr = watchHistories
            }).disposed(by: disposeBag)
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
        
        let currentEpisode = episodeArr[indexPath.row]
        
        episodeCell.titleLabel.text = currentEpisode.title
        episodeCell.descriptionLabel.text = currentEpisode.description
        episodeCell.indexLabel.text = String(episodeArr.count - indexPath.row)
        episodeCell.thumbnailImageView.image = nil
        
        if isAlreadyWatched(url: currentEpisode.mangaURL) {
            episodeCell.setWatched()
        } else {
            episodeCell.setNotWatched()
        }
        
        if let previewImageUrl = currentEpisode.thumbnailImageURL {
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
                            // fail to get episode thumbnail Image State
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
            mangaUrl = networkHandler.getCompleteUrl(url: mangaUrl)
            
            let mangaTitle = episodeArr[indexPath.row].title.trimmingCharacters(in: .whitespaces)
            
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
