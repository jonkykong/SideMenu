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
    fileprivate weak var originalSuperview: UIView?
    fileprivate weak var activeGesture: UIGestureRecognizer?
    fileprivate var switchMenus = false {
        didSet {
            if switchMenus {
                cancel()
            }
        }
    }
    fileprivate var menuWidth: CGFloat {
        get {
            let overriddenWidth = menuViewController?.menuWidth ?? 0
            if overriddenWidth > CGFloat.ulpOfOne {
                return overriddenWidth
            }
            return sideMenuManager.menuWidth
        }
    }
    internal weak var sideMenuManager: SideMenuManager!
    internal weak var mainViewController: UIViewController?
    internal weak var menuViewController: UISideMenuNavigationController? {
        get {
            return presentDirection == .left ? sideMenuManager.menuLeftNavigationController : sideMenuManager.menuRightNavigationController
        }
    }
    internal var presentDirection: UIRectEdge = .left
    internal weak var tapView: UIView? {
        didSet {
            guard let tapView = tapView else {
                return
            }
            
            tapView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
            let exitPanGesture = UIPanGestureRecognizer()
            exitPanGesture.addTarget(self, action:#selector(SideMenuTransition.handleHideMenuPan(_:)))
            let exitTapGesture = UITapGestureRecognizer()
            exitTapGesture.addTarget(self, action: #selector(SideMenuTransition.handleHideMenuTap(_:)))
            tapView.addGestureRecognizer(exitPanGesture)
            tapView.addGestureRecognizer(exitTapGesture)
        }
    }
    internal weak var statusBarView: UIView? {
        didSet {
            guard let statusBarView = statusBarView else {
                return
            }
            
            statusBarView.backgroundColor = sideMenuManager.menuAnimationBackgroundColor ?? UIColor.black
            statusBarView.isUserInteractionEnabled = false
        }
    }
    
    required public init(sideMenuManager: SideMenuManager) {
        super.init()
        
        NotificationCenter.default.addObserver(self, selector:#selector(handleNotification), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        NotificationCenter.default.addObserver(self, selector:#selector(handleNotification), name: NSNotification.Name.UIApplicationWillChangeStatusBarFrame, object: nil)
        self.sideMenuManager = sideMenuManager
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    fileprivate static var visibleViewController: UIViewController? {
        get {
            return getVisibleViewController(forViewController: UIApplication.shared.keyWindow?.rootViewController)
        }
    }
    
    fileprivate class func getVisibleViewController(forViewController: UIViewController?) -> UIViewController? {
        if let navigationController = forViewController as? UINavigationController {
            return getVisibleViewController(forViewController: navigationController.visibleViewController)
        }
        if let tabBarController = forViewController as? UITabBarController {
            return getVisibleViewController(forViewController: tabBarController.selectedViewController)
        }
        if let splitViewController = forViewController as? UISplitViewController {
            return getVisibleViewController(forViewController: splitViewController.viewControllers.last)
        }
        if let presentedViewController = forViewController?.presentedViewController {
            return getVisibleViewController(forViewController: presentedViewController)
        }
        
        return forViewController
    }
    
    @objc internal func handlePresentMenuLeftScreenEdge(_ edge: UIScreenEdgePanGestureRecognizer) {
        presentDirection = .left
        handlePresentMenuPan(edge)
    }
    
    @objc internal func handlePresentMenuRightScreenEdge(_ edge: UIScreenEdgePanGestureRecognizer) {
        presentDirection = .right
        handlePresentMenuPan(edge)
    }
    
    @objc internal func handlePresentMenuPan(_ pan: UIPanGestureRecognizer) {
        if activeGesture == nil {
            activeGesture = pan
        } else if pan != activeGesture {
            pan.isEnabled = false
            pan.isEnabled = true
            return
        } else if pan.state != .began && pan.state != .changed {
            activeGesture = nil
        }
        
        // how much distance have we panned in reference to the parent view?
        guard let view = mainViewController?.view ?? pan.view else {
            return
        }
        
        let transform = view.transform
        view.transform = .identity
        let translation = pan.translation(in: pan.view!)
        view.transform = transform
        
        // do some math to translate this to a percentage based value
        if !interactive {
            if translation.x == 0 {
                return // not sure which way the user is swiping yet, so do nothing
            }
            
            if !(pan is UIScreenEdgePanGestureRecognizer) {
                presentDirection = translation.x > 0 ? .left : .right
            }
            
            if let menuViewController = menuViewController, let visibleViewController = SideMenuTransition.visibleViewController {
                interactive = true
                visibleViewController.present(menuViewController, animated: true, completion: nil)
            } else {
                return
            }
        }
        
        let direction: CGFloat = presentDirection == .left ? 1 : -1
        let distance = translation.x / menuWidth
        // now lets deal with different states that the gesture recognizer sends
        switch (pan.state) {
        case .began, .changed:
            if pan is UIScreenEdgePanGestureRecognizer {
                update(min(distance * direction, 1))
            } else if distance > 0 && presentDirection == .right && sideMenuManager.menuLeftNavigationController != nil {
                presentDirection = .left
                switchMenus = true
            } else if distance < 0 && presentDirection == .left && sideMenuManager.menuRightNavigationController != nil {
                presentDirection = .right
                switchMenus = true
            } else {
                update(min(distance * direction, 1))
            }
        default:
            interactive = false
            view.transform = .identity
            let velocity = pan.velocity(in: pan.view!).x * direction
            view.transform = transform
            if velocity >= 100 || velocity >= -50 && abs(distance) >= 0.5 {
                // bug workaround: animation briefly resets after call to finishInteractiveTransition() but before animateTransition completion is called.
                if ProcessInfo().operatingSystemVersion.majorVersion == 8 && percentComplete > 1 - CGFloat.ulpOfOne {
                    update(0.9999)
                }
                finish()
            } else {
                cancel()
            }
        }
    }
    
    @objc internal func handleHideMenuPan(_ pan: UIPanGestureRecognizer) {
        if activeGesture == nil {
            activeGesture = pan
        } else if pan != activeGesture {
            pan.isEnabled = false
            pan.isEnabled = true
            return
        }
        
        let translation = pan.translation(in: pan.view!)
        let direction:CGFloat = presentDirection == .left ? -1 : 1
        let distance = translation.x / menuWidth * direction
        
        switch (pan.state) {
            
        case .began:
            interactive = true
            mainViewController?.dismiss(animated: true, completion: nil)
        case .changed:
            update(max(min(distance, 1), 0))
        default:
            interactive = false
            let velocity = pan.velocity(in: pan.view!).x * direction
            if velocity >= 100 || velocity >= -50 && distance >= 0.5 {
                // bug workaround: animation briefly resets after call to finishInteractiveTransition() but before animateTransition completion is called.
                if ProcessInfo().operatingSystemVersion.majorVersion == 8 && percentComplete > 1 - CGFloat.ulpOfOne {
                    update(0.9999)
                }
                finish()
                activeGesture = nil
            } else {
                cancel()
                activeGesture = nil
            }
        }
    }
    
    @objc internal func handleHideMenuTap(_ tap: UITapGestureRecognizer) {
        menuViewController?.dismiss(animated: true, completion: nil)
    }
    
    @discardableResult internal func hideMenuStart() -> SideMenuTransition {
        let menuView = menuViewController?.view
        let mainView = mainViewController?.view
      
        mainView?.transform = .identity
        mainView?.alpha = 1
        mainView?.frame.origin = .zero
        menuView?.transform = .identity
        menuView?.frame.origin.y = 0
        menuView?.frame.size.width = menuWidth
        menuView?.frame.size.height = mainView?.frame.height ?? 0 // in case status bar height changed
        var statusBarFrame = UIApplication.shared.statusBarFrame
        let statusBarOffset = SideMenuManager.appScreenRect.size.height - (mainView?.frame.maxY ?? 0)
        // For in-call status bar, height is normally 40, which overlaps view. Instead, calculate height difference
        // of view and set height to fill in remaining space.
        if statusBarOffset >= CGFloat.ulpOfOne {
            statusBarFrame.size.height = statusBarOffset
        }
        statusBarView?.frame = statusBarFrame
        statusBarView?.alpha = 0
        
        switch sideMenuManager.menuPresentMode {
            
        case .viewSlideOut:
            menuView?.alpha = 1 - sideMenuManager.menuAnimationFadeStrength
            menuView?.frame.origin.x = presentDirection == .left ? 0 : (mainView?.frame.width ?? 0) - menuWidth
            menuView?.transform = CGAffineTransform(scaleX: sideMenuManager.menuAnimationTransformScaleFactor, y: sideMenuManager.menuAnimationTransformScaleFactor)
            
        case .viewSlideInOut:
            menuView?.alpha = 1
            menuView?.frame.origin.x = presentDirection == .left ? -menuView!.frame.width : mainView!.frame.width
            
        case .menuSlideIn:
            menuView?.alpha = 1
            menuView?.frame.origin.x = presentDirection == .left ? -menuView!.frame.width : mainView!.frame.width
            
        case .menuDissolveIn:
            menuView?.alpha = 0
            menuView?.frame.origin.x = presentDirection == .left ? 0 : mainView!.frame.width - menuWidth
        }
        
        return self
    }
    
    @discardableResult internal func hideMenuComplete() -> SideMenuTransition {
        let menuView = menuViewController?.view
        let mainView = mainViewController?.view

        tapView?.removeFromSuperview()
        statusBarView?.removeFromSuperview()
        mainView?.motionEffects.removeAll()
        mainView?.layer.shadowOpacity = 0
        menuView?.layer.shadowOpacity = 0
        if let topNavigationController = mainViewController as? UINavigationController {
            topNavigationController.interactivePopGestureRecognizer!.isEnabled = true
        }
        if let originalSuperview = originalSuperview, let mainView = mainViewController?.view {
            originalSuperview.addSubview(mainView)
            let y = originalSuperview.bounds.height - mainView.frame.size.height
            mainView.frame.origin.y = max(y, 0)
        }
        
        originalSuperview = nil
        mainViewController = nil
        
        return self
    }
    
    @discardableResult internal func presentMenuStart() -> SideMenuTransition {
        let menuView = menuViewController?.view
        let mainView = mainViewController?.view
        
        menuView?.alpha = 1
        menuView?.transform = .identity
        menuView?.frame.size.width = menuWidth
        let size = SideMenuManager.appScreenRect.size
        menuView?.frame.origin.x = presentDirection == .left ? 0 : size.width - menuWidth
        mainView?.transform = .identity
        mainView?.frame.size.width = size.width
        let statusBarOffset = size.height - (menuView?.bounds.height ?? 0)
        mainView?.bounds.size.height = size.height - max(statusBarOffset, 0)
        mainView?.frame.origin.y = 0
        var statusBarFrame = UIApplication.shared.statusBarFrame
        // For in-call status bar, height is normally 40, which overlaps view. Instead, calculate height difference
        // of view and set height to fill in remaining space.
        if statusBarOffset >= CGFloat.ulpOfOne {
            statusBarFrame.size.height = statusBarOffset
        }
        tapView?.transform = .identity
        tapView?.bounds = mainView!.bounds
        statusBarView?.frame = statusBarFrame
        statusBarView?.alpha = 1
        
        switch sideMenuManager.menuPresentMode {
            
        case .viewSlideOut, .viewSlideInOut:
            mainView?.layer.shadowColor = sideMenuManager.menuShadowColor.cgColor
            mainView?.layer.shadowRadius = sideMenuManager.menuShadowRadius
            mainView?.layer.shadowOpacity = sideMenuManager.menuShadowOpacity
            mainView?.layer.shadowOffset = CGSize(width: 0, height: 0)
            let direction:CGFloat = presentDirection == .left ? 1 : -1
            mainView?.frame.origin.x = direction * (menuView!.frame.width)
            
        case .menuSlideIn, .menuDissolveIn:
            if sideMenuManager.menuBlurEffectStyle == nil {
                menuView?.layer.shadowColor = sideMenuManager.menuShadowColor.cgColor
                menuView?.layer.shadowRadius = sideMenuManager.menuShadowRadius
                menuView?.layer.shadowOpacity = sideMenuManager.menuShadowOpacity
                menuView?.layer.shadowOffset = CGSize(width: 0, height: 0)
            }
            mainView?.frame.origin.x = 0
        }
        
        if sideMenuManager.menuPresentMode != .viewSlideOut {
            mainView?.transform = CGAffineTransform(scaleX: sideMenuManager.menuAnimationTransformScaleFactor, y: sideMenuManager.menuAnimationTransformScaleFactor)
            if sideMenuManager.menuAnimationTransformScaleFactor > 1 {
                tapView?.transform = mainView!.transform
            }
            mainView?.alpha = 1 - sideMenuManager.menuAnimationFadeStrength
        }
        
        return self
    }
    
    @discardableResult internal func presentMenuComplete() -> SideMenuTransition {
        switch sideMenuManager.menuPresentMode {
        case .menuSlideIn, .menuDissolveIn, .viewSlideInOut:
            if let mainView = mainViewController?.view, sideMenuManager.menuParallaxStrength != 0 {
                let horizontal = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)
                horizontal.minimumRelativeValue = -sideMenuManager.menuParallaxStrength
                horizontal.maximumRelativeValue = sideMenuManager.menuParallaxStrength
                
                let vertical = UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongVerticalAxis)
                vertical.minimumRelativeValue = -sideMenuManager.menuParallaxStrength
                vertical.maximumRelativeValue = sideMenuManager.menuParallaxStrength
                
                let group = UIMotionEffectGroup()
                group.motionEffects = [horizontal, vertical]
                mainView.addMotionEffect(group)
            }
        case .viewSlideOut: break;
        }
        if let topNavigationController = mainViewController as? UINavigationController {
            topNavigationController.interactivePopGestureRecognizer!.isEnabled = false
        }
        
        return self
    }
    
    @objc internal func handleNotification(notification: NSNotification) {
        guard menuViewController?.presentedViewController == nil &&
            menuViewController?.presentingViewController != nil else {
                return
        }
        
        if let originalSuperview = originalSuperview, let mainViewController = mainViewController {
            originalSuperview.addSubview(mainViewController.view)
        }
        
        if notification.name == NSNotification.Name.UIApplicationDidEnterBackground {
            hideMenuStart().hideMenuComplete()
            menuViewController?.dismiss(animated: false, completion: nil)
            return
        }
        
        UIView.animate(withDuration: sideMenuManager.menuAnimationDismissDuration,
                       delay: 0,
                       usingSpringWithDamping: sideMenuManager.menuAnimationUsingSpringWithDamping,
                       initialSpringVelocity: sideMenuManager.menuAnimationInitialSpringVelocity,
                       options: sideMenuManager.menuAnimationOptions,
                       animations: {
                        self.hideMenuStart()
        }) { (finished) -> Void in
            self.hideMenuComplete()
            self.menuViewController?.dismiss(animated: false, completion: nil)
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
        
        if let menuBackgroundColor = sideMenuManager.menuAnimationBackgroundColor {
            container.backgroundColor = menuBackgroundColor
        }
        
        let fromViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)!
        let toViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)!
        
        // assign references to our menu view controller and the 'bottom' view controller from the tuple
        // remember that our menuViewController will alternate between the from and to view controller depending if we're presenting or dismissing
        mainViewController = presenting ? fromViewController : toViewController
        
        let menuView = menuViewController!.view!
        let topView = mainViewController!.view!
        
        // prepare menu items to slide in
        if presenting {
            originalSuperview = topView.superview
            
            // add the both views to our view controller
            switch sideMenuManager.menuPresentMode {
            case .viewSlideOut, .viewSlideInOut:
                container.addSubview(menuView)
                container.addSubview(topView)
            case .menuSlideIn, .menuDissolveIn:
                container.addSubview(topView)
                container.addSubview(menuView)
            }

            if sideMenuManager.menuFadeStatusBar {
                let statusBarView = UIView()
                self.statusBarView = statusBarView
                container.addSubview(statusBarView)
            }
            
            hideMenuStart()
        }
        
        let animate = {
            if self.presenting {
                self.presentMenuStart()
            } else {
                self.hideMenuStart()
            }
        }
        
        let complete = {
            container.isUserInteractionEnabled = true
            
            // tell our transitionContext object that we've finished animating
            if transitionContext.transitionWasCancelled {
                let viewControllerForPresentedMenu = self.mainViewController
                
                if self.presenting {
                    self.hideMenuComplete()
                } else {
                    self.presentMenuComplete()
                }
                
                transitionContext.completeTransition(false)
                
                if self.switchMenus {
                    self.switchMenus = false
                    viewControllerForPresentedMenu?.present(self.menuViewController!, animated: true, completion: nil)
                }
                
                return
            }
            
            if self.presenting {
                self.presentMenuComplete()
                transitionContext.completeTransition(true)
                switch self.sideMenuManager.menuPresentMode {
                case .viewSlideOut, .viewSlideInOut:
                    container.addSubview(topView)
                case .menuSlideIn, .menuDissolveIn:
                    container.insertSubview(topView, at: 0)
                }
                if !self.sideMenuManager.menuPresentingViewControllerUserInteractionEnabled {
                    let tapView = UIView()
                    container.insertSubview(tapView, aboveSubview: topView)
                    tapView.bounds = container.bounds
                    tapView.center = topView.center
                    if self.sideMenuManager.menuAnimationTransformScaleFactor > 1 {
                        tapView.transform = topView.transform
                    }
                    self.tapView = tapView
                }
                if let statusBarView = self.statusBarView {
                    container.bringSubview(toFront: statusBarView)
                }
                
                return
            }
            
            self.hideMenuComplete()
            transitionContext.completeTransition(true)
            menuView.removeFromSuperview()
        }
        
        // perform the animation!
        let duration = transitionDuration(using: transitionContext)
        if interactive {
            UIView.animate(withDuration: duration,
                           delay: duration, // HACK: If zero, the animation briefly flashes in iOS 11. UIViewPropertyAnimators (iOS 10+) may resolve this.
                           options: .curveLinear,
                           animations: {
                            animate()
            }, completion: { (finished) in
                complete()
            })
        } else {
            UIView.animate(withDuration: duration,
                           delay: 0,
                           usingSpringWithDamping: sideMenuManager.menuAnimationUsingSpringWithDamping,
                           initialSpringVelocity: sideMenuManager.menuAnimationInitialSpringVelocity,
                           options: sideMenuManager.menuAnimationOptions,
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
            return sideMenuManager.menuAnimationCompleteGestureDuration
        }
        return presenting ? sideMenuManager.menuAnimationPresentDuration : sideMenuManager.menuAnimationDismissDuration
    }
    
    open override func update(_ percentComplete: CGFloat) {
        guard !switchMenus else {
            return
        }
        
        super.update(percentComplete)
    }
    
}

extension SideMenuTransition: UIViewControllerTransitioningDelegate {
    
    // return the animator when presenting a viewcontroller
    // rememeber that an animator (or animation controller) is any object that aheres to the UIViewControllerAnimatedTransitioning protocol
    open func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        self.presenting = true
        presentDirection = presented == sideMenuManager.menuLeftNavigationController ? .left : .right
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
        return interactive ? self : nil
    }
    
    open func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactive ? self : nil
    }
    
}
