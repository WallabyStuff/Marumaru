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
    var blurView = UIVisualEffectView()
    
    
    // MARK: - LifeCycle
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        guard let _ = (scene as? UIWindowScene) else { return }
        
        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = instantiateMainViewController()
        window?.makeKeyAndVisible()
        
        setupBlurView()
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        showBlurView()
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        hideBlurView()
    }
    
    
    // MARK: - Setups
    
    func setupBlurView() {
        let effect = UIBlurEffect(style: .systemThinMaterial)
        blurView.effect = effect
    }
    
    
    // MARK: - Methods
    
    func instantiateMainViewController() -> UINavigationController {
        let tabBarController = MainTabBarController()
        let navigationController = UINavigationController(rootViewController: tabBarController)
        return navigationController
    }
    
    func showBlurView() {
        guard let window = window else {
            return
        }

        blurView.frame = window.frame
        window.addSubview(blurView)
        
        blurView.startFadeInAnimation(duration: 0.2)
    }
    
    func hideBlurView() {
        blurView.startFadeOutAnimation(duration: 0.2) { _ in
            self.blurView.removeFromSuperview()
        }
    }
}
