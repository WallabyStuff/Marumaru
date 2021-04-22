//
//  MangaEpisodeCell.swift
//  Marumaru
//
//  Created by 이승기 on 2021/04/08.
//

import UIKit

class MangaEpisodeCell: UITableViewCell{
    
    @IBOutlet weak var previewImage: UIImageView!
    @IBOutlet weak var episodeTitleLabel: UILabel!
    @IBOutlet weak var episodeDescLabel: UILabel!
    @IBOutlet weak var episodeIndexLabel: UILabel!
    
    var onReuse: () -> Void = {}
    
    override func awakeFromNib() {
        previewImage.layer.cornerRadius = 10
        previewImage.layer.masksToBounds = true
        previewImage.layer.borderWidth = 1
        previewImage.layer.borderColor = UIColor(named: "PlaceHolderTextColor")?.cgColor
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        onReuse()
        
        // Initialization
        previewImage.image = nil
        episodeTitleLabel.text = ""
        episodeDescLabel.text = ""
        episodeIndexLabel.text = ""
    }
}
