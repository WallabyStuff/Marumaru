//
//  UpdateCycle.swift
//  Marumaru
//
//  Created by 이승기 on 2022/06/08.
//

import UIKit

enum UpdateCycle: String {
  case weekly = "주간"
  case biweekly = "격주"
  case monthly = "월간"
  case bimonthly = "격월"
  case singleEpisode = "단편"
  case book = "단행본"
  case monthlyOrIrregular = "격월/비정기"
  case concluded = "완결"
  case notClassified = "미분류"
  case other
}

extension UpdateCycle {
  var color: UIColor {
    switch self {
    case .weekly:
      return R.color.accentIndigo()!
    case .biweekly:
      return R.color.accentIndigo()!
    case .monthly:
      return R.color.accentTeal()!
    case .bimonthly:
      return R.color.accentTeal()!
    case .singleEpisode:
      return R.color.accentOrange()!
    case .book:
      return R.color.accentOrange()!
    case .monthlyOrIrregular:
      return R.color.accentTeal()!
    case .concluded:
      return R.color.accentGreen()!
    case .notClassified:
      return .systemGray2
    case .other:
      return R.color.accentOrange()!
    }
  }
}
