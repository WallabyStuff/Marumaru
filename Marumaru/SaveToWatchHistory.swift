//
//  SaveToWatchHistory.swift
//  Marumaru
//
//  Created by 이승기 on 2021/04/26.
//

import UIKit
import CoreData

class CoreDataHandler{
    
    func saveToWatchHistory(mangaTitle: String, mangaLink: String, mangaPreviewImageUrl: String?, mangaPreviewImage: UIImage?){
    
        DispatchQueue.main.async {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            let entity = NSEntityDescription.entity(forEntityName: "WatchHistory", in: context)
            
            if let entity = entity{
                let manga = NSManagedObject(entity: entity, insertInto: context)
                
                if mangaTitle.isEmpty || mangaLink.isEmpty{
                    return
                }
                
                // save title & link
                manga.setValue(mangaTitle, forKey: "title")
                manga.setValue(mangaLink, forKey: "link")
                
                // save preview image url & data safely
                if let mangaPreviewImageUrl = mangaPreviewImageUrl{
                    manga.setValue(mangaPreviewImageUrl, forKey: "preview_image_url")
                }
                if let mangaPreviewImage = mangaPreviewImage{
                    let jpegData = mangaPreviewImage.jpegData(compressionQuality: 1)
                    manga.setValue(jpegData, forKey: "preview_image")
                }
                
                do{
                    try context.save()
                }catch{
                    // fail to save manga history
                    print(error.localizedDescription)
                }
            }
        }
    }
}
