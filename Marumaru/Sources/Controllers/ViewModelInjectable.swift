//
//  ViewModelInjectable.swift
//  Marumaru
//
//  Created by 이승기 on 2022/05/22.
//

import UIKit

import RxSwift

protocol ViewModelInjectable: AnyObject {
  
  // MARK: - Types
  
  associatedtype ViewModel: AnyObject
  
  
  // MARK: - Properties
  
  var viewModel: ViewModel { get set }
  
  
  // MARK: - Initializers
  
  init(_ viewModel: ViewModel)
  
  init?(_ coder: NSCoder, _ viewModel: ViewModel)
}
