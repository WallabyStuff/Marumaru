//
//  CategoryChipCollectionCell.swift
//  Marumaru
//
//  Created by 이승기 on 2022/06/08.
//

import UIKit

class CategoryChipCollectionCell: UICollectionViewCell {

    
    // MARK: - Properties
    
    static let identifier = R.reuseIdentifier.categoryChipCollectionCell.identifier
    
    
    // MARK: - UI
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var chipContentView: UIView!
    
    
    // MARK: - LifeCycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        setDeselected()
    }
    
    
    // MARK: - Methods
    
    public func setSelected() {
        chipContentView.backgroundColor = R.color.accentIndigo()!
        chipContentView.layer.borderWidth = 0
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = .white
    }
    
    public func setDeselected() {
        chipContentView.backgroundColor = R.color.backgroundWhite()!
        chipContentView.layer.borderWidth = 1
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        titleLabel.textColor = R.color.textBlackLight()!
    }
    
    
    // MARK: - TraitCollection
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        chipContentView.layer.borderColor = R.color.lineGrayLighter()!.cgColor
    }
}
