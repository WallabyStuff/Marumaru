//
//  MangaSceneCell.swift
//  Marumaru
//
//  Created by 이승기 on 2021/04/08.
//

import UIKit

class SceneTableCell: UITableViewCell {
    
    var indexPath: IndexPath?
    var tableView: UITableView?
    
    @IBOutlet weak var sceneImageView: UIImageView!
    
    var onReuse: () -> Void = {}
    
    override class func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        onReuse()
        
        // set background tile
        let tileImage = UIImage(named: "Tile")!
        let patternBackground = UIColor(patternImage: tileImage)
        backgroundColor = patternBackground
        sceneImageView.image = UIImage()
    }
    
    func setImage(_ image: UIImage) {
        sceneImageView.image = image
        
        // proporiton of height
        let heightProportion = image.size.height / image.size.width
        print("Log ", heightProportion)
        self.frame.height
        frame.size.height = frame.width * heightProportion
    }
}
