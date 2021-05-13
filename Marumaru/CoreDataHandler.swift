//
//  SaveToWatchHistory.swift
//  Marumaru
//
//  Created by 이승기 on 2021/04/26.
//

import UIKit
import CoreData

class CoreDataHandler{
    
    var appDelegate = AppDelegate()
    var context = NSManagedObjectContext()
    
    init(){
        self.appDelegate = UIApplication.shared.delegate as! AppDelegate
        self.context = appDelegate.persistentContainer.viewContext
    }
    
    
    
    func saveToWatchHistory(mangaTitle: String, mangaLink: String, mangaPreviewImageUrl: String?, mangaPreviewImage: UIImage?){
        
        DispatchQueue.global(qos: .background).async {
            let entity = NSEntityDescription.entity(forEntityName: "WatchHistory", in: self.context)
            
            if let entity = entity{
                let manga = NSManagedObject(entity: entity, insertInto: self.context)
                
                if mangaTitle.isEmpty || mangaLink.isEmpty{
                    return
                }
                
                
                self.checkExist(mangaLink){ Result in
                    do{
                        let success = try Result.get()
                        
                        if success{
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
                                try self.context.save()
                            }catch{
                                // fail to save manga history
                                print(error.localizedDescription)
                            }
                        }
                    }catch{
                        print(error.localizedDescription)
                    }
                }
            }
        }
        
    }
    
    
    func checkExist(_ link: String, _ completion: @escaping (Result<Bool, Error>) -> Void){
        // check if exists already
        DispatchQueue.global(qos: .background).async {
            self.getWatchHistory(){Result in
                do{
                    let historyArr = try Result.get()
                    
                    historyArr.forEach { WatchHistory in
                        // if watch history is already exsits
                        if WatchHistory.link?.lowercased().trimmingCharacters(in: .whitespaces) == link.lowercased().trimmingCharacters(in: .whitespaces){
                            
                            self.removeFromWatchHistory(object: WatchHistory)
                        }
                    }
                    
                    completion(.success(true))
                }catch{
                    completion(.failure(error))
                }
            }
        }
    }
    
    
    func getWatchHistory(_ completion: @escaping (Result<Array<WatchHistory>, Error>) -> Void){
        
        DispatchQueue.global(qos: .background).async {
            do{
                let watchHistory = try self.context.fetch(WatchHistory.fetchRequest()) as! [WatchHistory]
                
                completion(.success(watchHistory.reversed()))
            }catch{
                print(error.localizedDescription)
                completion(.failure(error))
            }
        }
    }
    

    func removeFromWatchHistory(object: NSManagedObject){
        
        DispatchQueue.main.async {
            
            self.context.delete(object)
            
            do{
                try self.context.save()
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
                        self.removeFromWatchHistory(object: $0)
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
