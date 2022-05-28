//
//  ComicThumbnailCollectionCell.swift
//  Marumaru
//
//  Created by 이승기 on 2021/04/06.
//

import UIKit

class ComicThumbnailCollectionCell: UICollectionViewCell {
    
    @IBOutlet weak var thumbnailImagePlaceholderView: ThumbnailView!
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var thumbnailImagePlaceholderLabel: UILabel!
    
    static let identifier = R.reuseIdentifier.comicThumbnailCollectionCell.identifier
    public var onReuse: () -> Void = {}
    
    override func awakeFromNib() {
        setup()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        onReuse()
        
        thumbnailImageView.image = nil
        thumbnailImagePlaceholderView.removeThumbnailShadow()
    }
    
    private func setup() {
        setupView()
    }
    
    private func setupView() {
        setupContentView()
        setupThumbnailImageView()
        setupThumbnailImageBaseView()
    }
    
    private func setupContentView() {
        clipsToBounds = false
    }
    
    private func setupThumbnailImageView() {
        thumbnailImageView.layer.cornerRadius = 8
        thumbnailImageView.clipsToBounds = true
    }
    
    private func setupThumbnailImageBaseView() {
        thumbnailImagePlaceholderView.layer.cornerRadius = 8
    }
}
