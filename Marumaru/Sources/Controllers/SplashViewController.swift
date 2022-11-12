//
//  SplashViewController.swift
//  Marumaru
//
//  Created by 이승기 on 2022/07/10.
//

import UIKit

import RxSwift
import RxCocoa

class SplashViewController: BaseViewController, ViewModelInjectable {
  
  
  // MARK: - Properties
  
  typealias ViewModel = SplashViewModel
  var viewModel: ViewModel
  private let logoImageViewSize = CGSize(width: 144, height: 144)
  private var logoImageViewWidthConstraint = NSLayoutConstraint()
  private var logoImageViewHeightConstraint = NSLayoutConstraint()
  
  
  // MARK: - UI
  
  private var logoImageView: UIImageView = {
    let imageView = UIImageView()
    imageView.image = R.image.logo()
    return imageView
  }()
  
  
  // MARK: - Initializers
  
  required init(_ viewModel: SplashViewModel) {
    self.viewModel = viewModel
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(_ coder: NSCoder, _ viewModel: SplashViewModel) {
    fatalError("init(coder:) not been implemented")
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  
  // MARK: - LifeCycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setup()
    bind()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    startPreproccesses()
  }
  
  
  // MARK: - Setups
  
  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }
  
  private func setup() {
    setupView()
  }
  
  private func setupView() {
    view.backgroundColor = R.color.accentDarkGray()!
    setupLogoView()
  }
  
  private func setupLogoView() {
    view.addSubview(logoImageView)
    logoImageView.translatesAutoresizingMaskIntoConstraints = false
    logoImageViewWidthConstraint = logoImageView.widthAnchor.constraint(equalToConstant: 0)
    logoImageViewHeightConstraint = logoImageView.heightAnchor.constraint(equalToConstant: 0)
    
    NSLayoutConstraint.activate([
      logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      logoImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      logoImageViewWidthConstraint,
      logoImageViewHeightConstraint
    ])
  }
  
  
  // MARK: - Binds
  
  private func bind() {
    bindPreProcccesses()
    bindMessageAlert()
  }
  
  private func bindPreProcccesses() {
    Observable.combineLatest(viewModel.isFinishStartAnimation,
                             viewModel.isFinishPreProccess,
                             resultSelector: {
      return ($0 == true) && ($1 == true)
    })
    .subscribe(onNext: { [weak self] isPreProccessFinished in
      if isPreProccessFinished {
        self?.startDecreaseLogoAnimation(completion: { [weak self] in
          self?.presentMainTabbarViewController()
        })
      }
    })
    .disposed(by: disposeBag)
  }
  
  private func bindMessageAlert() {
    viewModel.showMessageAlert
      .bind(onNext: { [weak self] in
        self?.showMaintainingServerAlert()
      })
      .disposed(by: disposeBag)
  }
  
  
  // MARK: - Methods
  
  private func startPreproccesses() {
    startIncreaseLogoAnimation()
    viewModel.replaceBasePath()
  }
  
  private func presentMainTabbarViewController() {
    let tabBarController = MainTabBarController()
    let navigationController = UINavigationController(rootViewController: tabBarController)
    navigationController.modalPresentationStyle = .fullScreen
    present(navigationController, animated: false)
  }
  
  private func startIncreaseLogoAnimation() {
    UIView.animate(withDuration: 0.5,
                   delay: 0,
                   usingSpringWithDamping: 0.8,
                   initialSpringVelocity: 0.8,
                   options: [],
                   animations: {
      self.logoImageViewWidthConstraint.constant = self.logoImageViewSize.width
      self.logoImageViewHeightConstraint.constant = self.logoImageViewSize.height
      self.view.layoutIfNeeded()
    }, completion: { _ in
      self.viewModel.finishStartAnimation()
    })
  }
  
  private func startDecreaseLogoAnimation(completion: @escaping () -> Void) {
    UIView.animate(withDuration: 0.3,
                   delay: 0.2,
                   options: [],
                   animations: {
      self.logoImageViewWidthConstraint.constant = 0.5
      self.logoImageViewHeightConstraint.constant = 0.5
      self.view.layoutIfNeeded()
    }, completion: { isCompleted in
      if isCompleted {
        self.logoImageView.isHidden = true
        completion()
      }
    })
  }
  
  private func showMaintainingServerAlert() {
    let alert = UIAlertController(title: "앗..",
                                  message: "서버 점검중인가봄😧\n다음에 봐",
                                  preferredStyle: .alert)
    let exitAppAction = UIAlertAction(title: "앱 종료",
                                      style: .destructive,
                                      handler: { [weak self] _ in
      self?.exitApp()
    })
    alert.addAction(exitAppAction)
    self.present(alert, animated: true)
  }
  
  private func exitApp() {
    UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
      exit(0)
    }
  }
}
