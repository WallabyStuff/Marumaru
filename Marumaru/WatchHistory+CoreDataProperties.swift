//
//  WatchHistory+CoreDataProperties.swift
//  
//
//  Created by 이승기 on 2021/04/26.
//
//

import Foundation
import CoreData


extension WatchHistory {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<WatchHistory> {
        return NSFetchRequest<WatchHistory>(entityName: "WatchHistory")
    }

    @NSManaged public var link: String?
    @NSManaged public var preview_image: Data?
    @NSManaged public var preview_image_url: String?
    @NSManaged public var title: String?

}
