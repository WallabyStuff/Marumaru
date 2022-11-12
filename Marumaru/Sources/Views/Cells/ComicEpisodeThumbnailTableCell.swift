//
//  ComicEpisodeThumbnailTableCell.swift
//  Marumaru
//
//  Created by 이승기 on 2021/04/08.
//

import UIKit

class ComicEpisodeThumbnailTableCell: UITableViewCell {
  
  
  // MARK: - Properties
  
  static let identifier = R.reuseIdentifier.comicEpisodeThumbnailTableCell.identifier
  public var onReuse: () -> Void = { }
  
  
  // MARK: - UI
  
  @IBOutlet weak var thumbnailImageView: UIImageView!
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var authorLabel: UILabel!
  @IBOutlet weak var indexLabel: UILabel!
  @IBOutlet weak var recentWatchingIndicatorView: UIView!
  
  
  // MARK: - LifeCycle
  
  override func awakeFromNib() {
    setup()
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()
    onReuse()
    thumbnailImageView.image = nil
    titleLabel.text = ""
    authorLabel.text = ""
    indexLabel.text = ""
    recentWatchingIndicatorView.isHidden = true
    setUnWatched()
  }
  
  
  // MARK: - Setups
  
  private func setup() {
    setupContentView()
  }
  
  private func setupContentView() {
    selectionStyle = .none
    selectedBackgroundView = UIView()
  }
  
  
  // MARK: - Methods
  
  public func configure(with episode: ComicEpisode, index: Int) {
    hideSkeleton()
    
    titleLabel.text = episode.title
    authorLabel.text = episode.description
    indexLabel.text = index.description
    thumbnailImageView.image = nil
    setThumbnailImage(episode.thumbnailImagePath)
  }
  
  private func setThumbnailImage(_ imagePath: String?) {
    guard let imageURL = MarumaruApiService.shared.getImageURL(imagePath) else {
      return
    }
    
    thumbnailImageView.kf.setImage(with: imageURL, options: [.transition(.fade(0.3)), .forceTransition])
    
    onReuse = { [weak self] in
      self?.thumbnailImageView.kf.cancelDownloadTask()
    }
  }
}

extension ComicEpisodeThumbnailTableCell {
  func setWatched() {
    indexLabel.textColor = R.color.textBlackLighter()
    titleLabel.textColor = R.color.textBlackLighter()
    backgroundColor = R.color.backgroundWhiteLighter()
  }
  
  func setUnWatched() {
    indexLabel.textColor = R.color.textBlack()
    titleLabel.textColor = R.color.textBlack()
    backgroundColor = R.color.backgroundWhite()
  }
}
