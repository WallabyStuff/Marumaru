//
//  MarumaruApiErrorMessage.swift
//  Marumaru
//
//  Created by 이승기 on 2021/04/22.
//

import UIKit

import SwiftSoup
import RxSwift
import RxCocoa

enum MarumaruApiErrorMessage: Error {
    case wrongBasePath
    case failToGetUrl
    case failToParseHtml
    
    var message: String {
        switch self {
        case .wrongBasePath:
            return "기본 경로가 올바르지 않습니다."
        case .failToGetUrl:
            return "정보를 가져오는데 실패하였습니다."
        case .failToParseHtml:
            return "html파싱에 실패하였습니다."
        }
    }
}

struct ImageResult {
    var imageCache: ImageCache
    var animate: Bool
}

class MarumaruApiService {
    var basePath: String?
    let searchPath = "/bbs/search.php?url=%2Fbbs%2Fsearch.php&stx="
    
    private var disposeBag = DisposeBag()
    private let imageCacheHandler = ImageCacheManager()
    private var runningRequest = [UUID: URLSessionDataTask]()
    private var imageCacheArr: [ImageCache] = []
    private var sharedDoc: Document?
    
    init() {
        fetchImageCaches()
        setupBasePath()
    }
    
    func updateBasePath() {
        let remotePath = "https://raw.githubusercontent.com/Avocado34/Marumaru/develop/Basepath.rtf"
        if let url = URL(string: remotePath) {
            do {
                var remoteBasePath = try String(contentsOf: url, encoding: .utf8)
                remoteBasePath = remoteBasePath.trimmingCharacters(in: .newlines)
                UserDefaults.standard.setValue(remoteBasePath, forKey: "remoteBasePath")
            } catch {
                UserDefaults.standard.setValue("https://marumaru259.com", forKey: "remoteBasePath")
                print(error)
            }
        }
    }
    
    // TODO: - Fetch updated path
    private func setupBasePath() {
        basePath = "https://marumaru259.com"
//        let remoteBasePath = UserDefaults.standard.string(forKey: "remoteBasePath")
//        if let remoteBasePath = remoteBasePath {
//            basePath = remoteBasePath
//        } else {
//            basePath = "https://marumaru232.com"
//        }
    }
    
    public func getDocument(_ url: String) -> Observable<Document> {
        return Observable.create { observer in
            if let url = URL(string: url) {
                do {
                    let html = try String(contentsOf: url, encoding: .utf8)
                    let doc = try SwiftSoup.parse(html)
                    observer.onNext(doc)
                } catch {
                    observer.onError(MarumaruApiErrorMessage.failToParseHtml)
                }
            } else {
                observer.onError(MarumaruApiErrorMessage.failToGetUrl)
            }
            
            return Disposables.create()
        }
    }
}

// MARK: - Updated Comic
extension MarumaruApiService {
    public func getNewUpdateComic() -> Observable<[Comic]> {
        return Observable.create { [weak self] observer in
            guard let self = self else { return Disposables.create() }
            
            guard let basePath = self.basePath else {
                observer.onError(MarumaruApiErrorMessage.wrongBasePath)
                return Disposables.create()
            }
            
            self.getDocument(basePath)
                .subscribe(onNext: { document in
                    do {
                        let comics = try self.parseNewUpdateComic(with: document)
                        observer.onNext(comics)
                    } catch {
                        observer.onError(error)
                    }
                }, onError: { error in
                    observer.onError(error)
                }).dispose()
            
            return Disposables.create()
        }
    }
    
    private func parseNewUpdateComic(with document: Document) throws -> [Comic] {
        do {
            var newUpdateComic = [Comic]()
            
            let elements = try document.getElementsByClass("post-row")
            try elements.forEach { element in
                let comicTitle = try element.select("a").text().trimmingCharacters(in: .whitespaces)
                let comicURL = try element .select("a").attr("href").trimmingCharacters(in: .whitespaces)
                var thumbnailImageUrl = try element.select("img").attr("src").trimmingCharacters(in: .whitespaces)
                thumbnailImageUrl = getEndPoint(url: thumbnailImageUrl)
                
                let comic = Comic(title: comicTitle,
                                  link: comicURL,
                                  thumbnailImageUrl: thumbnailImageUrl)
                newUpdateComic.append(comic)
            }
            
            return newUpdateComic
        } catch {
            throw MarumaruApiErrorMessage.failToParseHtml
        }
    }
}

// MARK: - Top Ranked Managa
extension MarumaruApiService {
    public func getTopRankComic() -> Observable<[TopRankedComic]> {
        return Observable.create { [weak self] observer in
            
            guard let self = self else { return Disposables.create() }
            
            guard let basePath = self.basePath else {
                observer.onError(MarumaruApiErrorMessage.wrongBasePath)
                return Disposables.create()
            }

            self.getDocument(basePath)
                .subscribe(onNext: { document in
                    do {
                        let topRankComic = try self.parseTopRankComic(with: document)
                        observer.onNext(topRankComic)
                    } catch {
                        observer.onError(error)
                    }
                }, onError: { error in
                    observer.onError(error)
                }).dispose()
            
            return Disposables.create()
        }
    }
    
    private func parseTopRankComic(with document: Document) throws -> [TopRankedComic] {
        do {
            var topRankComics = [TopRankedComic]()
            
            let elements = try document.getElementsByClass("basic-post-list")
            let topRankedList = try elements.first()?.getElementsByTag("tr")
            
            try topRankedList?.forEach({ comic in
                let comicTitle = try comic.select("a").text().trimmingCharacters(in: .whitespaces)
                let comicURL = try comic.select("a").attr("href").trimmingCharacters(in: .whitespaces)
                
                let topRankComic = TopRankedComic(title: comicTitle, link: comicURL)
                topRankComics.append(topRankComic)
            })
            
            return topRankComics
        } catch {
            throw MarumaruApiErrorMessage.failToParseHtml
        }
    }
}

// MARK: - Search Result
extension MarumaruApiService {
    public func getSearchResult(title: String) -> Observable<[ComicInfo]> {
        return Observable.create { [weak self] observer in
            guard let self = self else { return Disposables.create() }
            
            guard let basePath = self.basePath else {
                observer.onError(MarumaruApiErrorMessage.wrongBasePath)
                return Disposables.create()
            }
            
            let endPoint = self.getEndPoint(with: title, url: basePath)
            self.getDocument(endPoint)
                .subscribe(onNext: { document in
                    do {
                        let searchResult = try self.parseSearchResult(with: document)
                        observer.onNext(searchResult)
                    } catch {
                        observer.onError(error)
                    }
                }, onError: { error in
                    observer.onError(error)
                }).dispose()
            
            return Disposables.create()
        }
    }
    
    private func parseSearchResult(with document: Document) throws -> [ComicInfo] {
        do {
            var searchResult = [ComicInfo]()
            
            let contents = try document.getElementsByClass("media")
            try contents.forEach { content in
                let comicTitle = try content.getElementsByClass("media-heading").text().trimmingCharacters(in: .whitespaces)
                var thumbnailImageUrl = try content.select("img").attr("src")
                thumbnailImageUrl = self.getEndPoint(url: thumbnailImageUrl)
                
                // Serial Number
                var serialNumber = ""
                let link = try content.select("a").attr("href")
                if let range = link.range(of: "sca=") {
                    serialNumber = link[range.upperBound...].description
                }
                
                // Descriptions
                var descriptions = [String]()
                let descriptionElements = try content.getElementsByClass("text-muted")
                try descriptionElements.forEach { descElement in
                    do {
                        descriptions.append(try descElement.text().trimmingCharacters(in: .whitespaces))
                    } catch {
                        descriptions.append("")
                        throw error
                    }
                }
                
                let conicInfo = ComicInfo(title: comicTitle,
                                            author: descriptions[0],
                                            updateCycle: descriptions[1],
                                            thumbnailImage: nil,
                                            thumbnailImageURL: thumbnailImageUrl,
                                            comicSN: serialNumber)
                searchResult.append(conicInfo)
            }
            
            return searchResult
        } catch {
            throw MarumaruApiErrorMessage.failToParseHtml
        }
    }
}

// MARK: - Episode
extension MarumaruApiService {
    public func getEpisodes(_ serialNumber: String) -> Observable<[ComicEpisode]> {
        return Observable.create { [weak self] observer in
            guard let self = self else { return Disposables.create() }
            
            let endPoint = self.getEndPoint(serialNumber: serialNumber)
            self.getDocument(endPoint)
                .subscribe(onNext: { document in
                    do {
                        let episodes = try self.parseEpisode(with: document)
                        observer.onNext(episodes)
                    } catch {
                        observer.onError(error)
                    }
                }, onError: { error in
                    observer.onError(error)
                }).dispose()

            return Disposables.create()
        }
    }
    
    private func parseEpisode(with document: Document) throws -> [ComicEpisode] {
        do {
            var comicEpisodes = [ComicEpisode]()
            
            let headElement = try document.getElementsByClass("list-wrap")
            if let superElement = headElement.first() {
                let tbody = try superElement.getElementsByTag("tbody")
                
                if let tbody = tbody.first() {
                    let elements = try tbody.getElementsByTag("tr")
                    
                    try elements.forEach { element in
                        let episodeTitle = try element.select("a").text().trimmingCharacters(in: .whitespaces)
                        let description = try element.getElementsByTag("span").text()
                        
                        var link = String(try element.select("a").attr("href"))
                        link = self.getEndPoint(url: link)
                        var thumbnailImageUrl = String(try element.select("img").attr("src"))
                        
                        thumbnailImageUrl = self.getEndPoint(url: thumbnailImageUrl)
                        
                        let comicEpisode = ComicEpisode(title: episodeTitle,
                                                        description: description,
                                                        thumbnailImageURL: thumbnailImageUrl,
                                                        comicURL: link)
                        
                        comicEpisodes.append(comicEpisode)
                    }
                }
            }
            
            return comicEpisodes
        } catch {
            throw MarumaruApiErrorMessage.failToParseHtml
        }
    }
}

extension MarumaruApiService {
    public func getEpisodesInPlay() -> Single<[Episode]> {
        return Single.create { [weak self] observer in
            guard let self = self else { return Disposables.create() }
            
            do {
                let episodes = try self.parseEpisodesInPlay()
                observer(.success(episodes))
            } catch {
                observer(.failure(error))
            }
            
            return Disposables.create()
        }
    }
    
    public func parseEpisodesInPlay() throws -> [Episode] {
        guard let sharedDoc = sharedDoc else {
            throw MarumaruApiErrorMessage.failToParseHtml
        }
        
        do {
            let chartElement = try sharedDoc.getElementsByClass("chart").first()
            var episodes = [Episode]()
            
            if let chartElements = try chartElement?.select("option") {
                // last index of element is always empty
                for (index, chartElement) in chartElements.enumerated() where index != chartElements.count - 1 {
                    let episodeTitle = try chartElement.text().trimmingCharacters(in: .whitespaces)
                    let episodeSN = try chartElement.attr("value")
                    episodes.append(Episode(title: episodeTitle, serialNumber: episodeSN))
                }
            }
            
            return episodes
        } catch {
            throw MarumaruApiErrorMessage.failToParseHtml
        }
    }
}

// MARK: - Comic storp scene
extension MarumaruApiService {
    public func getComicStripScenes(_ url: String) -> Observable<[ComicStripScene]> {
        return Observable.create { [weak self] observer in
            guard let self = self else { return Disposables.create() }
            
            let endPoint = self.getEndPoint(url: url)
            self.getDocument(endPoint)
                .subscribe(with: self, onNext: { strongSelf, document in
                    do {
                        let comicStripScenes = try strongSelf.parseComicScenes(with: document)
                        observer.onNext(comicStripScenes)
                    } catch {
                        observer.onError(error)
                    }
                }, onError: { _, error in
                    observer.onError(error)
                }).dispose()
            
            return Disposables.create()
        }
    }
    
    private func parseComicScenes(with document: Document) throws -> [ComicStripScene] {
        do {
            sharedDoc = document
            var scenes = [ComicStripScene]()
            
            let elements = try document.getElementsByClass("img-tag")
            try elements.forEach { element in
                var imageUrl = try element.select("img").attr("src")
                imageUrl = getEndPoint(url: imageUrl)
                
                let comicScene = ComicStripScene(sceneImage: nil, sceneImageUrl: imageUrl)
                scenes.append(comicScene)
            }
            
            return scenes
        } catch {
            throw MarumaruApiErrorMessage.failToParseHtml
        }
    }
}

// MARK: - Fetch Image
extension MarumaruApiService {
    @discardableResult
    public func requestImage(_ url: String, _ completion: @escaping (Result<ImageResult, Error>) -> Void) -> UUID? {
        guard let url = URL(string: url) else { return nil }
        
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
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self else { return }
            
            defer {self.runningRequest.removeValue(forKey: uuid)}
            
            if let data = data, let image = UIImage(data: data) {
                let imageCache = ImageCache(url: url.path,
                                            image: image,
                                            imageAvgColor: image.averageColor ?? R.color.shadowGray()!)
                
                // Image load from url & save to Cache
                let result = ImageResult(imageCache: imageCache, animate: true)
                completion(.success(result))
                
                // save image to CacheData
                self.imageCacheHandler.addData(imageCache)
                    .subscribe(on: MainScheduler.instance)
                    .subscribe { [weak self] _ in
                        guard let self = self else { return }
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
    
    public func cancelImageRequest(_ uuid: UUID) {
        runningRequest[uuid]?.cancel()
        runningRequest.removeValue(forKey: uuid)
    }
    
    private func fetchImageCaches() {
        imageCacheArr.removeAll()
        imageCacheHandler.fetchData()
            .subscribe { [weak self] event in
                guard let self = self else { return }
                
                if let imageCaches = event.element {
                    self.imageCacheArr = imageCaches
                }
            }.disposed(by: disposeBag)
    }
}

// MARK: - Transforming URL
extension MarumaruApiService {
    private func getEndPoint(url: String) -> String {
        guard let basePath = basePath else { return url }
        return url.contains(basePath) == true ? url : "\(basePath)\(url)"
    }
    
    private func getEndPoint(with title: String, url: String) -> String {
        let modifiedTitle = title.replacingOccurrences(of: " ", with: "+")
        let endPoint = getEndPoint(url: "\(self.searchPath)\(modifiedTitle)")
        return transformURLString(endPoint)?.description ?? endPoint
    }
    
    private func getEndPoint(serialNumber: String) -> String {
        let url = "/bbs/cmoic/\(serialNumber)"
        return getEndPoint(url: url)
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
