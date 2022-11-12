//
//  ComicRankTableCell.swift
//  Marumaru
//
//  Created by 이승기 on 2022/02/02.
//

import UIKit

class ComicRankTableCell: UITableViewCell {
  
  
  // MARK: - Properties
  
  static let identifier = R.reuseIdentifier.comicRankTableCell.identifier
  
  
  // MARK: - UI
  
  @IBOutlet weak var cellContentView: UIView!
  @IBOutlet weak var rankLabel: UILabel!
  @IBOutlet weak var titleLabel: UILabel!
  
  
  // MARK: - LifeCycle
  
  override func awakeFromNib() {
    super.awakeFromNib()
    setup()
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()
    rankLabel.text = ""
    titleLabel.text = ""
  }
  
  
  // MARK: - Overrides
  
  override func setHighlighted(_ highlighted: Bool, animated: Bool) {
    if highlighted {
      cellContentView.backgroundColor = .systemGray3
    } else {
      cellContentView.backgroundColor = R.color.backgroundWhiteLighter()
    }
  }
  
  
  // MARK: - Setups
  
  private func setup() {
    setupView()
  }
  
  private func setupView() {
    selectionStyle = .none
    setupRankLabel()
    setupTitleLabel()
  }
  
  private func setupRankLabel() {
    rankLabel.text = ""
  }
  
  private func setupTitleLabel() {
    titleLabel.text = ""
  }
  
  
  // MARK: - Methods
  
  public func configure(with episode: ComicEpisode, rank: Int) {
    hideSkeleton()
    titleLabel.text = episode.title
    rankLabel.text = rank.description
  }
}
