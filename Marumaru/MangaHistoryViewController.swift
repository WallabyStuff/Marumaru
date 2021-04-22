//
//  HistoryMangaViewController.swift
//  Marumaru
//
//  Created by 이승기 on 2021/04/19.
//

import UIKit
import CoreData

class MangaHistoryViewController: UIViewController {
    
    var mangaHistoryArr = Array<MangaHistory>()
    let baseUrl = "https://marumaru.cloud"

    @IBOutlet weak var mangaHistoryPlaceholderLabel: UILabel!
    @IBOutlet weak var mangaHistoryCollectionView: UICollectionView!
    @IBOutlet weak var clearHistoryButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        initDesign()
        initInstance()
        
        loadMangaHistory()
    }
    
    func initDesign(){
        mangaHistoryCollectionView.contentInset = UIEdgeInsets(top: 0, left: 25, bottom: 0, right: 25)
    }
    
    func initInstance(){
        mangaHistoryCollectionView.delegate = self
        mangaHistoryCollectionView.dataSource = self
    }
    
    
    func loadMangaHistory(){
        mangaHistoryArr.removeAll()
        mangaHistoryCollectionView.reloadData()
        self.mangaHistoryPlaceholderLabel.isHidden = false
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        DispatchQueue.global(qos: .background).async {
            do{
                let recentMangas = try context.fetch(MangaHistory.fetchRequest()) as! [MangaHistory]
                
                self.mangaHistoryArr = recentMangas.reversed()
                
                DispatchQueue.main.async {
                    if self.mangaHistoryArr.count > 0{
                        self.mangaHistoryPlaceholderLabel.isHidden = true
                    }
                    
                    self.mangaHistoryCollectionView.reloadData()
                }
                
            }catch{
                print(error.localizedDescription)
            }
        }
    }
    
    func showClearHistoryActionSheet(){
        let deleteMenu = UIAlertController(title: "Clear History", message: "Press delete button to clear all the watch histories", preferredStyle: .actionSheet)
        
        let clearAction = UIAlertAction(title: "Clear History", style: .destructive) { (UIAlertAction) in
            self.clearHistory()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        deleteMenu.addAction(clearAction)
        deleteMenu.addAction(cancelAction)
        
        deleteMenu.popoverPresentationController?.sourceView = clearHistoryButton!
        deleteMenu.popoverPresentationController?.sourceRect = (clearHistoryButton as AnyObject).bounds
        
        self.present(deleteMenu, animated: true)
    }
    
    func removeHistory(object: NSManagedObject){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        context.delete(object)
        
        do{
            try context.save()
        }catch{
            print(error.localizedDescription)
        }
    }
    
    func clearHistory(){
        mangaHistoryArr.forEach {
            removeHistory(object: $0)
        }
        mangaHistoryCollectionView.reloadData()
    }
    
    @IBAction func clearHistoryButtonAction(_ sender: Any) {
        showClearHistoryActionSheet()
    }
}






extension MangaHistoryViewController: UICollectionViewDelegate, UICollectionViewDataSource{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return mangaHistoryArr.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let collectionCell = collectionView.dequeueReusableCell(withReuseIdentifier: "MangaHistoryCell", for: indexPath) as! MangaCollectionCell
        
        // init preview image
        collectionCell.previewImage.image = UIImage()
        
        if let title = mangaHistoryArr[indexPath.row].title{
            // set title & place holder
            collectionCell.titleLabel.text = title
            collectionCell.previewImagePlaceholderLabel.text = title
        }
        
        // set preview image
        if let previewImage = mangaHistoryArr[indexPath.row].preview_image{
            if !previewImage.isEmpty{
                // preview image is exists
                collectionCell.previewImage.image = UIImage(data: previewImage)
                collectionCell.previewImagePlaceholderLabel.isHidden = true
            }else{
                if let previewImageUrl = mangaHistoryArr[indexPath.row].preview_image_url{
                    if !previewImageUrl.isEmpty{
                        // preview image url is exists
                        DispatchQueue.global(qos: .background).async {
                            do{
                                let url = URL(string: previewImageUrl)
                                
                                if let url = url{
                                    let data = try Data(contentsOf: url)
                                    
                                    DispatchQueue.main.async {
                                        collectionCell.previewImage.image = UIImage(data: data)
                                        collectionCell.previewImagePlaceholderLabel.isHidden = true
                                    }
                                }else{
                                    DispatchQueue.main.async {
                                        collectionCell.previewImagePlaceholderLabel.isHidden = false
                                    }
                                }
                            }catch{
                                DispatchQueue.main.async {
                                    collectionCell.previewImagePlaceholderLabel.isHidden = false
                                }
                                print(error.localizedDescription)
                            }
                        }
                    }
                }else{
                    collectionCell.previewImagePlaceholderLabel.isHidden = false
                }
            }
        }else{
            collectionCell.previewImagePlaceholderLabel.isHidden = false
        }
        
        return collectionCell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let destStoryboard = mainStoryboard.instantiateViewController(identifier: "ViewMangaStoryboard") as! ViewMangaViewController
        
        destStoryboard.modalPresentationStyle = .fullScreen
        
        let link = mangaHistoryArr[indexPath.row].link
        
        if var unwrappedlink = link{
            // check link does have baseUrl
            if !unwrappedlink.contains(baseUrl){
                unwrappedlink = "\(baseUrl)\(unwrappedlink)"
            }
            
            // pass data
            destStoryboard.mangaUrl = unwrappedlink
            
            present(destStoryboard, animated: true, completion: nil)
        }
    }
}
