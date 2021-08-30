//
//  ModelGlobalExtension.swift
//  Marumaru
//
//  Created by 이승기 on 2021/08/23.
//

import UIKit
import RealmSwift

public extension Date {
    
    static var timeStamp: Int64 {
        Int64(Date().timeIntervalSince1970)
    }
    
    static var milliTimeStamp: Int64 {
        Int64(Date().timeIntervalSince1970 * 1000)
    }
}

extension Realm {
    /// prevent write while writing
    public func safeWrite(_ block: (() throws -> Void)) throws {
        if isInWriteTransaction {
            try block()
        } else {
            try write(block)
        }
    }
}
