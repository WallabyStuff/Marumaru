//
//  SingleButtonFooterReusableView.swift
//  Marumaru
//
//  Created by 이승기 on 2022/05/31.
//

import UIKit
import RxSwift

class SingleButtonFooterReusableView: UICollectionReusableView {

    
    // MARK: - Properties
    
    static let identifier = R.reuseIdentifier.singleButtonFooterReusableView.identifier
    
    @IBOutlet weak var mainButton: UIButton!
    
    public var mainButtonTapAction: () -> Void = {}
    private var disposeBag = DisposeBag()
    
    
    // MARK: - Lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        bind()
    }
    
    
    // MARK: Binds
    
    private func bind() {
        bindMainButton()
    }
    
    private func bindMainButton() {
        mainButton.rx.tap
            .asDriver()
            .drive(with: self, onNext: { strongSelf, _  in
                strongSelf.mainButtonTapAction()
            })
            .disposed(by: disposeBag)
    }
    
}
