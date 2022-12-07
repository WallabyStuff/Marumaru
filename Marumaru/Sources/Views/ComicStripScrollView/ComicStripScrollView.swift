//
//  ComicStripScrollView2.swift
//  Marumaru
//
//  Created by 이승기 on 2022/11/13.
//

import UIKit

import Kingfisher
import RxSwift
import RxGesture

@objc
protocol ComicStripScrollViewDelegate {
  @objc optional func didReachTop()
  @objc optional func didReachBottom()
  @objc optional func didScrollBegan()
  @objc optional func didSingleTap()
  @objc optional func didDoubleTap()
}

class ComicStripScrollView: UIScrollView {
  
  // MARK: - Constants
  
  fileprivate struct Metric {
    static let estimatedWidthRatio: CGFloat = 9
    static let estimatedHeightRatio: CGFloat = 13
    
    static let maxZoomScale: CGFloat = 3
    static let minZoomScale: CGFloat = 1
    static let preferredZoomScale: CGFloat = 2
    
    static let sceneSpacing: CGFloat = 20
    static let overPanThreshold: CGFloat = 50
  }
  
  
  // MARK: - Properties
  
  private var disposeBag = DisposeBag()
  public weak var actionDelegate: ComicStripScrollViewDelegate?
  private var isZoomed = false
  private var estimatedSize: CGSize {
    let estimatedHeight = frame.width / Metric.estimatedWidthRatio * Metric.estimatedHeightRatio
    return .init(width: frame.width, height: estimatedHeight)
  }
  private var estimatedHeightConstraints = [NSLayoutConstraint]()
  private var sceneData = [ComicStripScene]()
  private var singleTapGestureRecognizer = UITapGestureRecognizer()
  private var doubleTapGestureRecognizer = UITapGestureRecognizer()
  
  
  // MARK: - UI
  
  private var scrollView: UIScrollView {
    return self
  }
  
  public var contentView: UIStackView {
    return stackView
  }
  
  private var stackView: UIStackView = {
    let stackView = UIStackView()
    stackView.backgroundColor = .white
    stackView.distribution = .fillProportionally
    stackView.axis = .vertical
    stackView.spacing = Metric.sceneSpacing
    stackView.alignment = .fill
    return stackView
  }()

  
  // MARK: - Initializers
  
  init(_ frame: CGRect) {
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
    bind()
  }
  
  private func setupView() {
    setupStackView()
    setupScrollView()
  }
  
  private func setupStackView() {
    scrollView.backgroundColor = R.color.backgroundWhite()
    scrollView.maximumZoomScale = Metric.maxZoomScale
    scrollView.minimumZoomScale = Metric.minZoomScale
    scrollView.bouncesZoom = true
    scrollView.addSubview(stackView)
    stackView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
      stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
      stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
      stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor)
    ])
  }
  
  private func setupScrollView() {
    scrollView.showsHorizontalScrollIndicator = false
    scrollView.showsVerticalScrollIndicator = true
    scrollView.delegate = self
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      scrollView.widthAnchor.constraint(equalTo: stackView.widthAnchor)
    ])
  }

  
  // MARK: - Binds
  
  private func bind() {
    bindOffset()
    bindGestures()
  }
  
  private func bindOffset() {
    scrollView.rx
      .contentOffset
      .bind(with: self, onNext: { strongSelf, offset in
        // Reached to the TOP
        if offset.y < -(Metric.overPanThreshold * 2) {
          strongSelf.actionDelegate?.didReachTop?()
        }
        
        // Reached to the BOTTOM
        if offset.y > strongSelf.scrollView.contentSize.height - strongSelf.frame.height + Metric.overPanThreshold + strongSelf.bottomInset {
          strongSelf.actionDelegate?.didReachBottom?()
        }
      })
      .disposed(by: disposeBag)
  }
  
  private func bindGestures() {
    bindPanGesture()
    bindSingleTapGesture()
    bindDoubleTapGesture()
  }
  
  private func bindPanGesture() {
    scrollView.rx
      .panGesture()
      .when(.began)
      .subscribe(with: self, onNext: { strongSelf, _ in
        strongSelf.actionDelegate?.didScrollBegan?()
      })
      .disposed(by: disposeBag)
  }
  
  private func bindSingleTapGesture() {
    singleTapGestureRecognizer.numberOfTapsRequired = 1
    singleTapGestureRecognizer.delegate = self
    scrollView.rx
      .gesture(singleTapGestureRecognizer)
      .when(.recognized)
      .bind(with: self, onNext: { strongSelf, _ in
        strongSelf.actionDelegate?.didSingleTap?()
      })
      .disposed(by: disposeBag)
  }
  
  private func bindDoubleTapGesture() {
    doubleTapGestureRecognizer.numberOfTapsRequired = 2
    doubleTapGestureRecognizer.delegate = self
    scrollView.addGestureRecognizer(doubleTapGestureRecognizer)
    scrollView.rx
      .gesture(doubleTapGestureRecognizer)
      .when(.recognized)
      .subscribe(with: self, onNext: { strongSelf, recognizer in
        let tapPoint = recognizer.location(in: strongSelf.contentView)
        strongSelf.autoZoom(tapPoint)
      })
      .disposed(by: disposeBag)
  }
  
  
  // MARK: - Methods
  
  public func configureScenes(data: [ComicStripScene]) {
    clearScene()
    
    for (index, scene) in data.enumerated() {
      let sceneImageView = SceneImageView()
      
      sceneImageView.reloadButton
        .rx.tap
        .asDriver()
        .drive(with: self, onNext: { strongSelf, _ in
          strongSelf.loadScene(index)
        })
        .disposed(by: disposeBag)
      
      let heightConstraint = sceneImageView.heightAnchor.constraint(equalToConstant: estimatedSize.height)
      estimatedHeightConstraints.append(heightConstraint)
      sceneData.append(scene)
      heightConstraint.isActive = true
      stackView.addArrangedSubview(sceneImageView)
    }
    
    // Initially call scrollViewDidScroll to request first scene Image
    notifyDidScroll()
  }
  
  private func loadScene(_ index: Int) {
    if index >= 0 && index < sceneData.count {
      guard let imageView = stackView.arrangedSubviews[index] as? SceneImageView else { return }
      let imagePath = sceneData[index].imagePath
      imageView.startLoading()
      
      let url = MarumaruApiService.shared.getImageURL(imagePath)
      imageView.kf.setImage(with: url, options: [.keepCurrentImageWhileLoading]) { [weak self] result in
        guard let resultImageView = self?.stackView.arrangedSubviews[index] as? SceneImageView else { return }
        switch result {
        case .success:
          // Disable estimated constraint
          self?.estimatedHeightConstraints[index].isActive = false
          resultImageView.stopLoading()
        case .failure:
          self?.estimatedHeightConstraints[index].isActive = true
          resultImageView.showReloadButton()
        }
      }
    }
  }
  
  public func clearScene() {
    sceneData.removeAll()
    estimatedHeightConstraints.removeAll()
    stackView.arrangedSubviews.forEach { subView in
      subView.removeFromSuperview()
    }
  }
  
  public func autoZoom(_ startPoint: CGPoint) {
    if isZoomed {
      zoomOut(startPoint)
    } else {
      zoomIn(startPoint)
    }
  }
  
  public func zoomIn(_ startPoint: CGPoint) {
    let zoomPosition = CGRect(x: startPoint.x,
                              y: startPoint.y,
                              width: frame.width / Metric.preferredZoomScale,
                              height: frame.height / Metric.preferredZoomScale)
    scrollView.zoom(to: zoomPosition, animated: true)
    isZoomed = true
  }
  
  public func zoomOut(_ startPoint: CGPoint) {
    let zoomPosition = CGRect(x: startPoint.x,
                              y: startPoint.y,
                              width: frame.width,
                              height: frame.height - scrollView.bounds.height)
    scrollView.zoom(to: zoomPosition, animated: true)
    isZoomed = false
  }
  
  public func enableScrollView() {
    scrollView.isUserInteractionEnabled = true
    scrollView.maximumZoomScale = 3
    scrollView.minimumZoomScale = 1
  }
  
  public func disableScrollView() {
    scrollView.isUserInteractionEnabled = false
    scrollView.maximumZoomScale = 1
    scrollView.minimumZoomScale = 1
  }
  
  public func startLoading() {
    disableScrollView()
    scrollView.playRandomCatLottie(yInset: -(scrollView.topInset + safeAreaInsets.top))
  }
  
  public func stopLoading() {
    enableScrollView()
    scrollView.stopLottie()
  }
  
  private func notifyDidScroll() {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      self.scrollView.delegate?.scrollViewDidScroll?(self.scrollView)
    }
  }
}

extension ComicStripScrollView: UIScrollViewDelegate {
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    let detectionLine = scrollView.contentOffset.y + scrollView.topInset + frame.height
    for (currentSceneNumber, view) in stackView.arrangedSubviews.enumerated() {
      if detectionLine > view.frame.origin.y && detectionLine < view.frame.origin.y + frame.height {
        loadScene(currentSceneNumber - 2)
        loadScene(currentSceneNumber - 1)
        loadScene(currentSceneNumber)
        loadScene(currentSceneNumber + 1)
        loadScene(currentSceneNumber + 2)
        break
      }
    }
  }
  
  func viewForZooming(in scrollView: UIScrollView) -> UIView? {
    return stackView
  }
}

// To prevent gesture recognizer conflict
extension ComicStripScrollView: UIGestureRecognizerDelegate {
  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    if gestureRecognizer == self.singleTapGestureRecognizer &&
        otherGestureRecognizer == self.doubleTapGestureRecognizer {
      return true
    }
    return false
  }
}
