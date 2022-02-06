//
//  MangaEpisodeCell.swift
//  Marumaru
//
//  Created by 이승기 on 2021/04/08.
//

import UIKit

class MangaEpisodeTableCell: UITableViewCell {
    
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var indexLabel: UILabel!
    
    static let identifier = "mangaEpisodeTableCell"
    var onReuse: () -> Void = {}
    
    override func awakeFromNib() {
        setupView()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        onReuse()
        
        thumbnailImageView.image = nil
        titleLabel.text = ""
        descriptionLabel.text = ""
        indexLabel.text = ""
    }
    
    private func setup() {
        setupView()
    }
    
    private func setupView() {
        setupThumbnailImageView()
        setupSelectedView()
    }
    
    private func setupThumbnailImageView() {
        thumbnailImageView.layer.cornerRadius = 8
        thumbnailImageView.layer.masksToBounds = true
        thumbnailImageView.layer.borderWidth = 1
        thumbnailImageView.layer.borderColor = R.color.lineGrayLighter()?.cgColor
    }
    
    private func setupSelectedView() {
        let selectionView = UIView(frame: self.frame)
        selectionView.layer.cornerRadius = 16
        selectionView.backgroundColor = R.color.accentBlueLightest()
        self.selectedBackgroundView = selectionView
    }
}

extension MangaEpisodeTableCell {
    func setWatched() {
        titleLabel.textColor = R.color.textBlackLightest()
        descriptionLabel.textColor = R.color.textBlackLightest()
        backgroundColor = R.color.accentBlueLightest()
    }
    
    func setUnWatched() {
        titleLabel.textColor = R.color.textBlack()
        descriptionLabel.textColor = R.color.textBlackLighter()
        backgroundColor = R.color.backgroundWhite()
    }
}
