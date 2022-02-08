//
//  ImageCacheHandler.swift
//  Marumaru
//
//  Created by 이승기 on 2021/08/13.
//

import UIKit

import RealmSwift
import RxSwift
import RxCocoa

enum ImageCacheHandlingError: String, Error {
    case savedImageNotExists = "image is not exists"
    
}

class ImageCacheManager {
    var disposeBag = DisposeBag()
    
    static let secondsInDay: Int64 = 86400
    
    static func updateLastLaunchDate() {
        UserDefaults.standard.set(Date.timeStamp, forKey: "launchDate")
    }
    
    static func cleanChacheIfNeeded() {
        let lastLaunchDate = UserDefaults.standard.double(forKey: "launchDate")
                
        if (Double(Date.timeStamp) - lastLaunchDate) > Double(secondsInDay) * 3 {
            let imageCacheHandler = ImageCacheManager()
            imageCacheHandler.deleteAll()
                .subscribe()
                .dispose()
            
            self.updateLastLaunchDate()
        }
    }

    func addData(url: String,
                 image: UIImage,
                 imageAvgColor: UIColor) -> Observable<Any> {
        return Observable.create { observable in
            DispatchQueue.main.async {
                do {
                    let realmInstance = try Realm()
                    
                    let imageCache = ImageCache(url: url,
                                                image: image,
                                                imageAvgColor: imageAvgColor)
                    
                    try realmInstance.safeWrite {
                        realmInstance.add(imageCache, update: .modified)
                    }
                    observable.onCompleted()
                } catch {
                    observable.onError(error)
                }
            }
            
            return Disposables.create()
        }
    }
    
    func addData(_ imageCache: ImageCache) -> Observable<Any> {
        return Observable.create { observable in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                self.isAlreadyExists(url: imageCache.url)
                    .subscribe { isExists in
                        // if not exists in image cache save new
                        if !isExists {
                            do {
                                let realmInstance = try Realm()
                                
                                try realmInstance.safeWrite {
                                    realmInstance.add(imageCache)
                                }
                                
                                observable.onCompleted()
                            } catch {
                                
                            }
                        }
                    } onError: { error in
                        observable.onError(error)
                    }.disposed(by: self.disposeBag)
            }
            
            return Disposables.create()
        }
    }
    
    func fetchData() -> Observable<[ImageCache]> {
        return Observable.create { observable in
            DispatchQueue.main.async {
                do {
                    let realmInstance = try Realm()
                    let imageCaches = Array(realmInstance.objects(ImageCache.self))
                    
                    observable.onNext(imageCaches)
                    observable.onCompleted()
                } catch {
                    observable.onError(error)
                }
            }
            
            return Disposables.create()
        }
    }
    
    func fetchData(url: String) -> Observable<ImageCache> {
        return Observable.create { observable in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                self.fetchData()
                    .subscribe { imageCaches in
                        imageCaches.forEach { imageCache in
                            if imageCache.url == url {
                                observable.onNext(imageCache)
                                observable.onCompleted()
                            }
                        }
                    } onError: { error in
                        observable.onError(error)
                    }.disposed(by: self.disposeBag)
            }
            
            return Disposables.create()
        }
    }
    
    func isAlreadyExists(url: String) -> Observable<Bool> {
        return Observable.create { observable in
            DispatchQueue.main.async {
                do {
                    let realmInstance = try Realm()
                    let isExists = realmInstance.object(ofType: ImageCache.self, forPrimaryKey: url) == nil ? false : true
                    observable.onNext(isExists)
                    observable.onCompleted()
                } catch {
                    observable.onError(error)
                }
            }
            
            return Disposables.create()
        }
    }
    
    func deleteAll() -> Observable<Any> {
        return Observable.create { observable in
            do {
                let realmInstnace = try Realm()
                
                let objects = realmInstnace.objects(ImageCache.self)
                try realmInstnace.safeWrite {
                    realmInstnace.delete(objects)
                }
                observable.onCompleted()
            } catch {
                observable.onError(error)
            }
            
            return Disposables.create()
        }
    }
    
    func fetchIfsExists(url: String) -> ImageCache? {
        do {
            let realmInstance = try Realm()
            return realmInstance.object(ofType: ImageCache.self, forPrimaryKey: url)
        } catch {
            print(error)
            return nil
        }
    }
}
