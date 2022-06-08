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
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var chipContentView: UIView!
    
    
    // MARK: - LifeCycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        setDeselected()
    }
    
    
    // MARK: - Setups
    
    private func setup() {
        setupView()
    }
    
    private func setupView() {
        setupContentView()
    }
    
    private func setupContentView() {
        chipContentView.layer.cornerRadius = 12
        chipContentView.layer.borderWidth = 1
        chipContentView.layer.borderColor = R.color.lineGrayLighter()!.cgColor
    }
    
    
    // MARK: - Methods
    
    public func setSelected() {
        chipContentView.backgroundColor = R.color.accentOrange()!
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
}
