//
//  PopOverComicEpisodeTableCell.swift
//  Marumaru
//
//  Created by 이승기 on 2021/05/08.
//

import UIKit

class PopOverComicEpisodeTableCell: UITableViewCell {
    
    
    // MARK: - Properties
    
    static let identifier = R.reuseIdentifier.popOverComicEpisodeTableCell.identifier
    @IBOutlet weak var episodeTitleLabel: UILabel!
    
    
    // MARK: - LifeCycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }
    
    override func prepareForReuse() {
        episodeTitleLabel.text = ""
    }
    
    
    // MARK: - Setups
    
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
    
    
    // MARK: - Methods
    
    func setHighlighted() {
        episodeTitleLabel.textColor = R.color.accentGreen()
        episodeTitleLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
    }
    
    func setUnHighlighted() {
        episodeTitleLabel.textColor = R.color.textBlack()
        episodeTitleLabel.font = UIFont.systemFont(ofSize: 17, weight: .regular)
    }
}
