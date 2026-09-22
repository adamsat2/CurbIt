//
//  SceneDelegate.swift
//  CurbIt
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: windowScene)
        
        let rootVC: UIViewController
        if AppPreferences.shared.isFirstLaunch {
            rootVC = RegistrationViewController()
        } else {
            rootVC = UINavigationController(rootViewController: DashboardViewController())
        }

        window.rootViewController = rootVC
        self.window = window
        window.makeKeyAndVisible()
        
        AppTheme.applyGlobalStyling()
    }
}

