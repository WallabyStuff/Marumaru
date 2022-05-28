//
//  Array+IsInBound.swift
//  Marumaru
//
//  Created by 이승기 on 2022/05/28.
//

import Foundation

extension Array {
    func isInBound(_ index: Int) -> Bool {
        if (!self.isEmpty) && (index >= 0) && (self.count < index) {
            return true
        } else {
            return false
        }
    }
}
