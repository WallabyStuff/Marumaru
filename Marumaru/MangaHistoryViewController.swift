//
//  HistoryMangaViewController.swift
//  Marumaru
//
//  Created by 이승기 on 2021/04/19.
//

import UIKit

import CoreData
import Hero

// MARK: - Protocol
protocol DismissDelegate: AnyObject {
    func refreshHistory()
}

class MangaHistoryViewController: UIViewController {
    
    // MARK: - Declarations
    weak var dismissDelegate: DismissDelegate?
    
    let coredataHandler = HistoryHandler()
    var mangaHistoryArr = [WatchHistory]()
    let baseUrl = "https://marumaru.cloud"

    @IBOutlet weak var appbarView: UIView!
    @IBOutlet weak var mangaHistoryPlaceholderLabel: UILabel!
    @IBOutlet weak var mangaHistoryCollectionView: UICollectionView!
    @IBOutlet weak var clearHistoryButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    
    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
    
        initView()
        initInstance()
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
        mangaHistoryCollectionView.contentInset = UIEdgeInsets(top: 0, left: 25, bottom: 0, right: 25)
        
        // clear history Button
        clearHistoryButton.layer.masksToBounds = true
        clearHistoryButton.layer.cornerRadius = 10
        clearHistoryButton.hero.modifiers = [.scale(0)]
        
        // back Button
        backButton.hero.id = "appbarButton"
        backButton.imageEdgeInsets(with: 10)
        backButton.layer.cornerRadius = 13
    }
    
    func initInstance() {
        mangaHistoryCollectionView.delegate = self
        mangaHistoryCollectionView.dataSource = self
    }
    
    // MARK: - Methods
    func loadMangaHistory() {
        mangaHistoryArr.removeAll()
        mangaHistoryCollectionView.reloadData()
        self.mangaHistoryPlaceholderLabel.isHidden = false
        
        coredataHandler.getWatchHistory { Result in
            do {
                let recentMangas = try Result.get()
                
                self.mangaHistoryArr = recentMangas
                
                DispatchQueue.main.async {
                    if self.mangaHistoryArr.count > 0 {
                        self.mangaHistoryPlaceholderLabel.isHidden = true
                    }
                    
                    self.mangaHistoryCollectionView.reloadData()
                }
            } catch {
                print(error.localizedDescription)
            }
        }
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
        coredataHandler.clearWatchHistory {Result in
            do {
                let success = try Result.get()
                if success {
                    DispatchQueue.main.async {
                        self.mangaHistoryCollectionView.reloadData()
                        self.mangaHistoryArr.removeAll()
                        self.loadMangaHistory()
                    }
                }
            } catch {
                print(error.localizedDescription)
            }
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
extension MangaHistoryViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return mangaHistoryArr.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let collectionCell = collectionView.dequeueReusableCell(withReuseIdentifier: "MangaHistoryCell", for: indexPath) as! MangaCollectionCell
        
        // init preview image
        collectionCell.previewImage.image = UIImage()
        
        if let title = mangaHistoryArr[indexPath.row].title {
            // set title & place holder
            collectionCell.titleLabel.text = title
            collectionCell.previewImagePlaceholderLabel.text = title
        }
        
        // set preview image
        if let previewImage = mangaHistoryArr[indexPath.row].preview_image {
            if !previewImage.isEmpty {
                // preview image is exists
                collectionCell.previewImage.image = UIImage(data: previewImage)
                collectionCell.previewImagePlaceholderLabel.isHidden = true
            } else {
                if let previewImageUrl = mangaHistoryArr[indexPath.row].preview_image_url {
                    if !previewImageUrl.isEmpty {
                        // preview image url is exists
                        DispatchQueue.global(qos: .background).async {
                            do {
                                let url = URL(string: previewImageUrl)
                                
                                if let url = url {
                                    let data = try Data(contentsOf: url)
                                    
                                    DispatchQueue.main.async {
                                        collectionCell.previewImage.image = UIImage(data: data)
                                        collectionCell.previewImagePlaceholderLabel.isHidden = true
                                    }
                                } else {
                                    DispatchQueue.main.async {
                                        collectionCell.previewImagePlaceholderLabel.isHidden = false
                                    }
                                }
                            } catch {
                                DispatchQueue.main.async {
                                    collectionCell.previewImagePlaceholderLabel.isHidden = false
                                }
                                print(error.localizedDescription)
                            }
                        }
                    }
                } else {
                    collectionCell.previewImagePlaceholderLabel.isHidden = false
                }
            }
        } else {
            collectionCell.previewImagePlaceholderLabel.isHidden = false
        }
        
        return collectionCell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if mangaHistoryArr.count > indexPath.row {
            let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
            let destStoryboard = mainStoryboard.instantiateViewController(identifier: "ViewMangaStoryboard") as! ViewMangaViewController
            
            destStoryboard.modalPresentationStyle = .fullScreen
            
            var title = ""
            let link = mangaHistoryArr[indexPath.row].link
            if let unwrappedTitle = mangaHistoryArr[indexPath.row].title {
                title = unwrappedTitle
            }
            
            if var unwrappedLink = link {
                // check link does have baseUrl
                if !unwrappedLink.contains(baseUrl) {
                    unwrappedLink = "\(baseUrl)\(unwrappedLink)"
                }
                
                // pass data
                destStoryboard.mangaUrl = unwrappedLink
                destStoryboard.mangaTitle = title
                
                present(destStoryboard, animated: true, completion: nil)
            }
        }
    }
}
