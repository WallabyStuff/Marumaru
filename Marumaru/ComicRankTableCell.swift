//
//  ComicRankTableCell.swift
//  Marumaru
//
//  Created by 이승기 on 2022/02/02.
//

import UIKit

class ComicRankTableCell: UITableViewCell {

    
    // MARK: - Properties
    
    static let identifier = R.reuseIdentifier.comicRankTableCell.identifier
    
    @IBOutlet weak var cellContentView: UIView!
    @IBOutlet weak var rankLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    
    
    // MARK: - LifeCycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }
    
    
    // MARK: - Overrides
    
    override func prepareForReuse() {
        super.prepareForReuse()
        rankLabel.text = ""
        titleLabel.text = ""
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        if highlighted {
            cellContentView.backgroundColor = .systemGray3
        } else {
            cellContentView.backgroundColor = R.color.backgroundWhiteLighter()
        }
    }
    
    
    // MARK: - Setups
    
    private func setup() {
        setupView()
    }

    private func setupView() {
        selectionStyle = .none
        setupCellContentView()
        setupRankLabel()
        setupTitleLabel()
    }
    
    private func setupCellContentView() {
        cellContentView.layer.cornerRadius = 12
    }
    
    private func setupRankLabel() {
        rankLabel.text = ""
    }
    
    private func setupTitleLabel() {
        titleLabel.text = ""
    }
}
