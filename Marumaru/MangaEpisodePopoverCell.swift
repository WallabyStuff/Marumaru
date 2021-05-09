//
//  MangaEpisodePopoverCell.swift
//  Marumaru
//
//  Created by 이승기 on 2021/05/08.
//

import UIKit

class MangaEpisodePopoverCell: UITableViewCell {

    
    @IBOutlet weak var episodeTitleLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        episodeTitleLabel.text = ""
        episodeTitleLabel.lineBreakMode = .byTruncatingMiddle
    }
}
