//
//  FlexibleSceneScrollViewCellModel.swift
//  Marumaru
//
//  Created by 이승기 on 2022/02/04.
//

import UIKit

class FlexibleSceneScrollViewCellModel: MarumaruApiServiceViewModel {
    public func getImageURL(_ imagePath: String) -> String {
        return MarumaruApiService.shared.getImageURL(imagePath)?.description ?? ""
    }
}
