//
//  DocumentCache.swift
//  Marumaru
//
//  Created by 이승기 on 2022/11/13.
//

import Foundation

import RxSwift
import SwiftSoup

final class DocumentProvider {
  
  // MARK: - Properties
  
  static let shared = DocumentProvider()
  private let cache = NSCache<NSString, Document>()
  
  
  // MARK: - Initializers
  
  private init() {}
  
  
  // MARK: - Methods
  
  public func getDocument(_ url: URL?) -> Single<Document> {
    return Single.create { [weak self] observer in
      guard let url = url else {
        observer(.failure(NSError()))
        return Disposables.create()
      }
      
      let urlString = NSString(string: url.description)
      
      // Cache hit
      if let document = self?.cache.object(forKey: urlString) {
        observer(.success(document))
        return Disposables.create()
      }
      
      // Cache miss
      do {
        let html = try String(contentsOf: url, encoding: .utf8)
        let document = try SwiftSoup.parse(html)
        self?.cache.setObject(document, forKey: urlString)
        observer(.success(document))
      } catch {
        observer(.failure(error))
      }
      
      return Disposables.create()
    }
  }
}
