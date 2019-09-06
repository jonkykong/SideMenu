//
//  PushCoordinator.swift
//  SideMenu
//
//  Created by Jon Kent on 9/4/19.
//

import UIKit

protocol CoordinatorModel {
    var animated: Bool { get }
    var fromViewController: UIViewController { get }
    var toViewController: UIViewController { get }
}

protocol Coordinator {
    associatedtype Model: CoordinatorModel

    init(config: Model)
    @discardableResult func start() -> Bool
}

internal final class SideMenuPushCoordinator: Coordinator {

    struct Model: CoordinatorModel {
        var allowPushOfSameClassTwice: Bool
        var alongsideTransition: (() -> Void)?
        var animated: Bool
        var fromViewController: UIViewController
        var pushStyle: SideMenuPushStyle
        var toViewController: UIViewController
    }

    private let config: Model

    init(config: Model) {
        self.config = config
    }

    @discardableResult func start() -> Bool {
        guard config.pushStyle != .subMenu,
            let fromNavigationController = config.fromViewController as? UINavigationController else {
                return false
        }
        let toViewController = config.toViewController
        let presentingViewController = fromNavigationController.presentingViewController
        let splitViewController = presentingViewController as? UISplitViewController
        let tabBarController = presentingViewController as? UITabBarController
        let potentialNavigationController = (splitViewController?.viewControllers.first ?? tabBarController?.selectedViewController) ?? presentingViewController
        guard let navigationController = potentialNavigationController as? UINavigationController else {
            Print.warning(.cannotPush, arguments: String(describing: potentialNavigationController.self), required: true)
            return false
        }

        // To avoid overlapping dismiss & pop/push calls, create a transaction block where the menu
        // is dismissed after showing the appropriate screen
        CATransaction.begin()
        defer { CATransaction.commit() }
        UIView.animationsEnabled { [weak self] in
            self?.config.alongsideTransition?()
        }

        if let lastViewController = navigationController.viewControllers.last,
            !config.allowPushOfSameClassTwice && type(of: lastViewController) == type(of: toViewController) {
            return false
        }

        toViewController.navigationItem.hidesBackButton = config.pushStyle.hidesBackButton

        switch config.pushStyle {

        case .default:
            navigationController.pushViewController(toViewController, animated: config.animated)
            return true

        // subMenu handled earlier
        case .subMenu:
            return false

        case .popWhenPossible:
            for subViewController in navigationController.viewControllers.reversed() {
                if type(of: subViewController) == type(of: toViewController) {
                    navigationController.popToViewController(subViewController, animated: config.animated)
                    return true
                }
            }
            navigationController.pushViewController(toViewController, animated: config.animated)
            return true

        case .preserve, .preserveAndHideBackButton:
            var viewControllers = navigationController.viewControllers
            let filtered = viewControllers.filter { preservedViewController in type(of: preservedViewController) == type(of: toViewController) }
            guard let preservedViewController = filtered.last else {
                navigationController.pushViewController(toViewController, animated: config.animated)
                return true
            }
            viewControllers = viewControllers.filter { subViewController in subViewController !== preservedViewController }
            viewControllers.append(preservedViewController)
            navigationController.setViewControllers(viewControllers, animated: config.animated)
            return true

        case .replace:
            navigationController.setViewControllers([toViewController], animated: config.animated)
            return true
        }
    }
}
