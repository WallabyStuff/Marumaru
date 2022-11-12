//
//  AppbarView.swift
//  Marumaru
//
//  Created by 이승기 on 2022/08/08.
//

import UIKit

class NavigationView: UIView {
  
  struct Appearance {
    var backgroundColor: UIColor? = R.color.backgroundWhite()
    var borderColor: UIColor? = .systemGray6
  }
  
  
  // MARK: - Properties
  
  static let BORDER_ANIMATION_THRESHOLD: CGFloat = 28
  
  var appearance: Appearance = Appearance() {
    didSet {
      backgroundColor = appearance.backgroundColor
      border.backgroundColor = appearance.borderColor
    }
  }
  private var border = UIView()
  private var scrollViewContentOffsetObserver: NSKeyValueObservation?
  
  
  // MARK: - Initializers
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    setupView()
  }
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupView()
  }
  
  
  // MARK: - Setups
  
  private func setupView() {
    setupBaseView()
    setupBorder()
  }
  
  private func setupBaseView() {
    self.backgroundColor = appearance.backgroundColor
  }
  
  private func setupBorder() {
    border.backgroundColor = appearance.borderColor
    self.addSubview(border)
    border.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      border.leadingAnchor.constraint(equalTo: self.leadingAnchor),
      border.trailingAnchor.constraint(equalTo: self.trailingAnchor),
      border.bottomAnchor.constraint(equalTo: self.bottomAnchor),
      border.heightAnchor.constraint(equalToConstant: 1)
    ])
  }
  
  
  // MARK: - Configurations
  
  func configureScrollEdgeAppearance<T>(_ scrollView: T? = nil) where T: UIScrollView {
    let targetScrollView: UIScrollView?
    if scrollView != nil {
      targetScrollView = scrollView
    } else {
      targetScrollView = self.targetScrollView
    }
    
    scrollViewContentOffsetObserver = targetScrollView?.observe(\.contentOffset, options: [.new]) { [weak self] _, change in
      guard let position = change.newValue else {
        return
      }
      
      let alpha = position.y / Self.BORDER_ANIMATION_THRESHOLD
      self?.border.alpha = alpha
    }
  }
  
  
  // MARK: - Methods
  
  private var targetScrollView: UIScrollView? {
    guard let superView = superview else {
      return nil
    }
    
    for view in superView.subviews {
      if let scrollView = view as? UIScrollView {
        return scrollView
      }
    }
    
    return nil
  }
}
