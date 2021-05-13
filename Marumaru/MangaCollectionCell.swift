//
//  UpdatedMangaCollectionCell.swift
//  Marumaru
//
//  Created by 이승기 on 2021/04/07.
//

import UIKit

class MangaCollectionCell: UICollectionViewCell{
    
    @IBOutlet weak var previewImageBaseView: UIView!
    @IBOutlet weak var previewImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var previewImagePlaceholderLabel: UILabel!
    
    var onReuse: () -> Void = {}
    
    override func awakeFromNib() {
        previewImage.layer.cornerRadius = 10
        previewImageBaseView.layer.cornerRadius = 10
        
        previewImageBaseView.layer.shadowColor = UIColor(named: "ShadowColor")!.cgColor
        previewImageBaseView.layer.shadowOffset = .zero
        previewImageBaseView.layer.shadowRadius = 6
        previewImageBaseView.layer.shadowOpacity = 30
        previewImageBaseView.layer.masksToBounds = false
        previewImageBaseView.layer.borderWidth = 0
        previewImageBaseView.layer.shouldRasterize = true
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        onReuse()
        
        // Initialization
        previewImage.image = nil
        titleLabel.text = ""
        previewImagePlaceholderLabel.text = ""
    }
}
