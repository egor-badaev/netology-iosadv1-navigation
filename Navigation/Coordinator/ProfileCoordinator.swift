//
//  ProfileCoordinator.swift
//  Navigation
//
//  Created by Egor Badaev on 08.02.2021.
//  Copyright © 2021 Egor Badaev. All rights reserved.
//

import UIKit

final class ProfileCoordinator: Coordinator {
    var childCoordinators: [Coordinator]
    var navigationController: UINavigationController
    
    init(navigationController: UINavigationController) {
        childCoordinators = []
        self.navigationController = navigationController
    }
        
    func start() {
        let profileTabBarIcon = UIImage(named: "Profile")
        let profileTabBarItem = UITabBarItem(title: "Profile", image: profileTabBarIcon, selectedImage: nil)
        navigationController.tabBarItem = profileTabBarItem
    }
    
    func login() {
        let profileViewController = ProfileViewController()
        profileViewController.coordinator = self
        navigationController.pushViewController(profileViewController, animated: true)
    }
    
    func showPhotos() {
        let photosViewController = PhotosViewController()
        navigationController.pushViewController(photosViewController, animated: true)
    }
    
    func logout(fromController controller: UIViewController) {
        AuthenticationManager.shared.logout { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure( _):
                self.showAlert(presentedOn: controller, title: "Ошибка", message: "Невозможно выполнить выход")
            case .success( _):
                self.navigationController.popToRootViewController(animated: true)
            }
        }
    }
}
