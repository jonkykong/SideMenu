//
//  UISideMenuNavigationController.swift
//
//  Created by Jon Kent on 1/14/16.
//  Copyright © 2016 Jon Kent. All rights reserved.
//

import UIKit

open class UISideMenuNavigationController: UINavigationController {
    
    internal var originalMenuBackgroundColor: UIColor?
    
    open override func awakeFromNib() {
        super.awakeFromNib()
        
        // if this isn't set here, segues cause viewWillAppear and viewDidAppear to be called twice
        // likely because the transition completes and the presentingViewController is added back
        // into view for the default transition style.
        modalPresentationStyle = .overFullScreen
    }
    
    /// Whether the menu appears on the right or left side of the screen. Right is the default.
    @IBInspectable open var leftSide: Bool = false {
        didSet {
            if isViewLoaded && oldValue != leftSide { // suppress warnings
                didSetSide()
            }
        }
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        didSetSide()
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Dismiss keyboard to prevent weird keyboard animations from occurring during transition
        presentingViewController?.view.endEditing(true)
    }
    
    fileprivate func didSetSide() {
        if leftSide {
            SideMenuManager.menuLeftNavigationController = self
        } else {
            SideMenuManager.menuRightNavigationController = self
        }
    }
    
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // We had presented a view before, so lets dismiss ourselves as already acted upon
        if view.isHidden {
            SideMenuTransition.hideMenuComplete()
            dismiss(animated: false, completion: { () -> Void in
                self.view.isHidden = false
            })
        }
        
        if topViewController == nil {
            print("SideMenu Warning: the menu doesn't have a view controller to show! UISideMenuNavigationController needs a view controller to display just like a UINavigationController.")
        }
    }
    
    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // We're presenting a view controller from the menu, so we need to hide the menu so it isn't showing when the presented view is dismissed.
        if !isBeingDismissed {
            view.isHidden = true
            SideMenuTransition.hideMenuStart()
        }
    }
    
    override open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        // Don't bother resizing if the view isn't visible
        guard !view.isHidden else {
            return
        }
        
        NotificationCenter.default.removeObserver(SideMenuTransition.singleton, name: NSNotification.Name.UIApplicationWillChangeStatusBarFrame, object: nil)
        coordinator.animate(alongsideTransition: { (context) in
            SideMenuTransition.presentMenuStart()
        }) { (context) in
            NotificationCenter.default.addObserver(SideMenuTransition.singleton, selector:#selector(SideMenuTransition.handleNotification), name: NSNotification.Name.UIApplicationWillChangeStatusBarFrame, object: nil)
        }
    }
    
    override open func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let presentingViewController = presentingViewController {
            presentingViewController.prepare(for: segue, sender: sender)
        }
    }
    
    override open func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if let presentingViewController = presentingViewController {
            return presentingViewController.shouldPerformSegue(withIdentifier: identifier, sender: sender)
        }
        
        return super.shouldPerformSegue(withIdentifier: identifier, sender: sender)
    }
    
    override open func pushViewController(_ viewController: UIViewController, animated: Bool) {
        guard viewControllers.count > 0 && SideMenuManager.menuPushStyle != .subMenu else {
            // NOTE: pushViewController is called by init(rootViewController: UIViewController)
            // so we must perform the normal super method in this case.
            super.pushViewController(viewController, animated: animated)
            return
        }

        let tabBarController = presentingViewController as? UITabBarController
        guard let navigationController = (tabBarController?.selectedViewController ?? presentingViewController) as? UINavigationController else {
            print("SideMenu Warning: attempt to push a View Controller from \(String(describing: presentingViewController.self)) where its navigationController == nil. It must be embedded in a Navigation Controller for this to work.")
            return
        }
        
        // To avoid overlapping dismiss & pop/push calls, create a transaction block where the menu
        // is dismissed after showing the appropriate screen
        CATransaction.begin()
        CATransaction.setCompletionBlock( { () -> Void in
            self.dismiss(animated: true, completion: nil)
            self.visibleViewController?.viewWillAppear(false) // Hack: force selection to get cleared on UITableViewControllers when reappearing using custom transitions
        })
        
        let areAnimationsEnabled = UIView.areAnimationsEnabled
        UIView.setAnimationsEnabled(true)
        UIView.animate(withDuration: SideMenuManager.menuAnimationDismissDuration, animations: { () -> Void in
            SideMenuTransition.hideMenuStart()
        })
        UIView.setAnimationsEnabled(areAnimationsEnabled)
        
        if let lastViewController = navigationController.viewControllers.last, !SideMenuManager.menuAllowPushOfSameClassTwice && type(of: lastViewController) == type(of: viewController) {
            CATransaction.commit()
            return
        }
        
        switch SideMenuManager.menuPushStyle {
        case .subMenu, .defaultBehavior: break // .subMenu handled earlier, .defaultBehavior falls through to end
        case .popWhenPossible:
            for subViewController in navigationController.viewControllers.reversed() {
                if type(of: subViewController) == type(of: viewController) {
                    navigationController.popToViewController(subViewController, animated: animated)
                    CATransaction.commit()
                    return
                }
            }
        case .preserve, .preserveAndHideBackButton:
            var viewControllers = navigationController.viewControllers
            let filtered = viewControllers.filter { preservedViewController in type(of: preservedViewController) == type(of: viewController) }
            if let preservedViewController = filtered.last {
                viewControllers = viewControllers.filter { subViewController in subViewController !== preservedViewController }
                if SideMenuManager.menuPushStyle == .preserveAndHideBackButton {
                    preservedViewController.navigationItem.hidesBackButton = true
                }
                viewControllers.append(preservedViewController)
                navigationController.setViewControllers(viewControllers, animated: animated)
                CATransaction.commit()
                return
            }
            if SideMenuManager.menuPushStyle == .preserveAndHideBackButton {
                viewController.navigationItem.hidesBackButton = true
            }
        case .replace:
            viewController.navigationItem.hidesBackButton = true
            navigationController.setViewControllers([viewController], animated: animated)
            CATransaction.commit()
            return
        }
        
        navigationController.pushViewController(viewController, animated: animated)
        CATransaction.commit()
    }

}


