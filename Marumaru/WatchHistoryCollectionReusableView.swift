//
//  WatchHistoryCollectionReusableView.swift
//  Marumaru
//
//  Created by 이승기 on 2022/02/04.
//

import UIKit

class WatchHistoryCollectionReusableView: UICollectionReusableView {
    
    static let identifier = "watchHistoryCollectionReusableView"
    let contentView = UIView()
    let dateLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    override func layoutSubviews() {
        configureContentView()
    }
    
    // MARK: - Setups
    private func setup() {
        setupView()
        setupConstraints()
    }
    
    private func setupView() {
        setupContentView()
        setupDateLabel()
    }
    
    private func setupConstraints() {
        setupDateLabelConstraints()
    }
    
    // MARK: - Setup Views
    private func setupContentView() {
        configureContentView()
        contentView.backgroundColor = .clear
        addSubview(contentView)
    }
    
    private func configureContentView() {
        contentView.frame = bounds
    }

    private func setupDateLabel() {
        dateLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        dateLabel.textColor = R.color.textBlackLighter()
        contentView.addSubview(dateLabel)
    }
    
    // MARK: - Setup Constraints
    private func setupDateLabelConstraints() {
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20).isActive = true
        dateLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 20).isActive = true
        dateLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
    }
}
