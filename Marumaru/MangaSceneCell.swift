//
//  MangaSceneCell.swift
//  Marumaru
//
//  Created by 이승기 on 2021/04/08.
//

import UIKit

class MangaSceneCell: UITableViewCell{
    
    @IBOutlet weak var sceneImageView: UIImageView!
    @IBOutlet weak var sceneDividerView: UIView!
    
    var onReuse: () -> Void = {}
    
    override func prepareForReuse() {
        super.prepareForReuse()
        onReuse()
        
        // Initialization
        sceneImageView.image = nil
    }
}
