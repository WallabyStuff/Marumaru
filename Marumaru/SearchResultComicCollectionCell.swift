//
//  SearchResultComicCollectionCell.swift
//  Marumaru
//
//  Created by 이승기 on 2022/05/24.
//

import UIKit

class SearchResultComicCollectionCell: UICollectionViewCell {

    
    // MARK: - Properties
    
    static let identifier = R.reuseIdentifier.searchResultComicCollectionCell.identifier
    
    @IBOutlet weak var cellContentView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var uploadCycleLabel: TagLabel!
    @IBOutlet weak var thumbnailImagePlaceholderView: ThumbnailPlaceholderView!
    @IBOutlet weak var thumbnailImagePlaceholderLabel: UILabel!
    @IBOutlet weak var thumbnailImageView: UIImageView!
    
    public var onReuse: () -> Void = {}
    
    override var isHighlighted: Bool {
        didSet {
            if isHighlighted == true {
                cellContentView.backgroundColor = R.color.backgroundWhiteLight()
            } else {
                cellContentView.backgroundColor = R.color.backgroundWhite()
            }
        }
    }
    
    
    // MARK: - LifeCycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        onReuse()
        thumbnailImageView.image = nil
        thumbnailImagePlaceholderView.removeThumbnailShadow()
    }
    
    
    // MARK: - Overrides
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        setupCellContentView()
    }
    
    
    // MARK: - Setups
    
    private func setup() {
        setupView()
    }
    
    private func setupView() {
        setupCellContentView()
        setupTitleLabel()
        setupAuthorLabel()
        setupUploadCycleLabel()
        setupThumbnailImagePlaceholderView()
        setupThumbnailImagePlaceholderHolderLabel()
        setupThumbnailImageView()
    }
    
    private func setupCellContentView() {
        clipsToBounds = false
        cellContentView.layer.cornerRadius = 16
        cellContentView.layer.borderWidth = 1
        cellContentView.layer.borderColor = R.color.lineGrayLightest()!.cgColor
        cellContentView.layer.shadowColor = UIColor.gray.cgColor
        cellContentView.layer.shadowOffset = CGSize(width: 0, height: 4)
        cellContentView.layer.shadowRadius = 40
        cellContentView.layer.shadowOpacity = 0.1
    }
    
    private func setupTitleLabel() {
        titleLabel.text = ""
    }
    
    private func setupAuthorLabel() {
        authorLabel.text = "작가정보 없음"
    }
    
    private func setupUploadCycleLabel() {
        uploadCycleLabel.text = "미분류"
        uploadCycleLabel.makeRoundedBackground(cornerRadius: 8,
                                               backgroundColor: .systemTeal,
                                               foregroundColor: .white)
    }
    
    private func setupThumbnailImagePlaceholderView() {
        thumbnailImagePlaceholderView.layer.cornerRadius = 8
    }
    
    private func setupThumbnailImagePlaceholderHolderLabel() {
        thumbnailImagePlaceholderLabel.text = ""
    }
    
    private func setupThumbnailImageView() {
        thumbnailImageView.layer.cornerRadius = 8
        thumbnailImageView.contentMode = .scaleAspectFill
    }
}
