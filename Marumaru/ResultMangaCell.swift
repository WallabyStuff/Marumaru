//
//  ResultMangaCell.swift
//  Marumaru
//
//  Created by 이승기 on 2021/04/13.
//

import UIKit

class ResultMangaCell: UITableViewCell{
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var desc1Label: UILabel!
    @IBOutlet weak var desc2Label: UILabel!
    @IBOutlet weak var previewImage: UIImageView!
    @IBOutlet weak var previewImageBaseView: UIView!
    @IBOutlet weak var previewImagePlaceholderLabel: UILabel!
    
    var onReuse: () -> Void = {}
    
    override func awakeFromNib() {
        previewImage.layer.cornerRadius = 10
        previewImageBaseView.layer.cornerRadius = 10
        
        previewImageBaseView.layer.shadowColor = UIColor(named: "PointColor")!.cgColor
        previewImageBaseView.layer.shadowOffset = .zero
        previewImageBaseView.layer.shadowRadius = 3
        previewImageBaseView.layer.shadowOpacity = 30
        previewImageBaseView.layer.masksToBounds = false
        previewImageBaseView.layer.borderWidth = 0
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        onReuse()
        
        // Initialization
        titleLabel.text = ""
        desc1Label.text = ""
        desc2Label.text = ""
        previewImage.image = nil
        previewImagePlaceholderLabel.text = ""
    }
}
