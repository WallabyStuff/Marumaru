//
//  HistoryMangaViewController.swift
//  Marumaru
//
//  Created by 이승기 on 2021/04/19.
//

import UIKit

import CoreData
import Hero
import RxSwift
import RxCocoa

// MARK: - Protocol
protocol DismissDelegate: AnyObject {
    func refreshHistory()
}

class WatchHistoryViewController: UIViewController {
    
    // MARK: - Declarations
    weak var dismissDelegate: DismissDelegate?
    
    var disposeBag = DisposeBag()
    let networkHandler = NetworkHandler()
    let watchHistoryHandler = WatchHistoryHandler()
    var watchHistoryArr = [WatchHistory]()
    let baseUrl = "https://marumaru.cloud"

    @IBOutlet weak var appbarView: UIView!
    @IBOutlet weak var watchHistoryPlaceholderLabel: UILabel!
    @IBOutlet weak var watchHistoryCollectionView: UICollectionView!
    @IBOutlet weak var clearHistoryButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    
    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
    
        initView()
        initInstance()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        loadMangaHistory()
    }

    // MARK: - Overrides
    override func viewDidDisappear(_ animated: Bool) {
        dismissDelegate?.refreshHistory()
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
        appbarView.layer.maskedCorners = CACornerMask([.layerMinXMaxYCorner])
        
        // Manga history collectionView
        watchHistoryCollectionView.contentInset = UIEdgeInsets(top: 0, left: 25, bottom: 0, right: 25)
        
        // clear history Button
        clearHistoryButton.layer.masksToBounds = true
        clearHistoryButton.layer.cornerRadius = 10
        clearHistoryButton.hero.modifiers = [.scale(0)]
        
        // back Button
        backButton.hero.id = "appbarButton"
        backButton.imageEdgeInsets(with: 10)
        backButton.layer.cornerRadius = 13
        
        // watch history placeholder label
        watchHistoryPlaceholderLabel.alpha = 0
    }
    
    func initInstance() {
        // manga history CollectionView
        let mangaThumbnailCollectionCellNib = UINib(nibName: "MangaThumbnailCollectionViewCell", bundle: nil)
        watchHistoryCollectionView.register(mangaThumbnailCollectionCellNib, forCellWithReuseIdentifier: "mangaThumbnailCollectionCell")
        watchHistoryCollectionView.delegate = self
        watchHistoryCollectionView.dataSource = self
    }
    
    // MARK: - Methods
    func loadMangaHistory() {
        watchHistoryArr.removeAll()
        
        self.watchHistoryHandler.fetchData()
            .debug()
            .subscribe(onNext: { watchHistories in
                self.watchHistoryArr = watchHistories
                self.reloadWatchHistoryCollectionView()
            }).disposed(by: self.disposeBag)
    }
    
    func showClearHistoryActionSheet() {
        let deleteMenu = UIAlertController(title: "Clear History", message: "Press delete button to clear all the watch histories", preferredStyle: .actionSheet)
        
        let clearAction = UIAlertAction(title: "Clear History", style: .destructive) { (_) in
            self.clearHistory()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        deleteMenu.addAction(clearAction)
        deleteMenu.addAction(cancelAction)
        
        deleteMenu.popoverPresentationController?.sourceView = clearHistoryButton!
        deleteMenu.popoverPresentationController?.sourceRect = (clearHistoryButton as AnyObject).bounds
        
        self.present(deleteMenu, animated: true)
    }
    
    func clearHistory() {
        watchHistoryHandler.deleteAll()
            .subscribe(onNext: { isDeleted in
                if isDeleted {
                    self.watchHistoryArr.removeAll()
                    self.reloadWatchHistoryCollectionView()
                }
            }).disposed(by: disposeBag)
    }
    
    func presentViewMangaVC(_ mangaTitle: String, _ mangaUrl: String) {
        guard let viewMangaVC = storyboard?.instantiateViewController(identifier: "ViewMangaStoryboard") as? ViewMangaViewController else { return }
        viewMangaVC.modalPresentationStyle = .fullScreen
        
        viewMangaVC.mangaTitle = mangaTitle
        viewMangaVC.mangaUrl = mangaUrl
        
        present(viewMangaVC, animated: true, completion: nil)
    }
    
    func reloadWatchHistoryCollectionView() {
        DispatchQueue.main.async {
            if self.watchHistoryArr.count == 0 {
                self.watchHistoryPlaceholderLabel.startFadeInAnim(duration: 0.5)
            } else {
                self.watchHistoryPlaceholderLabel.startFadeOutAnim(duration: 0.5)
            }
            
            self.watchHistoryCollectionView.reloadData()
        }
    }
    
    // MARK: - Actions
    @IBAction func clearHistoryButtonAction(_ sender: Any) {
        showClearHistoryActionSheet()
    }
    
    @IBAction func backButtonAction(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - Extensions
extension WatchHistoryViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return watchHistoryArr.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let collectionCell = collectionView.dequeueReusableCell(withReuseIdentifier: "mangaThumbnailCollectionCell", for: indexPath) as? MangaThumbnailCollectionCell else { return UICollectionViewCell() }
        
        // init preview image
        collectionCell.thumbnailImageView.image = UIImage()
        
        let currentManga = watchHistoryArr[indexPath.row]
        // set title & place holder
        collectionCell.titleLabel.text = currentManga.mangaTitle
        collectionCell.thumbnailImagePlaceholderLabel.text = currentManga.mangaTitle
        
        if let thumbnailImageUrl = URL(string: currentManga.thumbnailImageUrl) {
            networkHandler.getImage(thumbnailImageUrl) { result in
                do {
                    let result = try result.get()
                    DispatchQueue.main.async {
                        collectionCell.thumbnailImageView.image = result.imageCache.image
                        collectionCell.thumbnailImageBaseView.setThumbnailShadow(with: result.imageCache.averageColor.cgColor)
                        collectionCell.thumbnailImagePlaceholderLabel.isHidden = true
                        collectionCell.thumbnailImageView.startFadeInAnim(duration: 0.3)
                    }
                } catch {
                    DispatchQueue.main.async {
                        collectionCell.thumbnailImagePlaceholderLabel.isHidden = false
                    }
                }
            }
        } else {
            DispatchQueue.main.async {
                collectionCell.thumbnailImagePlaceholderLabel.isHidden = false
            }
        }
        
        collectionCell.hero.modifiers = [.fade, .scale(0.5)]
        
        return collectionCell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if watchHistoryArr.count > indexPath.row {
            var mangaUrl = watchHistoryArr[indexPath.row].mangaUrl
            let mangaTitle = watchHistoryArr[indexPath.row].mangaTitle
//            guard var mangaUrl = watchHistoryArr[indexPath.row].mangaUrl,
//                  let mangaTitle = watchHistoryArr[indexPath.row].mangaTitle else { return }
//
            if !mangaUrl.contains(baseUrl) {
                mangaUrl = "\(baseUrl)\(mangaUrl)"
            }
            
            presentViewMangaVC(mangaTitle, mangaUrl)
        }
    }
}
