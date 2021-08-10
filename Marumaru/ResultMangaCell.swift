//
//  ResultMangaCell.swift
//  Marumaru
//
//  Created by 이승기 on 2021/04/13.
//

import UIKit
import Hero

class ResultMangaCell: UITableViewCell{
    
    @IBOutlet weak var mangaTitleLabel: UILabel!
    @IBOutlet weak var desc1Label: UILabel!
    @IBOutlet weak var desc2Label: UILabel!
    @IBOutlet weak var previewImage: UIImageView!
    @IBOutlet weak var previewImageBaseView: UIView!
    @IBOutlet weak var previewImagePlaceholderLabel: UILabel!
    
    var onReuse: () -> Void = {}
    
    override func awakeFromNib() {
        initView()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        onReuse()
        
        // Initialization
        mangaTitleLabel.text = ""
        desc1Label.text = ""
        desc2Label.text = ""
        previewImage.image = nil
        previewImagePlaceholderLabel.text = ""
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
        previewImage.hero.id = "previewImage"
        previewImage.layer.cornerRadius = 10
        previewImageBaseView.layer.cornerRadius = 10
        
        // previewImage base View
        previewImageBaseView.layer.shadowColor = UIColor(named: "ShadowColor")!.cgColor
        previewImageBaseView.layer.shadowOffset = .zero
        previewImageBaseView.layer.shadowRadius = 7
        previewImageBaseView.layer.shadowOpacity = 30
        previewImageBaseView.layer.masksToBounds = false
        previewImageBaseView.layer.borderWidth = 0
        previewImageBaseView.layer.shouldRasterize = true
        
        // manga title Label
        mangaTitleLabel.hero.id = "mangaTitleLabel"
    }
}
