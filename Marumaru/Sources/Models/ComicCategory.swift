//
//  ComicCategory.swift
//  Marumaru
//
//  Created by 이승기 on 2022/06/07.
//

import Foundation

enum ComicCategory: CaseIterable {
  case all
  case action
  case ordinaryLife
  case loveComedy
  case romance
  case isekai
  case pastLife
  case school
  case pure
  case harem
  case fantasy
  case mystery
  case scary
  case detective
  case horror
  case thriller
  case sports
  case game
  case music
  case gamble
  case drama
  case lightNovel
  case gag
  case cook
  case mukbang
  case era
  case animated
  case history
  case lily
  case seventeen
  case bl
  case gl
  case sf
  case ts
}

extension ComicCategory {
  var title: String {
    switch self {
    case .all:
      return "전체"
    case .action:
      return "액션"
    case .ordinaryLife:
      return "일상"
    case .loveComedy:
      return "러브코미디"
    case .romance:
      return "로맨스"
    case .isekai:
      return "이세계"
    case .pastLife:
      return "전생"
    case .school:
      return "학원"
    case .pure:
      return "순정"
    case .harem:
      return "하렘"
    case .fantasy:
      return "판타지"
    case .mystery:
      return "미스테리"
    case .scary:
      return "공포"
    case .detective:
      return "추리"
    case .horror:
      return "호러"
    case .thriller:
      return "스릴러"
    case .sports:
      return "스포츠"
    case .game:
      return "게임"
    case .music:
      return "음악"
    case .gamble:
      return "도박"
    case .drama:
      return "드라마"
    case .lightNovel:
      return "라노벨"
    case .gag:
      return "개그"
    case .cook:
      return "요리"
    case .mukbang:
      return "먹방"
    case .era:
      return "시대"
    case .animated:
      return "애니화"
    case .history:
      return "역사"
    case .lily:
      return "백합"
    case .seventeen:
      return "17"
    case .bl:
      return "BL"
    case .gl:
      return "GL"
    case .sf:
      return "SF"
    case .ts:
      return "TS"
    }
  }
}

extension ComicCategory {
  public func path(page: Int) -> String {
    if self == .all {
      return "\(idPrefix)\(pagePrefix)\(page)"
    } else {
      return "\(path)\(pagePrefix)\(page)"
    }
  }
  
  public var path: String {
    return "\(idPrefix)\(self.title)"
  }
}

extension ComicCategory {
  public var idPrefix: String {
    return "&name=&kind="
  }
  
  public var pagePrefix: String {
    return "&statu=&page="
  }
}
