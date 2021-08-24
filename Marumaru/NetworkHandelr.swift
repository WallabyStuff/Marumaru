//
//  NetworkHandelr.swift
//  Marumaru
//
//  Created by 이승기 on 2021/04/22.
//

import UIKit

import SwiftSoup
import RxSwift
import RxCocoa

struct ImageResult {
    var imageCache: ImageCache
    var animate: Bool
}

class NetworkHandler {

    let basePath = "https://marumaru201.com"
    let searchPath = "/bbs/search.php?url=%2Fbbs%2Fsearch.php&stx="
    
    var disposeBag = DisposeBag()
    
    let imageCacheHandler = ImageCacheHandler()
    var runningRequest = [UUID: URLSessionDataTask]()
    var imageCacheArr: [ImageCache] = []
    
    init() {
        fetchImageCaches()
    }
    
    func getDocument(urlString: String, completion: @escaping (Result<Document, Error>) -> Void) {
        DispatchQueue.global().async {
            if let url = URL(string: urlString) {
                do {
                    let html = try String(contentsOf: url, encoding: .utf8)
                    let doc = try SwiftSoup.parse(html)
                    
                    completion(.success(doc))
                } catch {
                    
                    completion(.failure(error))
                }
            }
        }
    }
    
    func getCompleteUrl(url: String) -> String {
        
        if !url.contains(basePath) {
            let completeUrl = "\(basePath)\(url)"
            return completeUrl
        } else {
            return url
        }
    }
    
    func getUpdatedManga(_ completion: @escaping (Result<[Manga], Error>) -> Void) {
        
        getDocument(urlString: basePath) { result in
            do {
                let doc = try result.get()
                let elements = try doc.getElementsByClass("post-row")
                
                var updatedMangaArr = [Manga]()
                
                try elements.forEach { element in
                    let mangaTitle = try element.select("a").text().trimmingCharacters(in: .whitespaces)
                    var thumbnailImageUrl = try String(element.select("img").attr("src")).trimmingCharacters(in: .whitespaces)
                    let mangaUrl = try element.select("a").attr("href").trimmingCharacters(in: .whitespaces)
                    
                    thumbnailImageUrl = self.getCompleteUrl(url: thumbnailImageUrl)
                    
                    let updatedManga = Manga(title: mangaTitle,
                                             link: mangaUrl,
                                             thumbnailImageUrl: thumbnailImageUrl)
                    updatedMangaArr.append(updatedManga)
                }
                completion(.success(updatedMangaArr))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func getTopRankedManga(_ completion: @escaping (Result<[TopRankManga], Error>) -> Void) {
        
        getDocument(urlString: basePath) { result in
            do {
                let doc = try result.get()
                let rankElement = try doc.getElementsByClass("basic-post-list")
                let elements = try rankElement.select("a")
                
                var topRankedMangaArr = [TopRankManga]()
                
                try elements.forEach({ element in
                    let mangaTitle = try element.select("a").text().trimmingCharacters(in: .whitespaces)
                    let mangaUrl = try element.select("a").attr("href").trimmingCharacters(in: .whitespaces)
                    
                    let topRankManga = TopRankManga(title: mangaTitle,
                                                    link: mangaUrl)
                    topRankedMangaArr.append(topRankManga)
                })
                completion(.success(topRankedMangaArr))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func getSearchResult(title: String, _ completion: @escaping (Result<[MangaInfo], Error>) -> Void) {
        let modifiedTitle = title.replacingOccurrences(of: " ", with: "+")
        let fullPath = "\(self.basePath)\(self.searchPath)\(modifiedTitle)"
        let completeUrl = self.transformURLString(fullPath)
        
        if let url = completeUrl?.string {
            getDocument(urlString: url) { result in
                do {
                    let doc = try result.get()
                    let elements = try doc.getElementsByClass("media")
                    
                    var resultMangaArr = [MangaInfo]()
                    
                    try elements.forEach { element in
                        // manga title
                        let mangaTitle = try element.getElementsByClass("media-heading").text()
                        
                        // manga descriptions
                        var descs: [String] = []
                        let descElements = try element.getElementsByClass("text-muted")
                        descElements.forEach { element in
                            do {
                                descs.append(try element.text())
                            } catch {
                                descs.append("")
                                print(error.localizedDescription)
                            }
                        }
                        
                        // thumbnail Image
                        var thumbnailImageUrl = String(try element.select("img").attr("src"))
                        thumbnailImageUrl = self.getCompleteUrl(url: thumbnailImageUrl)
                        
                        // manga Serial Number
                        var mangaSN = ""
                        let link = String(try element.select("a").attr("href"))
                        if let range = link.range(of: "sca=") {
                            mangaSN = String(link[range.upperBound...])
                        }
                        
                        let resultManga = MangaInfo(title: mangaTitle,
                                                    author: descs[0],
                                                    updateCycle: descs[1],
                                                    thumbnailImage: nil,
                                                    thumbnailImageURL: thumbnailImageUrl,
                                                    mangaSN: mangaSN)
                        resultMangaArr.append(resultManga)
                    }
                    completion(.success(resultMangaArr))
                } catch {
                    completion(.failure(error))
                }
            }
        }
    }

    func getEpisode(doc: Document, _ completion: @escaping (Result<[Episode], Error>) -> Void) {
        do {
            let chartDoc = try doc.getElementsByClass("chart").first()
            if let chart = try chartDoc?.select("option") {
                
                var episodeArr = [Episode]()
                
                for (index, Element) in chart.enumerated() {
                    let episodeTitle = try Element.text().trimmingCharacters(in: .whitespaces)
                    let episodeSN = try Element.attr("value")
                    
                    if chart.count - 1 != index { // 마지막 인덱스는 항상 비어서 마지막 인덱스 저장 안되도록
                        episodeArr.append(Episode(title: episodeTitle, serialNumber: episodeSN))
                    }
                }
                completion(.success(episodeArr))
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    func getEpisode(serialNumber: String, _ completion: @escaping (Result<[MangaEpisode], Error>) -> Void) {
        
        let completeUrl = "\(self.basePath)/bbs/cmoic/\(serialNumber)"
        
        getDocument(urlString: completeUrl) { result in
            do {
                let doc = try result.get()
                let headElement = try doc.getElementsByClass("list-wrap")
                
                if let superElement = headElement.first() {
                    let tbody = try superElement.getElementsByTag("tbody")
                    
                    if let tbody = tbody.first() {
                        let elements = try tbody.getElementsByTag("tr")
                        
                        var episodeArr = [MangaEpisode]()
                        
                        try elements.forEach { element in
                            // manga title
                            let mangaTitle = try element.select("a").text().trimmingCharacters(in: .whitespaces)
                            // manga descriptions
                            let description = try element.getElementsByTag("span").text()
                            // manga url
                            var link = String(try element.select("a").attr("href"))
                            link = self.getCompleteUrl(url: link)
                            // thumbnail image url
                            var thumbnailImageUrl = String(try element.select("img").attr("src"))
                            thumbnailImageUrl = self.getCompleteUrl(url: thumbnailImageUrl)
                            
                            let mangaEpisode = MangaEpisode(title: mangaTitle,
                                                            description: description,
                                                            thumbnailImageURL: thumbnailImageUrl,
                                                            mangaURL: link)
                            episodeArr.append(mangaEpisode)
                        }
                        completion(.success(episodeArr))
                    }
                }
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func getMangaScene(url: String, _ completion: @escaping (Result<[MangaScene], Error>) -> Void) {
        
        getDocument(urlString: url) { result in
            do {
                let doc = try result.get()
                self.getMangaScene(doc: doc) { result in
                    do {
                        let mangaSceneArr = try result.get()
                        completion(.success(mangaSceneArr))
                    } catch {
                        completion(.failure(error))
                    }
                }
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func getMangaScene(doc: Document, _ completion: @escaping (Result<[MangaScene], Error>) -> Void) {
        
        do {
            let elements = try doc.getElementsByClass("img-tag")
            
            var sceneArr = [MangaScene]()
            
            try elements.forEach { element in
                var imageUrl = try element.select("img").attr("src")
                imageUrl = self.getCompleteUrl(url: imageUrl)
             
                let mangaScene = MangaScene(sceneImage: nil,
                                            sceneImageUrl: imageUrl)
                sceneArr.append(mangaScene)
            }
            completion(.success(sceneArr))
        } catch {
            completion(.failure(error))
        }
    }
    
    // Get Image with URL
    @discardableResult
    func getImage(_ url: URL, _ completion: @escaping (Result<ImageResult, Error>) -> Void) -> UUID? {
        
        // Check does image existing on Cache data
        var isExists = false
        
        imageCacheArr.forEach { imageCache in
            if imageCache.url == url.path {
                // Already exists on Cache data
                isExists = true
                let result = ImageResult(imageCache: imageCache, animate: false)
                completion(.success(result))
            }
        }

        if isExists { return nil }
        
        let uuid = UUID()
        
        // if image is not existing on Cache data download from url
        let task = URLSession.shared.dataTask(with: url) { data, _, error in
            defer {self.runningRequest.removeValue(forKey: uuid)}
            
            if let data = data, let image = UIImage(data: data) {
                let imageCache = ImageCache(url: url.path,
                                            image: image,
                                            imageAvgColor: image.averageColor ?? ColorSet.shadowColor!)
                
                // Image load from url & save to Cache
                let result = ImageResult(imageCache: imageCache, animate: true)
                completion(.success(result))
                
                // save image to CacheData
                self.imageCacheHandler.addData(imageCache)
                    .subscribe(on: MainScheduler.instance)
                    .subscribe { _ in
                        // Success saving image to cache data STATE
                        self.imageCacheArr.append(imageCache)
                    }
                    .disposed(by: self.disposeBag)

                return
            }
            
            guard let error = error else {
                return
            }
            
            guard (error as NSError).code == NSURLErrorCancelled else {
                completion(.failure(error))
                return
            }
        }
        
        // start loading image
        task.resume()
        
        self.runningRequest[uuid] = task
        return uuid
    }
    
    func cancelLoadImage(_ uuid: UUID) {
        runningRequest[uuid]?.cancel()
        runningRequest.removeValue(forKey: uuid)
    }
    
    private func fetchImageCaches() {
        imageCacheArr.removeAll()
        imageCacheHandler.fetchData()
            .subscribe { event in
                if let imageCaches = event.element {
                    self.imageCacheArr = imageCaches
                }
            }.disposed(by: disposeBag)
    }
    
    // https://stackoverflow.com/questions/48576329/ios-urlstring-not-working-always
    private func transformURLString(_ string: String) -> URLComponents? {
        guard let urlPath = string.components(separatedBy: "?").first else {
            return nil
        }
        var components = URLComponents(string: urlPath)
        if let queryString = string.components(separatedBy: "?").last {
            components?.queryItems = []
            let queryItems = queryString.components(separatedBy: "&")
            for queryItem in queryItems {
                guard let itemName = queryItem.components(separatedBy: "=").first,
                      let itemValue = queryItem.components(separatedBy: "=").last else {
                        continue
                }
                components?.queryItems?.append(URLQueryItem(name: itemName, value: itemValue))
            }
        }
        return components!
    }
}
