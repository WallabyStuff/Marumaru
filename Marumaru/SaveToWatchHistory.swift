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
            
            DispatchQueue.global(qos: .background).async {
                let entity = NSEntityDescription.entity(forEntityName: "WatchHistory", in: context)
                
                if let entity = entity{
                    let manga = NSManagedObject(entity: entity, insertInto: context)
                    
                    if mangaTitle.isEmpty || mangaLink.isEmpty{
                        return
                    }
                    
                    // set title & link
                    manga.setValue(mangaTitle, forKey: "title")
                    manga.setValue(mangaLink, forKey: "link")
                    
                    // set preview image url & data safely
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
    
    func getWatchHistory(_ completion: @escaping (Result<Array<WatchHistory>, Error>) -> Void){
        DispatchQueue.main.async {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            DispatchQueue.global(qos: .background).async {
                do{
                    let watchHistory = try context.fetch(WatchHistory.fetchRequest()) as! [WatchHistory]
                    
                    completion(.success(watchHistory.reversed()))
                }catch{
                    print(error.localizedDescription)
                    completion(.failure(error))
                }
            }
        }
    }

    func removeWatchHistory(object: NSManagedObject){
        DispatchQueue.main.async {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            context.delete(object)
            
            do{
                try context.save()
            }catch{
                print(error.localizedDescription)
            }
        }
    }
    
    func clearWatchHistory(_ completion: ( (Result<Bool, Error>) -> Void)?){
        DispatchQueue.global(qos: .background).async {
            self.getWatchHistory(){Result in
                do{
                    let watchHistoryArr = try Result.get()
                    watchHistoryArr.forEach {
                        self.removeWatchHistory(object: $0)
                    }
                    
                    completion?(.success(true))
                }catch{
                    completion?(.failure(error))
                    print(error.localizedDescription)
                }
            }
        }
    }
}
