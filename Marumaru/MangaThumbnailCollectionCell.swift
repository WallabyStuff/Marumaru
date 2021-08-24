//
//  UpdatedMangaCollectionCell.swift
//  Marumaru
//
//  Created by 이승기 on 2021/04/07.
//

import UIKit
import Hero

class MangaThumbnailCollectionCell: UICollectionViewCell {
    
    @IBOutlet weak var thumbnailImageBaseView: UIView!
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var thumbnailImagePlaceholderLabel: UILabel!
    
    var onReuse: () -> Void = {}
    
    override func awakeFromNib() {
        initView()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        onReuse()
        
        // Initialization
        thumbnailImageView.image = nil
        titleLabel.text = ""
        thumbnailImagePlaceholderLabel.text = ""
    }
    
    private func initView() {
        // hero enable
        self.hero.isEnabled = true
        
        // selection View
        let selectionView = UIView(frame: self.frame)
        selectionView.layer.cornerRadius = 16
        selectionView.backgroundColor = ColorSet.cellSelectionColor
        self.selectedBackgroundView = selectionView
        
        // preview ImageView
        thumbnailImageView.layer.cornerRadius = 10
        
        // previewImage base View
        thumbnailImageBaseView.layer.cornerRadius = 10
        thumbnailImageBaseView.setThubmailShadow()
    }
}
