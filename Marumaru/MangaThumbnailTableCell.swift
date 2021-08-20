//
//  ResultMangaCell.swift
//  Marumaru
//
//  Created by 이승기 on 2021/04/13.
//

import UIKit
import Hero

class MangaThumbnailTableCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var updateCycleLabel: UILabel!
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var thumbnailImageBaseView: UIView!
    @IBOutlet weak var thumbnailImagePlaceholderLabel: UILabel!
    
    var onReuse: () -> Void = {}
    
    override func awakeFromNib() {
        initView()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        onReuse()
        
        titleLabel.text = ""
        authorLabel.text = ""
        updateCycleLabel.text = ""
        thumbnailImagePlaceholderLabel.isHidden = false
        updateCycleLabel.removeRoundedBackground(foregroundColor: ColorSet.subTextColor!)
        
        thumbnailImageView.image = UIImage()
        thumbnailImagePlaceholderLabel.text = ""
        thumbnailImageBaseView.setThubmailShadow()
    }
    
    private func initView() {
        // enable hero
        self.hero.isEnabled = true
        
        // info content View
        self.hero.id = "infoContentView"
        
        // selection View
        let selectionView = UIView(frame: self.frame)
        selectionView.layer.cornerRadius = 20
        selectionView.backgroundColor = ColorSet.cellSelectionColor
        self.selectedBackgroundView = selectionView
        
        // preview ImageView
        thumbnailImageView.hero.id = "previewImage"
        thumbnailImageView.layer.cornerRadius = 10
        
        // previewImage base View
        thumbnailImageBaseView.layer.cornerRadius = 10
        thumbnailImageBaseView.layer.shadowColor = UIColor(named: "ShadowColor")!.cgColor
        thumbnailImageBaseView.layer.shadowOffset = .zero
        thumbnailImageBaseView.layer.shadowRadius = 7
        thumbnailImageBaseView.layer.shadowOpacity = 30
        thumbnailImageBaseView.layer.masksToBounds = false
        thumbnailImageBaseView.layer.borderWidth = 0
        thumbnailImageBaseView.layer.shouldRasterize = true
        
        // manga title Label
        titleLabel.hero.id = "mangaTitleLabel"
    }
    
    func setUpdateCycleLabelBackgroundTint() {
        updateCycleLabel.makeRoundedBackground(cornerRadius: 8,
                                               backgroundColor: ColorSet.labelEffectBackgroundColor!,
                                               foregroundColor: ColorSet.labelEffectForegroundColor!)
    }
}
