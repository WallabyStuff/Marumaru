//
//  Episode.swift
//  Marumaru
//
//  Created by 이승기 on 2021/05/08.
//

import UIKit

class Episode: NSObject {
    var title: String
    var serialNumber: String
    
    init(title: String, serialNumber: String) {
        self.title = title
        self.serialNumber = serialNumber
    }
}
