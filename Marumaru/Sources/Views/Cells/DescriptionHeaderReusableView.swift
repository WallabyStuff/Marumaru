//
//  CollectionReusableView.swift
//  Marumaru
//
//  Created by 이승기 on 2022/05/31.
//

import UIKit

class DescriptionHeaderReusableView: UICollectionReusableView {
  
  
  // MARK: - Properties
  
  static let identifier = R.reuseIdentifier.descriptionHeaderReusableView.identifier
  
  
  // MARK: - UI
  
  @IBOutlet weak var descriptionLabel: UILabel!
  
  
  // MARK: - LifeCycle
  
  override func awakeFromNib() {
    super.awakeFromNib()
  }
}
