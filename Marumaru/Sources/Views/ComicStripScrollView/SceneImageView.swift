//
//  SceneImageView.swift
//  Marumaru
//
//  Created by 이승기 on 2022/11/19.
//

import UIKit

import RxSwift
import RxCocoa
import RxGesture

class SceneImageView: UIImageView {
  
  // MARK: - Constants
  
  private struct Metric {
    static let reloadButtonSize: CGFloat = 48
    static let reloadButtonCornerRadius: CGFloat = 24
    static let reloadButtonImageEdgeInset: CGFloat = 12
  }
  
  
  // MARK: - Properties
  
  private var loadingState = true
  public var reloadButtonTapAction: () -> Void = {}
  public var imageViewTapAction: () -> Void = {}
  private var disposeBag = DisposeBag()
  
  // MARK: - UI
  
  public var reloadButton: UIButton = {
    let button = UIButton()
    button.backgroundColor = R.color.backgroundGrayStatic()
    button.tintColor = .white
    button.cornerRadius = Metric.reloadButtonCornerRadius
    button.setImage(R.image.reload(), for: .normal)
    button.imageEdgeInsets = .init(
      top: Metric.reloadButtonImageEdgeInset,
      left: Metric.reloadButtonImageEdgeInset,
      bottom: Metric.reloadButtonImageEdgeInset,
      right: Metric.reloadButtonImageEdgeInset)
    return button
  }()
  
  // MARK: - Initializers
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setup()
  }
  
  convenience init() {
    self.init(frame: .zero)
  }
  
  
  // MARK: - Setups
  
  private func setup() {
    setupView()
  }
  
  private func setupView() {
    setupReloadButton()
  }
  
  private func setupReloadButton() {
    addSubview(reloadButton)
    reloadButton.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      reloadButton.centerXAnchor.constraint(equalTo: centerXAnchor),
      reloadButton.centerYAnchor.constraint(equalTo: centerYAnchor),
      reloadButton.widthAnchor.constraint(equalToConstant: Metric.reloadButtonSize),
      reloadButton.heightAnchor.constraint(equalTo: reloadButton.widthAnchor)
    ])
    
    isUserInteractionEnabled = true
    reloadButton.rx.tap
      .asDriver()
      .drive(with: self, onNext: { strongSelf, _ in
        strongSelf.reloadButtonTapAction()
      })
      .disposed(by: disposeBag)
  }
  
  // MARK: - Methods
  
  public func startLoading() {
    backgroundColor = UIColor.tilePatternColor
    reloadButton.isHidden = true
  }
  
  public func stopLoading() {
    backgroundColor = .white
    reloadButton.isHidden = true
  }
  
  public func showReloadButton() {
    backgroundColor = UIColor.tilePatternColor
    reloadButton.isHidden = false
  }
}

// Override intrinsicContentSize to resize imageView height with appropriate proportion
extension SceneImageView {
  override var intrinsicContentSize: CGSize {
    guard let image = self.image else { return .init(width: -1.0, height: -1.0) }
    
    let imageWidth = image.size.width
    let imageHeight = image.size.height
    let viewWidth = frame.size.width
    
    let ratio = viewWidth / imageWidth
    let scaledHeight = imageHeight * ratio
    
    return .init(width: viewWidth, height: scaledHeight)
  }
}
