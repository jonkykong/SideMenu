//
//  PushCoordinator.swift
//  SideMenu
//
//  Created by Jon Kent on 9/4/19.
//

import UIKit

protocol Coordinator {
    func start()
}

protocol CoordinatorModel {
    var animated: Bool { get }
    var fromViewController: UIViewController { get }
    var toViewController: UIViewController { get }
}

protocol PushCoordinator: Coordinator {
    associatedtype Model: CoordinatorModel

    init(config: Model)
}

internal final class SideMenuPushCoordinator: PushCoordinator {

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

    func start() {
        guard let fromNavigationController = config.fromViewController as? UINavigationController else { return }
        let toViewController = config.toViewController
        guard fromNavigationController.viewControllers.count > 0 else {
            // NOTE: pushViewController is called by init(rootViewController: UIViewController)
            // so we must perform the normal super method in this case
            return fromNavigationController.pushViewController(toViewController, animated: config.animated)
        }

        let presentingViewController = fromNavigationController.presentingViewController
        let splitViewController = presentingViewController as? UISplitViewController
        let tabBarController = presentingViewController as? UITabBarController
        let potentialNavigationController = (splitViewController?.viewControllers.first ?? tabBarController?.selectedViewController) ?? presentingViewController
        guard var navigationController = potentialNavigationController as? UINavigationController else {
            return Print.warning(.cannotPush, arguments: String(describing: potentialNavigationController.self), required: true)
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
            return
        }

        toViewController.navigationItem.hidesBackButton = config.pushStyle.hidesBackButton

        switch config.pushStyle {

        case .default:
            break

        case .subMenu:
            navigationController = fromNavigationController
            break

        case .popWhenPossible:
            for subViewController in navigationController.viewControllers.reversed() {
                if type(of: subViewController) == type(of: toViewController) {
                    navigationController.popToViewController(subViewController, animated: config.animated)
                    return
                }
            }

        case .preserve, .preserveAndHideBackButton:
            var viewControllers = navigationController.viewControllers
            let filtered = viewControllers.filter { preservedViewController in type(of: preservedViewController) == type(of: toViewController) }
            guard let preservedViewController = filtered.last else { break }
            viewControllers = viewControllers.filter { subViewController in subViewController !== preservedViewController }
            viewControllers.append(preservedViewController)
            return navigationController.setViewControllers(viewControllers, animated: config.animated)

        case .replace:
            return navigationController.setViewControllers([toViewController], animated: config.animated)
        }

        navigationController.pushViewController(toViewController, animated: config.animated)
    }
}
