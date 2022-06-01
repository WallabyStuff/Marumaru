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

enum MarumaruApiError: Error {
    case wrongBasePath
    case failToGetURL
    case failToParse
    
    var message: String {
        switch self {
        case .wrongBasePath:
            return "기본경로가 올바르지 않습니다."
        case .failToGetURL:
            return "정보를 가져오는데 실패하였습니다."
        case .failToParse:
            return "정보 파싱에 실패하였습니다."
        }
    }
}

struct ImageResult {
    var imageCache: ImageCache
    var animate: Bool
}

class MarumaruApiService {
    
    
    // MARK: - Properties
    
    static let shared = MarumaruApiService()
    
    typealias ComicAndEpisodeSN = (comicSN: String, episodeSN: String)
    typealias URLToDoc = [URL: Document]
    
    var basePath = "https://marumaru260.com"
    static let searchPath = "/bbs/search.php?url=%2Fbbs%2Fsearch.php&stx="
    static let comicPath = "/bbs/cmoic"
    
    private var disposeBag = DisposeBag()
    private var docuemntCache: URLToDoc = [:]
    
    private init() { }
}


// MARK: - Docuemtn parsing

extension MarumaruApiService {
    private func getDocument(_ url: URL?, caching: Bool) -> Single<Document> {
        return Single.create { [weak self] observer in
            guard let self = self,
                  let url = url else {
                return Disposables.create()
            }
            
            // TODO: - Manage docuemnt cache with REALM
            if caching {
                if let cache = self.docuemntCache[url] {
                    observer(.success(cache))
                    return Disposables.create()
                }
            }

            do {
                let html = try String(contentsOf: url, encoding: .utf8)
                let doc = try SwiftSoup.parse(html)
                observer(.success(doc))
                self.docuemntCache[url] = doc
            } catch {
                observer(.failure(MarumaruApiError.failToParse))
            }
            
            return Disposables.create()
        }
    }
}


// MARK: - Updated Comic

extension MarumaruApiService {
    public func getNewComicEpisodes() -> Single<[ComicEpisode]> {
        return Single.create { [weak self] observer in
            guard let self = self else { return Disposables.create() }
            
            self.getDocument(self.baseURL, caching: false)
                .subscribe(onSuccess: { doc in
                    do {
                        let comics = try self.parseNewComicEpisode(with: doc)
                        observer(.success(comics))
                    } catch {
                        observer(.failure(error))
                    }
                }, onFailure: { error in
                    observer(.failure(error))
                }).dispose()
            
            return Disposables.create()
        }
    }
    
    private func parseNewComicEpisode(with document: Document) throws -> [ComicEpisode] {
        do {
            var newUpdateEpisodes = [ComicEpisode]()
            
            let elements = try document.getElementsByClass("post-row")
            try elements.forEach { element in
                let title = try element.select("a").text().trimmingCharacters(in: .whitespaces)
                
                let episodePath = try element .select("a").attr("href").trimmingCharacters(in: .whitespaces)
                let comicAndEpisodeSN = getComicAndEpisodeSN(episodePath)
                
                var imagePath = try element.select("img").attr("src").trimmingCharacters(in: .whitespaces)
                imagePath = imagePath.dropBasePath()
                
                let episode = ComicEpisode(comicSN: comicAndEpisodeSN.comicSN,
                                           episodeSN: comicAndEpisodeSN.episodeSN,
                                           title: title,
                                           description: nil,
                                           thumbnailImagePath: imagePath)
                
                newUpdateEpisodes.append(episode)
            }
            
            return newUpdateEpisodes
        } catch {
            throw MarumaruApiError.failToParse
        }
    }
}


// MARK: - Comic ranks

extension MarumaruApiService {
    public func getComicRank() -> Single<[ComicEpisode]> {
        return Single.create { [weak self] observer in
            guard let self = self else { return Disposables.create() }

            self.getDocument(self.baseURL, caching: false)
                .subscribe(onSuccess: { doc in
                    do {
                        let episode = try self.parseComicRank(with: doc)
                        observer(.success(episode))
                    } catch {
                        observer(.failure(error))
                    }
                }, onFailure: { error in
                    observer(.failure(error))
                }).dispose()
            
            return Disposables.create()
        }
    }
    
    private func parseComicRank(with document: Document) throws -> [ComicEpisode] {
        do {
            var comicRank = [ComicEpisode]()
            
            let elements = try document.getElementsByClass("basic-post-list")
            let comicRankList = try elements.first()?.getElementsByTag("tr")
            
            try comicRankList?.forEach({ comic in
                let title = try comic.select("a").text().trimmingCharacters(in: .whitespaces)
                
                let episodePath = try comic.select("a").attr("href").trimmingCharacters(in: .whitespaces)
                let comicAndEpisodeSN = getComicAndEpisodeSN(episodePath)
                
                let episode = ComicEpisode(comicSN: comicAndEpisodeSN.comicSN,
                                           episodeSN: comicAndEpisodeSN.episodeSN,
                                           title: title,
                                           description: nil,
                                           thumbnailImagePath: nil)
                
                comicRank.append(episode)
            })
            
            return comicRank
        } catch {
            throw MarumaruApiError.failToParse
        }
    }
}


// MARK: - Search comics

extension MarumaruApiService {
    public func getSearchResult(title: String) -> Single<[ComicInfo]> {
        return Single.create { [weak self] observer in
            guard let self = self else { return Disposables.create() }
            
            let url = self.getSearchURL(title)
            self.getDocument(url, caching: true)
                .subscribe(onSuccess: { doc in
                    do {
                        let searchResult = try self.parseSearchResult(with: doc)
                        observer(.success(searchResult))
                    } catch {
                        observer(.failure(error))
                    }
                }, onFailure: { error in
                    observer(.failure(error))
                }).disposed(by: self.disposeBag)
            
            return Disposables.create()
        }
    }
    
    private func parseSearchResult(with document: Document) throws -> [ComicInfo] {
        do {
            var searchResult = [ComicInfo]()
            
            let contents = try document.getElementsByClass("media")
            try contents.forEach { content in
                let title = try content.getElementsByClass("media-heading").text().trimmingCharacters(in: .whitespaces)
                var imagePath = try content.select("img").attr("src")
                imagePath = imagePath.dropBasePath()
                
                // Serial Number
                var comicSN = ""
                let link = try content.select("a").attr("href")
                if let range = link.range(of: "sca=") {
                    comicSN = link[range.upperBound...].description
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
                
                let comicInfo = ComicInfo(comicSN: comicSN,
                                          title: title,
                                          author: descriptions[0],
                                          updateCycle: descriptions[1],
                                          thumbnailImage: nil,
                                          thumbnailImagePath: imagePath)
                
                searchResult.append(comicInfo)
            }
            
            return searchResult
        } catch {
            throw MarumaruApiError.failToParse
        }
    }
}


// MARK: - Comic episodes

extension MarumaruApiService {
    public func getEpisodes(_ comicSN: String) -> Single<[ComicEpisode]> {
        return Single.create { [weak self] observer in
            guard let self = self else { return Disposables.create() }
            
            
            let url = self.getComicURL(comicSN)
            self.getDocument(url, caching: true)
                .subscribe(onSuccess: { document in
                    do {
                        let episodes = try self.parseEpisodes(with: document)
                        observer(.success(episodes))
                    } catch {
                        observer(.failure(error))
                    }
                }, onFailure: { error in
                    observer(.failure(error))
                }).dispose()

            return Disposables.create()
        }
    }
    
    private func parseEpisodes(with document: Document) throws -> [ComicEpisode] {
        do {
            var episodes = [ComicEpisode]()
            
            let headElement = try document.getElementsByClass("list-wrap")
            if let superElement = headElement.first() {
                let tbody = try superElement.getElementsByTag("tbody")
                
                if let tbody = tbody.first() {
                    let elements = try tbody.getElementsByTag("tr")
                    
                    try elements.forEach { element in
                        let title = try element.select("a").text().trimmingCharacters(in: .whitespaces)
                        let description = try element.getElementsByTag("span").text()
                        
                        let episodePath = String(try element.select("a").attr("href"))
                        let comicAndEpisodeSN = getComicAndEpisodeSN(episodePath)
                        
                        var imagePath = String(try element.select("img").attr("src"))
                        imagePath = imagePath.dropBasePath()
                        
                        let episode = ComicEpisode(comicSN: comicAndEpisodeSN.comicSN,
                                                   episodeSN: comicAndEpisodeSN.episodeSN,
                                                   title: title,
                                                   description: description,
                                                   thumbnailImagePath: imagePath)
                        
                        episodes.append(episode)
                    }
                }
            }
            
            return episodes
        } catch {
            throw MarumaruApiError.failToParse
        }
    }
}


// MARK: - Episodes in comic strip

extension MarumaruApiService {
    public func getEpisodesInStrip(_ comicEpisode: ComicEpisode) -> Single<[EpisodeItem]> {
        return Single.create { [weak self] observer in
            guard let self = self else { return Disposables.create() }
            
            let url = self.getEpisodeURL(comicEpisode.comicSN, comicEpisode.episodeSN)
            self.getDocument(url, caching: true)
                .subscribe(onSuccess: { doc in
                    do {
                        let episodes = try self.parseEpisodesInStrip(doc)
                        observer(.success(episodes))
                    } catch {
                        observer(.failure(error))
                    }
                }, onFailure: { error in
                    observer(.failure(error))
                })
                .disposed(by: self.disposeBag)
            
            return Disposables.create()
        }
    }
    
    public func parseEpisodesInStrip(_ document: Document) throws -> [EpisodeItem] {
        do {
            let chartElement = try document.getElementsByClass("chart").first()
            var episodes = [EpisodeItem]()
            
            if let episodeElements = try chartElement?.select("option") {
                
                for (index, chartElement) in episodeElements.enumerated() where index != episodeElements.count - 1 {
                    let title = try chartElement.text().trimmingCharacters(in: .whitespaces)
                    let episodeSN = try chartElement.attr("value")
                    let episode = EpisodeItem(title: title, episodeSN: episodeSN)
                    
                    episodes.append(episode)
                }
            }
            
            return episodes
        } catch {
            throw MarumaruApiError.failToParse
        }
    }
}


// MARK: - Comic strip scenes

extension MarumaruApiService {
    public func getComicStripScenes(_ comicEpisode: ComicEpisode) -> Single<[ComicStripScene]> {
        return Single.create { [weak self] observer in
            guard let self = self else {
                return Disposables.create()
            }
            
            let url = self.getEpisodeURL(comicEpisode.comicSN, comicEpisode.episodeSN)
            self.getDocument(url, caching: true)
                .subscribe(with: self, onSuccess: { strongSelf, doc in
                    do {
                        let comicStripScenes = try strongSelf.parseComicScenes(with: doc)
                        observer(.success(comicStripScenes))
                    } catch {
                        observer(.failure(error))
                    }
                }, onFailure: { _, error in
                    observer(.failure(error))
                }).dispose()
            
            return Disposables.create()
        }
    }
    
    private func parseComicScenes(with document: Document) throws -> [ComicStripScene] {
        do {
            var scenes = [ComicStripScene]()
            
            let elements = try document.getElementsByClass("img-tag")
            try elements.forEach { element in
                var imagePath = try element.select("img").attr("src")
                imagePath = imagePath.dropBasePath()
                let comicScene = ComicStripScene(sceneImage: nil, imagePath: imagePath)
                
                scenes.append(comicScene)
            }
            
            return scenes
        } catch {
            throw MarumaruApiError.failToParse
        }
    }
}


// MARK: - Transforming URL

extension MarumaruApiService {
    
    private var baseURL: URL? {
        if let baseURL = URL(string: basePath) {
            return baseURL
        }
        
        return nil
    }

    private func getEpisodeURL(_ comicSN: String, _ episodeSN: String) -> URL? {
        guard var endPoint = getComicURL(comicSN) else {
            return nil
        }
        
        endPoint.appendPathComponent(episodeSN)
        return endPoint
    }
    
    private func getComicURL(_ comicSN: String) -> URL? {
        guard var endPoint = URL(string: basePath) else {
            return nil
        }
        
        endPoint.appendPathComponent(Self.comicPath)
        endPoint.appendPathComponent(comicSN)
        return endPoint
    }
    
    private func getComicAndEpisodeSN(_ urlString: String) -> ComicAndEpisodeSN {
        var comicAndEpisodeSN: ComicAndEpisodeSN = ("", "")
        let subSequences = urlString.split(separator: "/")
        if subSequences.count >= 2 {
            let comicSN = subSequences[subSequences.count - 2].description
            let episodeSN = subSequences[subSequences.count - 1].description
            
            comicAndEpisodeSN.comicSN = comicSN
            comicAndEpisodeSN.episodeSN = episodeSN
        }
        
        return comicAndEpisodeSN
    }
    
    private func getSearchURL(_ title: String) -> URL? {
        // Note: Do not make search urlPath with (URL). (appendPathComponent) makes wrong urlPath
        var endPoint = basePath
        let transformedTitle = title.replacingOccurrences(of: " ", with: "+")
        let searchPath = "\(Self.searchPath)\(transformedTitle)"
        endPoint.append(searchPath)
        
        if let endPoint = transformURLString(endPoint) {
            let url = URL(string: endPoint.description)
            return url
        }
        
        return nil
    }
    
    public func getImageURL(_ imagePath: String) -> URL? {
        guard var endPoint = URL(string: basePath) else {
            return nil
        }
        
        endPoint.appendPathComponent(imagePath)
        return endPoint
    }
    
    // Code source
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

private extension String {
    func dropBasePath() -> String {
        var resultPath = self
        
        do {
            let regex = try NSRegularExpression(pattern: "[^ ]+.com")
            let firstMatch = regex.firstMatch(in: self, options: [], range: self.fullRange)
            
            guard let firstMatch = firstMatch,
                  let range = Range(firstMatch.range, in: resultPath) else {
                return resultPath
            }

            resultPath.removeSubrange(range)
            return resultPath
        } catch {
            return resultPath
        }
    }

}
