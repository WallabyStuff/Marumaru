//
//  CRUDable.swift
//  Marumaru
//
//  Created by 이승기 on 2022/06/06.
//

import Foundation

import RxSwift

protocol CRUDable {
  associatedtype Item: AnyObject
  
  func addData(_ item: Item) -> Completable
  func fetchData() -> Single<[Item]>
  func deleteData(_ item: Item) -> Completable
  func deleteAll() -> Completable
}
