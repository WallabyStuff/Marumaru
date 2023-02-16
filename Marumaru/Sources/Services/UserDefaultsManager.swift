//
//  UserDefaultsManager.swift
//  Marumaru
//
//  Created by 이승기 on 2022/07/08.
//

import Foundation

struct UserDefaultsManager {
    
  @UserDefault(key: "basePath", defaultValue: "https://marumaru643.com")
  static var basePath: String
}
