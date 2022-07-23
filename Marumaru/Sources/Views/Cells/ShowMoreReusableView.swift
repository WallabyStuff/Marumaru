//
//  ShowMoreReusableView.swift
//  Marumaru
//
//  Created by 이승기 on 2022/06/15.
//

import UIKit

import RxSwift
import RxCocoa

class ShowMoreReusableView: UICollectionReusableView {

    
    // MARK: - Properties
    
    static let identifier = R.reuseIdentifier.showMoreReusableView.identifier
    private var disposeBag = DisposeBag()
    public var showMoreButtonTapAction: () -> Void = {}
    
    
    // MARK: - UI
    
    @IBOutlet weak var showMoreButton: IndicatorButton!
    
    
    // MARK: - LifeCycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        bind()
    }
    
    
    // MARK: - Binds
    
    private func bind() {
        bindShowMoreButton()
    }
    
    private func bindShowMoreButton() {
        showMoreButton.rx.tap
            .asDriver()
            .drive(with: self, onNext: { strongSelf, _ in
                strongSelf.showMoreButtonTapAction()
            })
            .disposed(by: disposeBag)
    }
}
