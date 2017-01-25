//
//  SideMenuTransition.swift
//  Pods
//
//  Created by Jon Kent on 1/14/16.
//
//

import UIKit

open class SideMenuTransition: UIPercentDrivenInteractiveTransition {
    
    fileprivate var presenting = false
    fileprivate var interactive = false
    fileprivate static weak var originalSuperview: UIView?
    fileprivate static weak var activeGesture: UIGestureRecognizer?
    fileprivate static var switchMenus = false
    
    internal static let singleton = SideMenuTransition()
    internal static var presentDirection: UIRectEdge = .left;
    internal static weak var tapView: UIView? {
        didSet {
            guard let tapView = tapView else {
                return
            }
            
            tapView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
            let exitPanGesture = UIPanGestureRecognizer()
            exitPanGesture.addTarget(SideMenuTransition.self, action:#selector(SideMenuTransition.handleHideMenuPan(_:)))
            let exitTapGesture = UITapGestureRecognizer()
            exitTapGesture.addTarget(SideMenuTransition.self, action: #selector(SideMenuTransition.handleHideMenuTap(_:)))
            tapView.addGestureRecognizer(exitPanGesture)
            tapView.addGestureRecognizer(exitTapGesture)
        }
    }
    internal static weak var statusBarView: UIView? {
        didSet {
            guard let statusBarView = statusBarView else {
                return
            }
            
            if let menuShrinkBackgroundColor = SideMenuManager.menuAnimationBackgroundColor {
                statusBarView.backgroundColor = menuShrinkBackgroundColor
            } else {
                statusBarView.backgroundColor = UIColor.black
            }
            statusBarView.isUserInteractionEnabled = false
        }
    }
    
    // prevent instantiation
    fileprivate override init() {}
    
    fileprivate class var viewControllerForPresentedMenu: UIViewController? {
        get {
            return SideMenuManager.menuLeftNavigationController?.presentingViewController != nil ? SideMenuManager.menuLeftNavigationController?.presentingViewController : SideMenuManager.menuRightNavigationController?.presentingViewController
        }
    }
    
    fileprivate class var visibleViewController: UIViewController? {
        get {
            return getVisibleViewControllerFromViewController(UIApplication.shared.keyWindow?.rootViewController)
        }
    }
    
    fileprivate class func getVisibleViewControllerFromViewController(_ viewController: UIViewController?) -> UIViewController? {
        if let navigationController = viewController as? UINavigationController {
            return getVisibleViewControllerFromViewController(navigationController.visibleViewController)
        } else if let tabBarController = viewController as? UITabBarController {
            return getVisibleViewControllerFromViewController(tabBarController.selectedViewController)
        } else if let presentedViewController = viewController?.presentedViewController {
            return getVisibleViewControllerFromViewController(presentedViewController)
        }
        
        return viewController
    }
    
    internal class func handlePresentMenuLeftScreenEdge(_ edge: UIScreenEdgePanGestureRecognizer) {
        SideMenuTransition.presentDirection = .left
        handlePresentMenuPan(edge)
    }
    
    internal class func handlePresentMenuRightScreenEdge(_ edge: UIScreenEdgePanGestureRecognizer) {
        SideMenuTransition.presentDirection = .right
        handlePresentMenuPan(edge)
    }
    
    internal class func handlePresentMenuPan(_ pan: UIPanGestureRecognizer) {
        if activeGesture == nil {
            activeGesture = pan
        } else if pan != activeGesture {
            pan.isEnabled = false
            pan.isEnabled = true
            return
        }
        
        // how much distance have we panned in reference to the parent view?
        guard let view = viewControllerForPresentedMenu != nil ? viewControllerForPresentedMenu?.view : pan.view else {
            return
        }
        
        let transform = view.transform
        view.transform = CGAffineTransform.identity
        let translation = pan.translation(in: pan.view!)
        view.transform = transform
        
        // do some math to translate this to a percentage based value
        if !singleton.interactive {
            if translation.x == 0 {
                return // not sure which way the user is swiping yet, so do nothing
            }
            
            if !(pan is UIScreenEdgePanGestureRecognizer) {
                SideMenuTransition.presentDirection = translation.x > 0 ? .left : .right
            }
            
            if let menuViewController = SideMenuTransition.presentDirection == .left ? SideMenuManager.menuLeftNavigationController : SideMenuManager.menuRightNavigationController,
                let visibleViewController = visibleViewController {
                singleton.interactive = true
                visibleViewController.present(menuViewController, animated: true, completion: nil)
            } else {
                return
            }
        }
        
        let direction: CGFloat = SideMenuTransition.presentDirection == .left ? 1 : -1
        let distance = translation.x / SideMenuManager.menuWidth
        // now lets deal with different states that the gesture recognizer sends
        switch (pan.state) {
        case .began, .changed:
            if pan is UIScreenEdgePanGestureRecognizer {
                singleton.update(min(distance * direction, 1))
            } else if distance > 0 && SideMenuTransition.presentDirection == .right && SideMenuManager.menuLeftNavigationController != nil {
                SideMenuTransition.presentDirection = .left
                switchMenus = true
                singleton.cancel()
            } else if distance < 0 && SideMenuTransition.presentDirection == .left && SideMenuManager.menuRightNavigationController != nil {
                SideMenuTransition.presentDirection = .right
                switchMenus = true
                singleton.cancel()
            } else {
                singleton.update(min(distance * direction, 1))
            }
        default:
            singleton.interactive = false
            view.transform = CGAffineTransform.identity
            let velocity = pan.velocity(in: pan.view!).x * direction
            view.transform = transform
            if velocity >= 100 || velocity >= -50 && abs(distance) >= 0.5 {
                // bug workaround: animation briefly resets after call to finishInteractiveTransition() but before animateTransition completion is called.
                if ProcessInfo().operatingSystemVersion.majorVersion == 8 && singleton.percentComplete > 1 - CGFloat(FLT_EPSILON) {
                    singleton.update(0.9999)
                }
                singleton.finish()
                activeGesture = nil
            } else {
                singleton.cancel()
                activeGesture = nil
            }
        }
    }
    
    internal class func handleHideMenuPan(_ pan: UIPanGestureRecognizer) {
        if activeGesture == nil {
            activeGesture = pan
        } else if pan != activeGesture {
            pan.isEnabled = false
            pan.isEnabled = true
            return
        }
        
        let translation = pan.translation(in: pan.view!)
        let direction:CGFloat = SideMenuTransition.presentDirection == .left ? -1 : 1
        let distance = translation.x / SideMenuManager.menuWidth * direction
        
        switch (pan.state) {
            
        case .began:
            singleton.interactive = true
            viewControllerForPresentedMenu?.dismiss(animated: true, completion: nil)
        case .changed:
            singleton.update(max(min(distance, 1), 0))
        default:
            singleton.interactive = false
            let velocity = pan.velocity(in: pan.view!).x * direction
            if velocity >= 100 || velocity >= -50 && distance >= 0.5 {
                // bug workaround: animation briefly resets after call to finishInteractiveTransition() but before animateTransition completion is called.
                if ProcessInfo().operatingSystemVersion.majorVersion == 8 && singleton.percentComplete > 1 - CGFloat(FLT_EPSILON) {
                    singleton.update(0.9999)
                }
                singleton.finish()
                activeGesture = nil
            } else {
                singleton.cancel()
                activeGesture = nil
            }
        }
    }
    
    internal class func handleHideMenuTap(_ tap: UITapGestureRecognizer) {
        viewControllerForPresentedMenu?.dismiss(animated: true, completion: nil)
    }
    
    internal class func hideMenuStart() {
        NotificationCenter.default.removeObserver(SideMenuTransition.singleton)
        guard let mainViewController = SideMenuTransition.viewControllerForPresentedMenu,
            let menuView = SideMenuTransition.presentDirection == .left ? SideMenuManager.menuLeftNavigationController?.view : SideMenuManager.menuRightNavigationController?.view else {
                return
        }
      
        menuView.transform = CGAffineTransform.identity
        mainViewController.view.transform = CGAffineTransform.identity
        mainViewController.view.alpha = 1
        SideMenuTransition.tapView?.frame = CGRect(x: 0, y: 0, width: mainViewController.view.frame.width, height: mainViewController.view.frame.height)
        menuView.frame.origin.y = 0
        menuView.frame.size.width = SideMenuManager.menuWidth
        menuView.frame.size.height = mainViewController.view.frame.height
        SideMenuTransition.statusBarView?.frame = UIApplication.shared.statusBarFrame
        SideMenuTransition.statusBarView?.alpha = 0
        
        switch SideMenuManager.menuPresentMode {
            
        case .viewSlideOut:
            menuView.alpha = 1 - SideMenuManager.menuAnimationFadeStrength
            menuView.frame.origin.x = SideMenuTransition.presentDirection == .left ? 0 : mainViewController.view.frame.width - SideMenuManager.menuWidth
            mainViewController.view.frame.origin.x = 0
            menuView.transform = CGAffineTransform(scaleX: SideMenuManager.menuAnimationTransformScaleFactor, y: SideMenuManager.menuAnimationTransformScaleFactor)
            
        case .viewSlideInOut:
            menuView.alpha = 1
            menuView.frame.origin.x = SideMenuTransition.presentDirection == .left ? -menuView.frame.width : mainViewController.view.frame.width
            mainViewController.view.frame.origin.x = 0
            
        case .menuSlideIn:
            menuView.alpha = 1
            menuView.frame.origin.x = SideMenuTransition.presentDirection == .left ? -menuView.frame.width : mainViewController.view.frame.width
            
        case .menuDissolveIn:
            menuView.alpha = 0
            menuView.frame.origin.x = SideMenuTransition.presentDirection == .left ? 0 : mainViewController.view.frame.width - SideMenuManager.menuWidth
            mainViewController.view.frame.origin.x = 0
        }
    }
    
    internal class func hideMenuComplete() {
        guard let mainViewController = SideMenuTransition.viewControllerForPresentedMenu,
            let menuView = SideMenuTransition.presentDirection == .left ? SideMenuManager.menuLeftNavigationController?.view : SideMenuManager.menuRightNavigationController?.view else {
                return
        }

        SideMenuTransition.tapView?.removeFromSuperview()
        SideMenuTransition.statusBarView?.removeFromSuperview()
        mainViewController.view.motionEffects.removeAll()
        mainViewController.view.layer.shadowOpacity = 0
        menuView.layer.shadowOpacity = 0
        if let topNavigationController = mainViewController as? UINavigationController {
            topNavigationController.interactivePopGestureRecognizer!.isEnabled = true
        }
        originalSuperview?.addSubview(mainViewController.view)
    }
    
    internal class func presentMenuStart(forSize size: CGSize = SideMenuManager.appScreenRect.size) {
        guard let menuView = SideMenuTransition.presentDirection == .left ? SideMenuManager.menuLeftNavigationController?.view : SideMenuManager.menuRightNavigationController?.view,
            let mainViewController = SideMenuTransition.viewControllerForPresentedMenu else {
                return
        }
        
        menuView.transform = CGAffineTransform.identity
        mainViewController.view.transform = CGAffineTransform.identity
        menuView.frame.size.width = SideMenuManager.menuWidth
        menuView.frame.size.height = size.height
        menuView.frame.origin.x = SideMenuTransition.presentDirection == .left ? 0 : size.width - SideMenuManager.menuWidth
        SideMenuTransition.statusBarView?.frame = UIApplication.shared.statusBarFrame
        SideMenuTransition.statusBarView?.alpha = 1
        
        switch SideMenuManager.menuPresentMode {
            
        case .viewSlideOut:
            menuView.alpha = 1
            let direction:CGFloat = SideMenuTransition.presentDirection == .left ? 1 : -1
            mainViewController.view.frame.origin.x = direction * (menuView.frame.width)
            mainViewController.view.layer.shadowColor = SideMenuManager.menuShadowColor.cgColor
            mainViewController.view.layer.shadowRadius = SideMenuManager.menuShadowRadius
            mainViewController.view.layer.shadowOpacity = SideMenuManager.menuShadowOpacity
            mainViewController.view.layer.shadowOffset = CGSize(width: 0, height: 0)
            
        case .viewSlideInOut:
            menuView.alpha = 1
            mainViewController.view.layer.shadowColor = SideMenuManager.menuShadowColor.cgColor
            mainViewController.view.layer.shadowRadius = SideMenuManager.menuShadowRadius
            mainViewController.view.layer.shadowOpacity = SideMenuManager.menuShadowOpacity
            mainViewController.view.layer.shadowOffset = CGSize(width: 0, height: 0)
            let direction:CGFloat = SideMenuTransition.presentDirection == .left ? 1 : -1
            mainViewController.view.frame = CGRect(x: direction * (menuView.frame.width), y: 0, width: size.width, height: size.height)
            mainViewController.view.transform = CGAffineTransform(scaleX: SideMenuManager.menuAnimationTransformScaleFactor, y: SideMenuManager.menuAnimationTransformScaleFactor)
            mainViewController.view.alpha = 1 - SideMenuManager.menuAnimationFadeStrength
            
        case .menuSlideIn, .menuDissolveIn:
            menuView.alpha = 1
            if SideMenuManager.menuBlurEffectStyle == nil {
                menuView.layer.shadowColor = SideMenuManager.menuShadowColor.cgColor
                menuView.layer.shadowRadius = SideMenuManager.menuShadowRadius
                menuView.layer.shadowOpacity = SideMenuManager.menuShadowOpacity
                menuView.layer.shadowOffset = CGSize(width: 0, height: 0)
            }
            mainViewController.view.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            mainViewController.view.transform = CGAffineTransform(scaleX: SideMenuManager.menuAnimationTransformScaleFactor, y: SideMenuManager.menuAnimationTransformScaleFactor)
            mainViewController.view.alpha = 1 - SideMenuManager.menuAnimationFadeStrength
        }
    }
    
    internal class func presentMenuComplete() {
        NotificationCenter.default.addObserver(SideMenuTransition.singleton, selector:#selector(SideMenuTransition.applicationDidEnterBackgroundNotification), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        guard let mainViewController = SideMenuTransition.viewControllerForPresentedMenu else {
            return
        }
      
        switch SideMenuManager.menuPresentMode {
        case .menuSlideIn, .menuDissolveIn, .viewSlideInOut:
            if SideMenuManager.menuParallaxStrength != 0 {
                let horizontal = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)
                horizontal.minimumRelativeValue = -SideMenuManager.menuParallaxStrength
                horizontal.maximumRelativeValue = SideMenuManager.menuParallaxStrength
                
                let vertical = UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongVerticalAxis)
                vertical.minimumRelativeValue = -SideMenuManager.menuParallaxStrength
                vertical.maximumRelativeValue = SideMenuManager.menuParallaxStrength
                
                let group = UIMotionEffectGroup()
                group.motionEffects = [horizontal, vertical]
                mainViewController.view.addMotionEffect(group)
            }
        case .viewSlideOut: break;
        }
        if let topNavigationController = mainViewController as? UINavigationController {
            topNavigationController.interactivePopGestureRecognizer!.isEnabled = false
        }
    }
    
}

extension SideMenuTransition: UIViewControllerAnimatedTransitioning {
    
    // animate a change from one viewcontroller to another
    open func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        // get reference to our fromView, toView and the container view that we should perform the transition in
        let container = transitionContext.containerView
        // prevent any other menu gestures from firing
        container.isUserInteractionEnabled = false
        
        if let menuBackgroundColor = SideMenuManager.menuAnimationBackgroundColor {
            container.backgroundColor = menuBackgroundColor
        }
        
        let fromViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)!
        let toViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)!
        
        // assign references to our menu view controller and the 'bottom' view controller from the tuple
        // remember that our menuViewController will alternate between the from and to view controller depending if we're presenting or dismissing
        let menuViewController = presenting ? toViewController : fromViewController
        let topViewController = presenting ? fromViewController : toViewController
        
        let menuView = menuViewController.view!
        let topView = topViewController.view!
        
        // prepare menu items to slide in
        if presenting {
            SideMenuTransition.originalSuperview = topView.superview
            
            // add the both views to our view controller
            switch SideMenuManager.menuPresentMode {
            case .viewSlideOut, .viewSlideInOut:
                container.addSubview(menuView)
                container.addSubview(topView)
            case .menuSlideIn, .menuDissolveIn:
                container.addSubview(topView)
                container.addSubview(menuView)
            }

            if SideMenuManager.menuFadeStatusBar {
                let statusBarView = UIView()
                SideMenuTransition.statusBarView = statusBarView
                container.addSubview(statusBarView)
            }
            
            SideMenuTransition.hideMenuStart()
        }
        
        let animate = {
            if self.presenting {
                SideMenuTransition.presentMenuStart()
            } else {
                SideMenuTransition.hideMenuStart()
            }
        }
        
        let complete = {
            container.isUserInteractionEnabled = true
            
            // tell our transitionContext object that we've finished animating
            if transitionContext.transitionWasCancelled {
                let viewControllerForPresentedMenu = SideMenuTransition.viewControllerForPresentedMenu
                
                if self.presenting {
                    SideMenuTransition.hideMenuComplete()
                } else {
                    SideMenuTransition.presentMenuComplete()
                }
                
                transitionContext.completeTransition(false)
                
                if SideMenuTransition.switchMenus {
                    SideMenuTransition.switchMenus = false
                    viewControllerForPresentedMenu?.present(SideMenuTransition.presentDirection == .left ? SideMenuManager.menuLeftNavigationController! : SideMenuManager.menuRightNavigationController!, animated: true, completion: nil)
                }
                
                return
            }
            
            if self.presenting {
                SideMenuTransition.presentMenuComplete()
                if !SideMenuManager.menuPresentingViewControllerUserInteractionEnabled {
                    let tapView = UIView()
                    topView.addSubview(tapView)
                    tapView.frame = topView.bounds
                    SideMenuTransition.tapView = tapView
                }
                transitionContext.completeTransition(true)
                switch SideMenuManager.menuPresentMode {
                case .viewSlideOut, .viewSlideInOut:
                    container.addSubview(topView)
                case .menuSlideIn, .menuDissolveIn:
                    container.insertSubview(topView, at: 0)
                }
                if let statusBarView = SideMenuTransition.statusBarView {
                    container.bringSubview(toFront: statusBarView)
                }
                
                return
            }
            
            SideMenuTransition.hideMenuComplete()
            transitionContext.completeTransition(true)
            menuView.removeFromSuperview()
        }
        
        // perform the animation!
        let duration = transitionDuration(using: transitionContext)
        if interactive {
            UIView.animate(withDuration: duration,
                           delay: 0,
                           options: .curveLinear,
                           animations: {
                            animate()
            }, completion: { (finished) in
                complete()
            })
        } else {
            UIView.animate(withDuration: duration,
                           delay: 0,
                           usingSpringWithDamping: SideMenuManager.menuAnimationUsingSpringWithDamping,
                           initialSpringVelocity: SideMenuManager.menuAnimationInitialSpringVelocity,
                           options: SideMenuManager.menuAnimationOptions,
                           animations: {
                            animate()
            }) { (finished) -> Void in
                complete()
            }
        }
    }
    
    // return how many seconds the transiton animation will take
    open func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        if interactive {
            return SideMenuManager.menuAnimationCompleteGestureDuration
        }
        return presenting ? SideMenuManager.menuAnimationPresentDuration : SideMenuManager.menuAnimationDismissDuration
    }
    
}

extension SideMenuTransition: UIViewControllerTransitioningDelegate {
    
    // return the animator when presenting a viewcontroller
    // rememeber that an animator (or animation controller) is any object that aheres to the UIViewControllerAnimatedTransitioning protocol
    open func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        self.presenting = true
        SideMenuTransition.presentDirection = presented == SideMenuManager.menuLeftNavigationController ? .left : .right
        return self
    }
    
    // return the animator used when dismissing from a viewcontroller
    open func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        presenting = false
        return self
    }
    
    open func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        // if our interactive flag is true, return the transition manager object
        // otherwise return nil
        return interactive ? SideMenuTransition.singleton : nil
    }
    
    open func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactive ? SideMenuTransition.singleton : nil
    }
    
    internal func applicationDidEnterBackgroundNotification() {
        if let menuViewController: UINavigationController = SideMenuTransition.presentDirection == .left ? SideMenuManager.menuLeftNavigationController : SideMenuManager.menuRightNavigationController,
            menuViewController.presentedViewController == nil {
            SideMenuTransition.hideMenuStart()
            SideMenuTransition.hideMenuComplete()
            menuViewController.dismiss(animated: false, completion: nil)
        }
    }
    
}
