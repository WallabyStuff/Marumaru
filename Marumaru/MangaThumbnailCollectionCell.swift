//
//  ViewController.swift
//  Marumaru
//
//  Created by 이승기 on 2021/04/06.
//

import UIKit
import Hero

class MangaThumbnailCollectionCell: UICollectionViewCell {
    
    @IBOutlet weak var thumbnailImageBaseView: ThumbnailView!
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var thumbnailImagePlaceholderLabel: UILabel!
    
    static let identifier = "mangaThumbnailCell"
    public var onReuse: () -> Void = {}
    
    override func awakeFromNib() {
        setup()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        onReuse()
        
        thumbnailImageView.image = nil
        titleLabel.text = ""
        thumbnailImagePlaceholderLabel.text = ""
    }
    
    private func setup() {
        setupView()
    }
    
    private func setupView() {
        setupHero()
        setupContentView()
        setupThumbnailImageView()
        setupThumbnailImageBaseView()
        setupSelectedView()
    }
    
    private func setupHero() {
        self.hero.isEnabled = true
    }
    
    private func setupContentView() {
        clipsToBounds = false
    }
    
    private func setupThumbnailImageView() {
        thumbnailImageView.layer.cornerRadius = 8
        thumbnailImageView.clipsToBounds = true
    }
    
    private func setupThumbnailImageBaseView() {
        thumbnailImageBaseView.layer.cornerRadius = 8
        thumbnailImageBaseView.setThubmailShadow()
    }
    
    private func setupSelectedView() {
        let selectionView = UIView(frame: self.frame)
        selectionView.layer.cornerRadius = 16
        selectionView.backgroundColor = R.color.accentBlueLightest()
        self.selectedBackgroundView = selectionView
    }
}
