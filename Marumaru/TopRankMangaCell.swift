//
//  TopRankMangaCell.swift
//  Marumaru
//
//  Created by 이승기 on 2021/04/07.
//

import UIKit

class TopRankMangaCell: UITableViewCell {
    
    @IBOutlet weak var innerView: UIView!
    @IBOutlet weak var rankLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    
    override func awakeFromNib() {
        innerView.layer.cornerRadius = 10
    }
}
