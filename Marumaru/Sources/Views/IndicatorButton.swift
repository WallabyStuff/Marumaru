//
//  LoadingIndicatorButton.swift
//  Marumaru
//
//  Created by 이승기 on 2022/06/15.
//

import UIKit

class IndicatorButton: UIButton {
  
  
  // MARK: - Properties
  
  public var indicatorView = UIActivityIndicatorView()
  private var titleText = ""
  
  
  // MARK: - Initializers
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setup()
  }
  
  
  // MARK: - Setups
  
  private func setup() {
    setupView()
  }
  
  private func setupView() {
    setupLoadingIndicatorView()
  }
  
  private func setupLoadingIndicatorView() {
    indicatorView = UIActivityIndicatorView(style: .medium)
    
    addSubview(indicatorView)
    indicatorView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      indicatorView.centerXAnchor.constraint(equalTo: centerXAnchor),
      indicatorView.centerYAnchor.constraint(equalTo: centerYAnchor),
      indicatorView.widthAnchor.constraint(equalToConstant: 24),
      indicatorView.heightAnchor.constraint(equalToConstant: 24)
    ])
  }
  
  
  // MARK: - Methods
  
  public func startLoading() {
    indicatorView.startAnimating()
    indicatorView.isHidden = false
    titleText = titleLabel?.text ?? ""
    setTitle("", for: .normal)
  }
  
  public func stopLoading() {
    indicatorView.stopAnimating()
    indicatorView.isHidden = true
    setTitle(titleText, for: .normal)
  }
}
