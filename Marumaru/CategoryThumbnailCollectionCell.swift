//
//  CategoryThumbnailCollectionCell.swift
//  Marumaru
//
//  Created by 이승기 on 2022/06/07.
//

import UIKit

class CategoryThumbnailCollectionCell: UICollectionViewCell {

    
    // MARK: - Properties
    
    static let identifier = R.reuseIdentifier.categoryThumbnailCollectionCell.identifier
    
    @IBOutlet weak var thumbnailImagePlaceholderView: ThumbnailPlaceholderView!
    @IBOutlet weak var thumbnailImagePlaceholderLabel: UILabel!
    @IBOutlet weak var thumbnailImageView: UIImageView!
    
    @IBOutlet weak var updateCycleView: UIView!
    @IBOutlet weak var updateCycleLabel: UILabel!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    
    public var onReuse: () -> Void = {}
    
    
    // MARK: - LifeCycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
        setupView()
    }

    override func prepareForReuse() {
        onReuse()
        thumbnailImageView.image = nil
        thumbnailImagePlaceholderView.removeThumbnailShadow()
    }
    
    
    // MARK: - Setups
    
    private func setup() {
        setupView()
    }
    
    private func setupView() {
        setupContentView()
        setupThumbnailImagePlaceholderView()
        setupThumbnailImageView()
        setupUpdateCycleView()
    }
    
    private func setupContentView() {
        clipsToBounds = false
    }
    
    private func setupThumbnailImagePlaceholderView() {
        thumbnailImagePlaceholderView.layer.cornerRadius = 8
    }
    
    private func setupThumbnailImageView() {
        thumbnailImageView.layer.cornerRadius = 8
        thumbnailImageView.clipsToBounds = true
    }
    
    private func setupUpdateCycleView() {
        updateCycleView.layer.cornerRadius = 8
        updateCycleView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMinYCorner]
    }
}
