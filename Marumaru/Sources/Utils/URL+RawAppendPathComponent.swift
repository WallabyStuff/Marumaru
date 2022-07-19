//
//  URL+RawAppendPathComponent.swift
//  Marumaru
//
//  Created by 이승기 on 2022/06/07.
//

import Foundation

extension URL {
    // Prevent making wrong url path
    mutating
    func appendRawPathComponent(_ pathComponent: String) {
        var path = self.description
        path = "\(path)\(pathComponent)"
        self = URL(string: path) ?? self
    }
}
