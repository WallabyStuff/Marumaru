//
//  SceneDelegate.swift
//  Marumaru
//
//  Created by 이승기 on 2021/04/06.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  
  
  // MARK: - Properties
  
  var window: UIWindow?
  
  
  // MARK: - LifeCycle
  
  func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    guard let windowScene = (scene as? UIWindowScene) else { return }
    
    window = UIWindow(windowScene: windowScene)
    window?.rootViewController = splashViewController()
    window?.makeKeyAndVisible()
  }
  
  private func splashViewController() -> SplashViewController {
    let viewModel = SplashViewModel()
    let viewController = SplashViewController(viewModel)
    return viewController
  }
}
