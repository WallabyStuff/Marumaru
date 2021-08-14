//
//  ImageCache.swift
//  Marumaru
//
//  Created by 이승기 on 2021/08/13.
//

import UIKit
import RealmSwift

class ImageCache: Object {
    
    var image: UIImage {
        get { return UIImage(data: imageData) ?? UIImage() }
    }
    var averageColor: UIColor {
        get { return UIColor(hexString: imageAvgColorHex) }
    }
    
    // MARK: - Properties
    @objc dynamic var url: String               = ""
    @objc dynamic var imageData: Data           = Data()
    @objc dynamic var imageAvgColorHex: String     = ColorSet.shadowColor!.toHexString()
    
    // MARK: - Initializations
    convenience init(url: String,
                     image: UIImage,
                     imageAvgColor: UIColor) {
        self.init()

        self.url            = url
        self.imageData          = image.jpegData(compressionQuality: 1) ?? Data()
        self.imageAvgColorHex  = imageAvgColor.toHexString()
    }
    
    override class func primaryKey() -> String? {
        return "url"
    }
}
