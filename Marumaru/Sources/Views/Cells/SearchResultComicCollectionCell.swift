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
  
  
  // MARK: - UI
  
  @IBOutlet weak var cellContentView: UIView!
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var authorLabel: UILabel!
  @IBOutlet weak var updateCycleLabel: TagLabel!
  @IBOutlet weak var thumbnailImagePlaceholderView: ThumbnailPlaceholderView!
  @IBOutlet weak var thumbnailImagePlaceholderLabel: UILabel!
  @IBOutlet weak var thumbnailImageView: UIImageView!
  
  
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
    setupThumbnailImagePlaceholderHolderLabel()
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
    updateCycleLabel.text = "미분류"
    updateCycleLabel.makeRoundedBackground(cornerRadius: 6,
                                           backgroundColor: .systemTeal,
                                           foregroundColor: .white)
  }
  
  private func setupThumbnailImagePlaceholderHolderLabel() {
    thumbnailImagePlaceholderLabel.text = ""
  }
  
  // MARK: - Methods
  
  public func configure(with comicInfo: ComicInfo) {
    hideSkeleton()
    
    titleLabel.text = comicInfo.title
    thumbnailImagePlaceholderLabel.text = comicInfo.title
    authorLabel.text = comicInfo.author.isEmpty ? "작가정보 없음" : comicInfo.author
    updateCycleLabel.text = comicInfo.updateCycle
    updateCycleLabel.makeRoundedBackground(cornerRadius: 6,
                                           backgroundColor: UpdateCycle(rawValue: comicInfo.updateCycle)?.color,
                                           foregroundColor: .white)
    setThumbnailImage(comicInfo.thumbnailImagePath)
  }
  
  private func setThumbnailImage(_ imagePath: String?) {
    guard let thumbnailImageURL = MarumaruApiService.shared.getImageURL(imagePath) else {
      return
    }
    
    thumbnailImageView.kf.setImage(with: thumbnailImageURL, options: [.transition(.fade(0.3)), .forceTransition]) { [weak self] result in
      guard let self = self else { return }
      
      do {
        let result = try result.get()
        let image = result.image
        self.thumbnailImagePlaceholderView.makeThumbnailShadow(with: image.averageColor)
        self.thumbnailImagePlaceholderLabel.isHidden = true
      } catch {
        self.thumbnailImagePlaceholderLabel.isHidden = false
      }
    }
    
    onReuse = { [weak self] in
      self?.thumbnailImageView.kf.cancelDownloadTask()
    }
  }
}
