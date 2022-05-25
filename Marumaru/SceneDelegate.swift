//
//  SceneDelegate.swift
//  Marumaru
//
//  Created by 이승기 on 2021/04/06.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = instantiateMainViewController()
        window?.makeKeyAndVisible()

        guard let _ = (scene as? UIWindowScene) else { return }
    }
    
    func instantiateMainViewController() -> UINavigationController {
        let tabBarController = MainTabBarController()
        let navigationController = UINavigationController(rootViewController: tabBarController)
        return navigationController
    }
}
