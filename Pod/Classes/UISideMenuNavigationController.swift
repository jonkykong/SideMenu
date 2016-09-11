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
    @IBInspectable open var leftSide:Bool = false {
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
    
    fileprivate func didSetSide() {
        if leftSide {
            SideMenuManager.menuLeftNavigationController = self
        } else {
            SideMenuManager.menuRightNavigationController = self
        }
    }
    
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // we had presented a view before, so lets dismiss ourselves as already acted upon
        if view.isHidden {
            SideMenuTransition.hideMenuComplete()
            dismiss(animated: false, completion: { () -> Void in
                self.view.isHidden = false
            })
        }
    }
    
    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // when presenting a view controller from the menu, the menu view gets moved into another transition view above our transition container
        // which can break the visual layout we had before. So, we move the menu view back to its original transition view to preserve it.
        if !isBeingDismissed {
            if let mainView = presentingViewController?.view {
                switch SideMenuManager.menuPresentMode {
                case .viewSlideOut, .viewSlideInOut:
                    mainView.superview?.insertSubview(view, belowSubview: mainView)
                case .menuSlideIn, .menuDissolveIn:
                    if let tapView = SideMenuTransition.tapView {
                        mainView.superview?.insertSubview(view, aboveSubview: tapView)
                    } else {
                        mainView.superview?.insertSubview(view, aboveSubview: mainView)
                    }
                }
            }
        }
    }
    
    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // we're presenting a view controller from the menu, so we need to hide the menu so it isn't  g when the presented view is dismissed.
        if !isBeingDismissed {
            view.isHidden = true
            SideMenuTransition.hideMenuStart()
        }
    }
    
    override open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        // don't bother resizing if the view isn't visible
        if view.isHidden {
            return
        }
        
        SideMenuTransition.statusBarView?.isHidden = true
        coordinator.animate(alongsideTransition: { (context) -> Void in
            SideMenuTransition.presentMenuStart(forSize: size)
            }) { (context) -> Void in
                SideMenuTransition.statusBarView?.isHidden = false
        }
    }
    
    override open func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let menuViewController: UINavigationController = SideMenuTransition.presentDirection == .left ? SideMenuManager.menuLeftNavigationController : SideMenuManager.menuRightNavigationController,
            let presentingViewController = menuViewController.presentingViewController as? UINavigationController {
                presentingViewController.prepare(for: segue, sender: sender)
        }
    }
    
    override open func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if let menuViewController: UINavigationController = SideMenuTransition.presentDirection == .left ? SideMenuManager.menuLeftNavigationController : SideMenuManager.menuRightNavigationController,
            let presentingViewController = menuViewController.presentingViewController as? UINavigationController {
                return presentingViewController.shouldPerformSegue(withIdentifier: identifier, sender: sender)
        }
        
        return super.shouldPerformSegue(withIdentifier: identifier, sender: sender)
    }
    
    override open func pushViewController(_ viewController: UIViewController, animated: Bool) {
        guard viewControllers.count > 0 else {
            // NOTE: pushViewController is called by init(rootViewController: UIViewController)
            // so we must perform the normal super method in this case.
            super.pushViewController(viewController, animated: true)
            return
        }
        
        guard let presentingViewController = presentingViewController as? UINavigationController else {
            present(viewController, animated: animated, completion: nil)
            print("SideMenu Warning: cannot push a ViewController from a ViewController without a NavigationController. It will be presented it instead.")
            return
        }
        
        // to avoid overlapping dismiss & pop/push calls, create a transaction block where the menu
        // is dismissed after showing the appropriate screen
        CATransaction.begin()
        CATransaction.setCompletionBlock( { () -> Void in
            self.dismiss(animated: true, completion: nil)
            self.visibleViewController?.viewWillAppear(false) // Hack: force selection to get cleared on UITableViewControllers when reappearing using custom transitions
        })
        
        UIView.animate(withDuration: SideMenuManager.menuAnimationDismissDuration, animations: { () -> Void in
            SideMenuTransition.hideMenuStart()
        })
        
        if SideMenuManager.menuAllowPopIfPossible {
            for subViewController in presentingViewController.viewControllers {
                if type(of: subViewController) == type(of: viewController) {
                    presentingViewController.popToViewController(subViewController, animated: animated)
                    CATransaction.commit()
                    return
                }
            }
        }
        if !SideMenuManager.menuAllowPushOfSameClassTwice {
            if type(of: presentingViewController.viewControllers.last) == type(of: viewController) {
                CATransaction.commit()
                return
            }
        }
        
        presentingViewController.pushViewController(viewController, animated: animated)
        CATransaction.commit()
    }
}


