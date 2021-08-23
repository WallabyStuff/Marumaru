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
        
        initView()
    }
    
    func initView() {
        // episode title Label
        episodeTitleLabel.text = ""
        episodeTitleLabel.lineBreakMode = .byTruncatingMiddle
        episodeTitleLabel.textColor = ColorSet.textColor
        
        // contentView
        contentView.backgroundColor = ColorSet.transparentColor
        
        // selection View
        let selectionView = UIView(frame: self.frame)
        selectionView.backgroundColor = ColorSet.cellSelectionColor
        self.selectedBackgroundView = selectionView
    }
}
