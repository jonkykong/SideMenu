//
//  UISideMenuNavigationController.swift
//
//  Created by Jon Kent on 1/14/16.
//  Copyright © 2016 Jon Kent. All rights reserved.
//

import UIKit

public class UISideMenuNavigationController: UINavigationController {
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        
        // if this isn't set here, segues cause viewWillAppear and viewDidAppear to be called twice
        // likely because the transition completes and the presentingViewController is added back
        // into view for the default transition style.
        modalPresentationStyle = .OverFullScreen
    }
    
    /// Whether the menu appears on the right or left side of the screen. Right is the default.
    @IBInspectable public var leftSide:Bool = false {
        didSet {
            if isViewLoaded() { // suppress warnings
                didSetSide()
            }
        }
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        didSetSide()
    }
    
    private func didSetSide() {
        if leftSide {
            SideMenuManager.menuLeftNavigationController = self
        } else {
            SideMenuManager.menuRightNavigationController = self
        }
    }
    
    override public func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // we had presented a view before, so lets dismiss ourselves as already acted upon
        if view.hidden {
            SideMenuTransition.hideMenuComplete()
            dismissViewControllerAnimated(false, completion: { () -> Void in
                self.view.hidden = false
            })
        }
    }
    
    override public func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        // when presenting a view controller from the menu, the menu view gets moved into another transition view above our transition container
        // which can break the visual layout we had before. So, we move the menu view back to its original transition view to preserve it.
        if !isBeingDismissed() {
            if let mainView = presentingViewController?.view {
                switch SideMenuManager.menuPresentMode {
                case .ViewSlideOut, .ViewSlideInOut:
                    mainView.superview?.insertSubview(view, belowSubview: mainView)
                case .MenuSlideIn, .MenuDissolveIn:
                    mainView.superview?.insertSubview(view, aboveSubview: SideMenuTransition.tapView)
                }
            }
        }
    }
    
    override public func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        // we're presenting a view controller from the menu, so we need to hide the menu so it isn't  g when the presented view is dismissed.
        if !isBeingDismissed() {
            view.hidden = true
            SideMenuTransition.hideMenuStart()
        }
    }
    
    override public func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        // don't bother resizing if the view isn't visible
        if view.hidden {
            return
        }
        
        SideMenuTransition.statusBarView?.hidden = true
        coordinator.animateAlongsideTransition({ (context) -> Void in
            SideMenuTransition.presentMenuStart(forSize: size)
            }) { (context) -> Void in
                SideMenuTransition.statusBarView?.hidden = false
        }
    }
    
    override public func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let menuViewController: UINavigationController = SideMenuTransition.presentDirection == .Left ? SideMenuManager.menuLeftNavigationController : SideMenuManager.menuRightNavigationController,
            presentingViewController = menuViewController.presentingViewController as? UINavigationController {
                presentingViewController.prepareForSegue(segue, sender: sender)
        }
    }
    
    override public func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        if let menuViewController: UINavigationController = SideMenuTransition.presentDirection == .Left ? SideMenuManager.menuLeftNavigationController : SideMenuManager.menuRightNavigationController,
            presentingViewController = menuViewController.presentingViewController as? UINavigationController {
                return presentingViewController.shouldPerformSegueWithIdentifier(identifier, sender: sender)
        }
        
        return super.shouldPerformSegueWithIdentifier(identifier, sender: sender)
    }
    
    override public func pushViewController(viewController: UIViewController, animated: Bool) {
        if let menuViewController: UINavigationController = SideMenuTransition.presentDirection == .Left ? SideMenuManager.menuLeftNavigationController : SideMenuManager.menuRightNavigationController {
            if let presentingViewController = menuViewController.presentingViewController as? UINavigationController {
                
                // to avoid overlapping dismiss & pop/push calls, create a transaction block where the menu
                // is dismissed after showing the appropriate screen
                CATransaction.begin()
                CATransaction.setCompletionBlock( { () -> Void in
                    self.dismissViewControllerAnimated(true, completion: nil)
                    self.visibleViewController?.viewWillAppear(false) // Hack: force selection to get cleared on UITableViewControllers when reappearing using custom transitions
                })
                
                UIView.animateWithDuration(SideMenuManager.menuAnimationDismissDuration, animations: { () -> Void in
                    SideMenuTransition.hideMenuStart()
                })
                
                if SideMenuManager.menuAllowPopIfPossible {
                    for subViewController in presentingViewController.viewControllers {
                        if subViewController.dynamicType == viewController.dynamicType {
                            presentingViewController.popToViewController(subViewController, animated: animated)
                            CATransaction.commit()
                            return
                        }
                    }
                }
                if !SideMenuManager.menuAllowPushOfSameClassTwice {
                    if presentingViewController.viewControllers.last?.dynamicType == viewController.dynamicType {
                        CATransaction.commit()
                        return
                    }
                }
                
                presentingViewController.pushViewController(viewController, animated: animated)
                CATransaction.commit()
            } else {
                menuViewController.presentViewController(viewController, animated: animated, completion: nil)
                print("Warning: attempted to push a ViewController from a ViewController that doesn't have a NavigationController. It will be presented it instead.")
            }
        }
    }
}


