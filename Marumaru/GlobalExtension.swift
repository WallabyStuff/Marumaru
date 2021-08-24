//
//  ModelGlobalExtension.swift
//  Marumaru
//
//  Created by 이승기 on 2021/08/23.
//

import UIKit

public extension Date {
    
    static var timeStamp: Int64 {
        Int64(Date().timeIntervalSince1970)
    }
}
