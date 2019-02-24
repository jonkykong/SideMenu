//
//  SideMenuAnimationController.swift
//  SideMenu
//
//  Created by Jon Kent on 10/24/18.
//

import UIKit

internal protocol SideMenuTransitionControllerDelegate: class {
    func sideMenuTransitionController(_ transitionController: SideMenuTransitionController, animationEnded transitionCompleted: Bool)
}

internal class SideMenuTransitionController: NSObject, UIViewControllerAnimatedTransitioning {

    internal weak var tapView: UIView?
    internal var interactive: Bool = false
    internal var options: Menu.Options
    internal var delegate: SideMenuTransitionControllerDelegate?
    internal lazy var interactionController: SideMenuInteractionController? = {
        guard interactive else { return nil }
        return SideMenuInteractionController(completionCurve: options.completionCurve)
    }()

    private(set) var presenting: Bool = true
    private var transitioning = false
    private weak var containerView: UIView?
    private var presentationController: SideMenuPresentationController!

    init(options: Menu.Options) {
        self.options = options
    }

    deinit {
        guard !presenting else { return }
        fatalError("TEMPORARY: Transition controller destroyed without reversing presentation!")
    }

    open func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard
            let toViewController = transitionContext.viewController(forKey: .to),
            let fromViewController = transitionContext.viewController(forKey: .from),
            let menu = (toViewController as? Menu) ?? (fromViewController as? Menu)
            else { return }

        menu.sideMenuManagerDelegate = self
        options = menu.options
        let presentingViewController = menu == toViewController ? fromViewController : toViewController
        containerView = transitionContext.containerView

        if presenting {
            presentationController = SideMenuPresentationController(style: options.presentStyle,
                                                                    presented: menu,
                                                                    presenting: presentingViewController,
                                                                    containerView: transitionContext.containerView,
                                                                    presentingUserInteractionEnabled: options.presentingViewControllerUserInteractionEnabled,
                                                                    presentingViewControllerUseSnapshot: options.presentingViewControllerUseSnapshot)
        }

        transition(using: transitionContext)
    }

    open func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }

    open func animationEnded(_ transitionCompleted: Bool) {
        transitioning = false
        interactive = false
        delegate?.sideMenuTransitionController(self, animationEnded: transitionCompleted)
        if transitionCompleted {
            presenting = !presenting
        }
    }
}

extension SideMenuTransitionController: UISideMenuNavigationControllerManagerDelegate {

    internal func sideMenuWillAppear(menu: Menu, animated: Bool) -> Bool {
        // Dismiss keyboard to prevent weird keyboard animations from occurring during transition
        menu.presentingViewController?.view.endEditing(true)
        return true
    }

    internal func sideMenuDidAppear(menu: Menu, animated: Bool) -> Bool {
        // We had presented a view before, so lets dismiss ourselves as already acted upon
        if menu.view.isHidden {
            presentationController.dismissalTransitionDidEnd(true)
            presenting = true
            menu.dismiss(animated: false, completion: {
                menu.view.isHidden = false
            })
        } else if menu.topViewController == nil {
            Print.warning(.emptyMenu)
        }

        return true
    }

    internal func sideMenuWillDisappear(menu: Menu, animated: Bool) -> Bool {
        // When presenting a view controller from the menu, the menu view gets moved into another transition view above our transition container
        // which can break the visual layout we had before. So, we move the menu view back to its original transition view to preserve it.
        if menu.dismissOnPresent && !menu.isBeingDismissed  {
            // We're presenting a view controller from the menu, so we need to hide the menu so it isn't showing when the presented view is dismissed.
            if let presentingView = menu.presentingViewController?.view, let containerView = presentingView.superview {
                containerView.addSubview(menu.view)
            }

            animate(animated: animated, animations: { [weak self] in
                self?.presentationController.dismissalTransition()
                menu.activeDelegate?.sideMenuWillDisappear?(menu: menu, animated: animated)
            }) { completed in
                menu.activeDelegate?.sideMenuDidDisappear?(menu: menu, animated: animated)
                menu.view.isHidden = true
            }
            return true
        }

        return true
    }

    internal func sideMenuDidDisappear(menu: Menu, animated: Bool) -> Bool {
        // Work-around: if the menu is dismissed without animation the transition logic is never called to restore the
        // the view hierarchy leaving the screen black/empty. This is because the transition moves views within a container
        // view, but dismissing without animation removes the container view before the original hierarchy is restored.
        // This check corrects that.
        if let activeDelegate = menu.activeDelegate as? UIViewController, activeDelegate.view.window == nil {
            presentationController?.dismissalTransition()
        }

        // Clear selecton on UITableViewControllers when reappearing using custom transitions
        if let tableViewController = menu.topViewController as? UITableViewController,
            let tableView = tableViewController.tableView,
            let indexPaths = tableView.indexPathsForSelectedRows,
            tableViewController.clearsSelectionOnViewWillAppear {
            indexPaths.forEach { tableView.deselectRow(at: $0, animated: false) }
        }

        return true
    }

    internal func sideMenuShouldPushViewController(menu: Menu, viewController: UIViewController, animated: Bool, completion: ((Bool) -> Void)?) -> Bool {
        guard menu.viewControllers.count > 0 && menu.pushStyle != .subMenu else {
            // NOTE: pushViewController is called by init(rootViewController: UIViewController)
            // so we must perform the normal super method in this case
            return true
        }

        let splitViewController = menu.presentingViewController as? UISplitViewController
        let tabBarController = menu.presentingViewController as? UITabBarController
        let potentialNavigationController = (splitViewController?.viewControllers.first ?? tabBarController?.selectedViewController) ?? menu.presentingViewController
        guard let navigationController = potentialNavigationController as? UINavigationController else {
            Print.warning(.cannotPush, arguments: String(describing: potentialNavigationController.self), required: true)
            return false
        }

        // To avoid overlapping dismiss & pop/push calls, create a transaction block where the menu
        // is dismissed after showing the appropriate screen
        CATransaction.begin()
        defer { CATransaction.commit() }
        var push = false

        if menu.dismissOnPush {
            let animated = animated || menu.alwaysAnimate

            CATransaction.setCompletionBlock { [weak self] in
                menu.activeDelegate?.sideMenuDidDisappear?(menu: menu, animated: animated)
                self?.presenting = true
                menu.dismiss(animated: false, completion: nil)
                completion?(push)
            }

            if animated {
                let areAnimationsEnabled = UIView.areAnimationsEnabled
                UIView.setAnimationsEnabled(true)
                transition(animated: animated, alongsideTransition: {
                    menu.activeDelegate?.sideMenuWillDisappear?(menu: menu, animated: animated)
                })
                UIView.setAnimationsEnabled(areAnimationsEnabled)
            }
        }

        if let lastViewController = navigationController.viewControllers.last,
            !menu.allowPushOfSameClassTwice && type(of: lastViewController) == type(of: viewController) {
            return false
        }

        switch menu.pushStyle {
        case .subMenu: return false // handled earlier
        case .defaultBehavior:
            navigationController.pushViewController(viewController, animated: animated)
            return false
        case .popWhenPossible:
            for subViewController in navigationController.viewControllers.reversed() {
                if type(of: subViewController) == type(of: viewController) {
                    navigationController.popToViewController(subViewController, animated: animated)
                    return false
                }
            }
            push = true
            return true
        case .preserve, .preserveAndHideBackButton:
            var viewControllers = navigationController.viewControllers
            let filtered = viewControllers.filter { preservedViewController in type(of: preservedViewController) == type(of: viewController) }
            if let preservedViewController = filtered.last {
                viewControllers = viewControllers.filter { subViewController in subViewController !== preservedViewController }
                if menu.pushStyle == .preserveAndHideBackButton {
                    preservedViewController.navigationItem.hidesBackButton = true
                }
                viewControllers.append(preservedViewController)
                navigationController.setViewControllers(viewControllers, animated: animated)
                return false
            }
            if menu.pushStyle == .preserveAndHideBackButton {
                viewController.navigationItem.hidesBackButton = true
            }

            push = true
            return true
        case .replace:
            viewController.navigationItem.hidesBackButton = true
            navigationController.setViewControllers([viewController], animated: animated)
            return false
        }
    }

    internal func sideMenuWillTransition(menu: Menu, to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        // Don't bother resizing if the view isn't visible
        guard let presentationController = presentationController, !menu.view.isHidden else { return }

        coordinator.animate(alongsideTransition: { (context) in
            presentationController.presentationTransition()
        }, completion: nil)
    }
}

private extension SideMenuTransitionController {

    var duration: Double {
        if interactive { return options.completeGestureDuration }
        return presenting ? options.presentDuration : options.dismissDuration
    }

    func transition(animated: Bool = true, alongsideTransition: (() -> Void)? = nil, completion: ((Bool) -> Void)? = nil, using transitionContext: UIViewControllerContextTransitioning? = nil) {
        let presentationController: SideMenuPresentationController! = self.presentationController
        let presenting = self.presenting

        transitioning = true

        // prevent any other menu gestures from firing
        containerView?.isUserInteractionEnabled = false

        if presenting {
            presentationController.presentationTransitionWillBegin()
        } else {
            presentationController.dismissalTransitionWillBegin()
        }

        let animations = {
            if presenting {
                presentationController.presentationTransition()
            } else {
                presentationController.dismissalTransition()
            }
            alongsideTransition?()
        }

        let completion: (Bool) -> Void = { [weak self] _ in
            self?.containerView?.isUserInteractionEnabled = true
            let completed = !(transitionContext?.transitionWasCancelled ?? false)
            if presenting {
                presentationController.presentationTransitionDidEnd(completed)
                self?.tapView = presentationController.tapView
            } else {
                presentationController.dismissalTransitionDidEnd(completed)
            }
            completion?(completed)
            transitionContext?.completeTransition(completed)
        }

        animate(animated: animated, animations: animations, completion: completion)
    }

    func animate(animated: Bool = true, animations: @escaping () -> Void, completion: ((Bool) -> Void)? = nil) {
        if interactive {
            // IMPORTANT: The non-interactive animation block will not complete if adapted for interactive. The below animation block must be used!
            UIView.animate(
                withDuration: self.duration,
                delay: self.duration, // HACK: If zero, the animation briefly flashes in iOS 11.
                options: .curveLinear,
                animations: animations,
                completion: completion
            )
        } else {
            let duration = animated ? self.duration : 0
            UIView.animate(
                withDuration: duration,
                delay: 0,
                usingSpringWithDamping: options.usingSpringWithDamping,
                initialSpringVelocity: options.initialSpringVelocity,
                options: options.animationOptions,
                animations: animations,
                completion: completion
            )
        }
    }
}
