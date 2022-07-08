//
//  UserDefaultsManager.swift
//  Marumaru
//
//  Created by 이승기 on 2022/07/08.
//

import Foundation

enum MyUserDefault: String {
    case basePath
    
    func getValue() -> Any? {
        switch self {
        case .basePath:
            return UserDefaults.standard.string(forKey: self.rawValue) ?? nil
        }
    }
    
    func setValue(_ value: Any) {
        switch self {
        case .basePath:
            UserDefaults.standard.set(value, forKey: self.rawValue)
        }
    }
}
