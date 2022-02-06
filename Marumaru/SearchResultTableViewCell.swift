//
//  ResultMangaCell.swift
//  Marumaru
//
//  Created by 이승기 on 2021/04/13.
//

import UIKit
import Hero

class SearchResultTableViewCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var updateCycleLabel: TagLabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var thumbnailImageBaseView: ThumbnailView!
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var thumbnailImagePlaceholderLabel: UILabel!
    
    static var identifier = "searchResultTableCell"
    public var onReuse: () -> Void = {}
    
    override func awakeFromNib() {
        setup()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        onReuse()
        
        titleLabel.text = ""
        setupDescription()
        thumbnailImagePlaceholderLabel.isHidden = false
        updateCycleLabel.removeRoundedBackground(foregroundColor: R.color.textBlackLight() ?? .black)
        
        thumbnailImageView.image = UIImage()
        thumbnailImagePlaceholderLabel.text = ""
        setupThumbnailImageBaseView()
    }
    
    private func setup() {
        setupHero()
        setupView()
    }
    
    private func setupHero() {
        self.hero.isEnabled = true
        self.hero.id = "infoContentView"
        thumbnailImageView.hero.id = "previewImage"
        titleLabel.hero.id = "mangaTitleLabel"
    }
    
    private func setupView() {
        setupContentView()
        setupThumbnailImageView()
        setupThumbnailImageBaseView()
        setupSelectedView()
        setupDescription()
    }
    
    private func setupContentView() {
        clipsToBounds = false
        contentView.clipsToBounds = false
    }
    
    private func setupThumbnailImageView() {
        thumbnailImageView.layer.cornerRadius = 8
        thumbnailImageView.contentMode = .scaleAspectFill
    }
    
    private func setupThumbnailImageBaseView() {
        thumbnailImageBaseView.layer.cornerRadius = 8
        thumbnailImageBaseView.setThubmailShadow()
    }
    
    private func setupDescription() {
        descriptionLabel.text = "작가정보 없음"
        updateCycleLabel.text = "미분류"
    }
    
    private func setupSelectedView() {
        let selectionView = UIView(frame: self.frame)
        selectionView.layer.cornerRadius = 20
        selectionView.backgroundColor = R.color.accentBlueLightest() ?? .clear
        self.selectedBackgroundView = selectionView
    }
}

extension SearchResultTableViewCell {
    public func setUpdatedCycleLabelBackground() {
        updateCycleLabel.makeRoundedBackground(cornerRadius: 8,
                                               backgroundColor: R.color.accentBlue() ?? .clear,
                                               foregroundColor: R.color.textWhite() ?? .black)
    }
}
extension UILabel {
    func setBackgroundHighlight(with backgroundColor: UIColor, textColor: UIColor) {
        self.clipsToBounds = true
        self.layer.cornerRadius = 6
        self.backgroundColor = backgroundColor
        self.textColor = textColor
    }
}
