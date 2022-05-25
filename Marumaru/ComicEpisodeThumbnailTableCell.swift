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
    
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var indexLabel: UILabel!
    
    var onReuse: () -> Void = {}
    
    
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
    }
    
    
    // MARK: - Setups
    
    private func setup() {
        setupContentView()
        setupView()
    }
    
    private func setupView() {
        setupThumbnailImageView()
    }
    
    private func setupContentView() {
        selectionStyle = .none
        selectedBackgroundView = UIView()
    }
    
    private func setupThumbnailImageView() {
        thumbnailImageView.layer.cornerRadius = 6
        thumbnailImageView.layer.masksToBounds = true
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
