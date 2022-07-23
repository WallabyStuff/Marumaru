//
//  SearchHistoryCollectionViewCell.swift
//  Marumaru
//
//  Created by 이승기 on 2022/05/29.
//

import UIKit
import RxSwift

class SearchHistoryCollectionCell: UICollectionViewCell {

    
    // MARK: - Properties
    
    static let identifier = R.reuseIdentifier.searchHistoryCollectionCell.identifier
    private var disposeBag = DisposeBag()
    public var deleteButtonTapAction: () -> Void = {}
    
    
    // MARK: - UI
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var deleteButton: UIButton!
    
    
    // MARK: - LifeCycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        bind()
    }
    
    
    // MARK: - Binds
    
    private func bind() {
        deleteButton.rx.tap
            .subscribe(with: self, onNext: { strongSelf, _ in
                strongSelf.deleteButtonTapAction()
            })
            .disposed(by: disposeBag)
    }
    
    
    // MARK: - Methods
    
    public func configure(title: String) {
        titleLabel.text = title
    }
}
