//
//  ComicThumbnailCollectionCell.swift
//  Marumaru
//
//  Created by 이승기 on 2021/04/06.
//

import UIKit

class ComicEpisodeThumbnailCollectionCell: UICollectionViewCell {
  
  
  // MARK: - Properties
  
  static let identifier = R.reuseIdentifier.comicEpisodeThumbnailCollectionCell.identifier
  public var onReuse: () -> Void = {}
  
  
  // MARK: - UI
  
  @IBOutlet weak var thumbnailImagePlaceholderView: ThumbnailPlaceholderView!
  @IBOutlet weak var thumbnailImageView: UIImageView!
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var thumbnailImagePlaceholderLabel: UILabel!
  
  
  // MARK: - LifeCycle
  
  override func awakeFromNib() {
    setup()
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()
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
  }
  
  private func setupContentView() {
    clipsToBounds = false
  }
  
  
  // MARK: - Methods
  
  public func configure(with episode: ComicEpisode) {
    self.hideSkeleton()
    thumbnailImagePlaceholderLabel.text = episode.title
    titleLabel.text = episode.title
    setThumbnailImage(episode.thumbnailImagePath)
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
