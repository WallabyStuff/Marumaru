//
//  MangaEpisodePopoverCell.swift
//  Marumaru
//
//  Created by 이승기 on 2021/05/08.
//

import UIKit

class PopOverEpisodeCell: UITableViewCell {
    
    @IBOutlet weak var episodeTitleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }
    
    override func prepareForReuse() {
        episodeTitleLabel.text = ""
    }
    
    private func setup() {
        setupView()
    }
    
    private func setupView() {
        setupContentView()
        setupTitleLabel()
    }
    
    private func setupContentView() {
        contentView.backgroundColor = UIColor.clear
    }
    
    private func setupTitleLabel() {
        episodeTitleLabel.text = ""
        episodeTitleLabel.lineBreakMode = .byTruncatingMiddle
        episodeTitleLabel.textColor = R.color.textBlack()
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        if highlighted {
            contentView.backgroundColor = R.color.accentBlueLightest()
        } else {
            contentView.backgroundColor = R.color.backgroundWhite()
        }
    }
}
