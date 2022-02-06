//
//  MangaRankTableViewCell.swift
//  Marumaru
//
//  Created by 이승기 on 2022/02/02.
//

import UIKit

class MangaRankTableViewCell: UITableViewCell {

    @IBOutlet weak var cellContentView: UIView!
    @IBOutlet weak var rankLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    
    static let identifier = "mangaRankTableCell"
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setup()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        rankLabel.text = ""
        titleLabel.text = ""
    }
    
    // MARK: - Setup
    private func setup() {
        setupView()
    }

    private func setupView() {
        selectionStyle = .none
        rankLabel.text = ""
        titleLabel.text = ""
        cellContentView.layer.cornerRadius = 12
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        if highlighted {
            cellContentView.backgroundColor = R.color.backgroundGrayLighter()
        } else {
            cellContentView.backgroundColor = R.color.backgroundGrayLightest()
        }
    }
}
