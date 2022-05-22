//
//  ViewModelInjectable.swift
//  Marumaru
//
//  Created by 이승기 on 2022/05/22.
//

import UIKit
import RxSwift

protocol ViewModelInjectable: AnyObject {
    associatedtype ViewModel: AnyObject
    
    var viewModel: ViewModel { get set }
    
    var disposeBag: DisposeBag { get set }
    
    init(_ viewModel: ViewModel)
    
    init?(_ coder: NSCoder,
          _ viewModel: ViewModel)
}
