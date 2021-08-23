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
    
    var onReuse: () -> Void = {}
    
    override func awakeFromNib() {
        initView()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        onReuse()
        
        thumbnailImageView.image = nil
        titleLabel.text = ""
        descriptionLabel.text = ""
        indexLabel.text = ""
    }
    
    private func initView() {
        // selection View
        let selectionView = UIView(frame: self.frame)
        selectionView.layer.cornerRadius = 16
        selectionView.backgroundColor = ColorSet.cellSelectionColor
        self.selectedBackgroundView = selectionView
        
        // preview Image
        thumbnailImageView.layer.cornerRadius = 10
        thumbnailImageView.layer.masksToBounds = true
        thumbnailImageView.layer.borderWidth = 1
        thumbnailImageView.layer.borderColor = ColorSet.thumbnailBorderColor?.cgColor
    }
    
    func setWatched() {
        titleLabel.textColor = ColorSet.placeHolderTextColor
        descriptionLabel.textColor = ColorSet.placeHolderTextColor
        backgroundColor = ColorSet.cellSelectionColor
    }
    
    func setNotWatched() {
        titleLabel.textColor = ColorSet.textColor
        descriptionLabel.textColor = ColorSet.subTextColor
        backgroundColor = ColorSet.backgroundColor
    }
}
