//
//  CategoryThumbnailCollectionCell.swift
//  Marumaru
//
//  Created by 이승기 on 2022/06/07.
//

import UIKit

class ComicThumbnailCollectionCell: UICollectionViewCell {
  
  
  // MARK: - Properties
  
  static let identifier = R.reuseIdentifier.comicThumbnailCollectionCell.identifier
  public var onReuse: () -> Void = {}
  
  
  // MARK: - UI
  
  @IBOutlet weak var thumbnailImagePlaceholderView: ThumbnailPlaceholderView!
  @IBOutlet weak var thumbnailImagePlaceholderLabel: UILabel!
  @IBOutlet weak var thumbnailImageView: UIImageView!
  
  @IBOutlet weak var updateCycleView: UIVisualEffectView!
  @IBOutlet weak var updateCycleLabel: UILabel!
  
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var authorLabel: UILabel!
  
  
  // MARK: - LifeCycle
  
  override func awakeFromNib() {
    super.awakeFromNib()
    setup()
    setupView()
  }
  
  override func prepareForReuse() {
    onReuse()
    thumbnailImageView.image = nil
    thumbnailImagePlaceholderLabel.isHidden = false
    thumbnailImagePlaceholderView.removeThumbnailShadow()
  }
  
  
  // MARK: - Setups
  
  private func setup() {
    setupView()
  }
  
  private func setupView() {
    setupContentView()
    setupUpdateCycleView()
  }
  
  private func setupContentView() {
    clipsToBounds = false
  }
  
  private func setupUpdateCycleView() {
    updateCycleView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMinYCorner]
  }
  
  
  // MARK: - Methods
  
  public func configure(with comicInfo: ComicInfo) {
    hideSkeleton()
    titleLabel.text = comicInfo.title
    thumbnailImagePlaceholderLabel.text = comicInfo.title
    authorLabel.text = comicInfo.author
    setUpdateCycle(UpdateCycle(rawValue: comicInfo.updateCycle) ?? .notClassified)
    setThumbnailImage(comicInfo.thumbnailImagePath)
  }
  
  private func setThumbnailImage(_ imagePath: String?) {
    guard let imageURL = MarumaruApiService.shared.getImageURL(imagePath) else {
      return
    }
    
    thumbnailImageView.kf.setImage(with: imageURL, options: [.transition(.fade(0.3)), .forceTransition]) { [weak self] result in
      guard let self = self else { return }
      
      do {
        let result = try result.get()
        let image = result.image
        
        self.thumbnailImagePlaceholderLabel.isHidden = true
        self.thumbnailImagePlaceholderView.makeThumbnailShadow(with: image.averageColor)
      } catch {
        self.thumbnailImagePlaceholderLabel.isHidden = false
      }
    }
    
    onReuse = { [weak self] in
      self?.thumbnailImageView.kf.cancelDownloadTask()
    }
  }
  
  private func setUpdateCycle(_ updateCycle: UpdateCycle) {
    if updateCycle == .notClassified {
      updateCycleView.isHidden = true
      updateCycleLabel.text = ""
    } else {
      updateCycleView.isHidden = false
      updateCycleLabel.text = updateCycle.rawValue
    }
  }
}
