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
        
        updateBasePath()
        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = instantiateMainViewController()
        window?.makeKeyAndVisible()
    }
    
    
    // MARK: - Methods
    
    func instantiateMainViewController() -> UINavigationController {
        let tabBarController = MainTabBarController()
        let navigationController = UINavigationController(rootViewController: tabBarController)
        return navigationController
    }
    
    func updateBasePath() {
        let basePathManager = BasePathManager()
        basePathManager.replaceToValidBasePath()
    }
}
