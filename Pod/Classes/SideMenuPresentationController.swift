//
//  BasePresentationController.swift
//  SideMenu
//
//  Created by Jon Kent on 10/20/18.
//

import UIKit

internal protocol PresentationModel {
    /// Draws `presentStyle.backgroundColor` behind the status bar. Default is 1.
    var statusBarEndAlpha: CGFloat { get }
    /// Enable or disable interaction with the presenting view controller while the menu is displayed. Enabling may make it difficult to dismiss the menu or cause exceptions if the user tries to present and already presented menu. `presentingViewControllerUseSnapshot` must also set to false. Default is false.
    var presentingViewControllerUserInteractionEnabled: Bool { get }
    /// Use a snapshot for the presenting vierw controller while the menu is displayed. Useful when layout changes occur during transitions. Not recommended for apps that support rotation. Default is false.
    var presentingViewControllerUseSnapshot: Bool { get }
    /// The presentation style of the menu.
    var presentationStyle: SideMenuPresentationStyle { get }
    /// Width of the menu when presented on screen, showing the existing view controller in the remaining space. Default is zero.
    var menuWidth: CGFloat { get }
}

internal protocol SideMenuPresentationControllerDelegate: AnyObject {
    func sideMenuPresentationControllerDidTap(_ presentationController: SideMenuPresentationController)
    func sideMenuPresentationController(_ presentationController: SideMenuPresentationController, didPanWith gesture: UIPanGestureRecognizer)
}

internal final class SideMenuPresentationController {

    private let config: PresentationModel
    private weak var containerView: UIView?
    private var interactivePopGestureRecognizerEnabled: Bool?
    private var clipsToBounds: Bool?
    private let leftSide: Bool
    private weak var presentedViewController: UIViewController?
    private weak var presentingViewController: UIViewController?

    private lazy var snapshotView: UIView? = {
        guard config.presentingViewControllerUseSnapshot,
            let view = presentingViewController?.view.snapshotView(afterScreenUpdates: true) else {
                return nil
        }

        view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        return view
    }()

    private lazy var statusBarView: UIView? = {
        guard config.statusBarEndAlpha > .leastNonzeroMagnitude else { return nil }

        return UIView {
            $0.backgroundColor = config.presentationStyle.backgroundColor
            $0.autoresizingMask = [.flexibleHeight, .flexibleWidth]
            $0.isUserInteractionEnabled = false
        }
    }()

    required init(config: PresentationModel, leftSide: Bool, presentedViewController: UIViewController, presentingViewController: UIViewController, containerView: UIView) {
        self.config = config
        self.containerView = containerView
        self.leftSide = leftSide
        self.presentedViewController = presentedViewController
        self.presentingViewController = presentingViewController
    }

    deinit {
        guard presentedViewController?.isHidden == false else { return }

        // Presentations must be reversed to preserve user experience
        dismissalTransitionWillBegin()
        dismissalTransition()
        dismissalTransitionDidEnd(true)
    }
    
    func containerViewWillLayoutSubviews() {
        guard let containerView = containerView,
            let presentedViewController = presentedViewController,
            let presentingViewController = presentingViewController
            else { return }

        presentedViewController.view.untransform {
            presentedViewController.view.frame = frameOfPresentedViewInContainerView
        }
        presentingViewController.view.untransform {
            presentingViewController.view.frame = frameOfPresentingViewInContainerView
            snapshotView?.frame = presentingViewController.view.bounds
        }

        guard let statusBarView = statusBarView else { return }

        var statusBarFrame: CGRect = self.statusBarFrame
        statusBarFrame.size.height -= containerView.frame.minY
        statusBarView.frame = statusBarFrame
    }
    
    func presentationTransitionWillBegin() {
        guard let containerView = containerView,
            let presentedViewController = presentedViewController,
            let presentingViewController = presentingViewController
            else { return }

        if let snapshotView = snapshotView {
            presentingViewController.view.addSubview(snapshotView)
        }

        presentingViewController.view.isUserInteractionEnabled = config.presentingViewControllerUserInteractionEnabled
        containerView.backgroundColor = config.presentationStyle.backgroundColor
        
        layerViews()

        if let statusBarView = statusBarView {
            containerView.addSubview(statusBarView)
        }
        
        dismissalTransition()
        config.presentationStyle.presentationTransitionWillBegin(to: presentedViewController, from: presentingViewController)
    }

    func presentationTransition() {
        guard let presentedViewController = presentedViewController,
            let presentingViewController = presentingViewController
            else { return }

        transition(
            to: presentedViewController,
            from: presentingViewController,
            alpha: config.presentationStyle.presentingEndAlpha,
            statusBarAlpha: config.statusBarEndAlpha,
            scale: config.presentationStyle.presentingScaleFactor,
            translate: config.presentationStyle.presentingTranslateFactor
        )

        config.presentationStyle.presentationTransition(to: presentedViewController, from: presentingViewController)
    }
    
    func presentationTransitionDidEnd(_ completed: Bool) {
        guard completed else {
            snapshotView?.removeFromSuperview()
            dismissalTransitionDidEnd(!completed)
            return
        }

        guard let presentedViewController = presentedViewController,
            let presentingViewController = presentingViewController
            else { return }

        addParallax(to: presentingViewController.view)
        
        if let topNavigationController = presentingViewController as? UINavigationController {
            interactivePopGestureRecognizerEnabled = interactivePopGestureRecognizerEnabled ?? topNavigationController.interactivePopGestureRecognizer?.isEnabled
            topNavigationController.interactivePopGestureRecognizer?.isEnabled = false
        }

        containerViewWillLayoutSubviews()
        config.presentationStyle.presentationTransitionDidEnd(to: presentedViewController, from: presentingViewController, completed)
    }

    func dismissalTransitionWillBegin() {
        snapshotView?.removeFromSuperview()
        presentationTransition()

        guard let presentedViewController = presentedViewController,
            let presentingViewController = presentingViewController
            else { return }

        config.presentationStyle.dismissalTransitionWillBegin(to: presentedViewController, from: presentingViewController)
    }

    func dismissalTransition() {
        guard let presentedViewController = presentedViewController,
            let presentingViewController = presentingViewController
            else { return }

        transition(
            to: presentingViewController,
            from: presentedViewController,
            alpha: config.presentationStyle.menuStartAlpha,
            statusBarAlpha: 0,
            scale: config.presentationStyle.menuScaleFactor,
            translate: config.presentationStyle.menuTranslateFactor
        )

        config.presentationStyle.dismissalTransition(to: presentedViewController, from: presentingViewController)
    }

    func dismissalTransitionDidEnd(_ completed: Bool) {
        guard completed else {
            if let snapshotView = snapshotView, let presentingViewController = presentingViewController {
                presentingViewController.view.addSubview(snapshotView)
            }
            presentationTransitionDidEnd(!completed)
            return
        }

        guard let presentedViewController = presentedViewController,
            let presentingViewController = presentingViewController
            else { return }

        statusBarView?.removeFromSuperview()
        removeStyles(from: presentingViewController.containerViewController.view)
        
        if let interactivePopGestureRecognizerEnabled = interactivePopGestureRecognizerEnabled,
            let topNavigationController = presentingViewController as? UINavigationController {
            topNavigationController.interactivePopGestureRecognizer?.isEnabled = interactivePopGestureRecognizerEnabled
        }

        presentingViewController.view.isUserInteractionEnabled = true
        config.presentationStyle.dismissalTransitionDidEnd(to: presentedViewController, from: presentingViewController, completed)
    }
}

private extension SideMenuPresentationController {

    var statusBarFrame: CGRect {
        if #available(iOS 13.0, *) {
            return containerView?.window?.windowScene?.statusBarManager?.statusBarFrame ?? .zero
        } else {
            return UIApplication.shared.statusBarFrame
        }
    }

    var frameOfPresentedViewInContainerView: CGRect {
        guard let containerView = containerView else { return .zero }
        var rect = containerView.bounds
        rect.origin.x = leftSide ? 0 : rect.width - config.menuWidth
        rect.size.width = config.menuWidth
        return rect
    }

    var frameOfPresentingViewInContainerView: CGRect {
        guard let containerView = containerView else { return .zero }
        var rect = containerView.frame
        if containerView.superview != nil, containerView.frame.minY > .ulpOfOne {
            let statusBarOffset = statusBarFrame.height - rect.minY
            rect.origin.y = statusBarOffset
            rect.size.height -= statusBarOffset
        }
        return rect
    }

    func transition(to: UIViewController, from: UIViewController, alpha: CGFloat, statusBarAlpha: CGFloat, scale: CGFloat, translate: CGFloat) {
        containerViewWillLayoutSubviews()
        
        to.view.transform = .identity
        to.view.alpha = 1

        let x = (leftSide ? 1 : -1) * config.menuWidth * translate
        from.view.alpha = alpha
        from.view.transform = CGAffineTransform
            .identity
            .translatedBy(x: x, y: 0)
            .scaledBy(x: scale, y: scale)

        statusBarView?.alpha = statusBarAlpha
    }

    func layerViews() {
        guard let presentedViewController = presentedViewController,
            let presentingViewController = presentingViewController
            else { return }

        statusBarView?.layer.zPosition = 2

        if config.presentationStyle.menuOnTop {
            addShadow(to: presentedViewController.view)
            presentedViewController.view.layer.zPosition = 1
        } else {
            addShadow(to: presentingViewController.view)
            presentedViewController.view.layer.zPosition = -1
        }
    }

    func addShadow(to view: UIView) {
        view.layer.shadowColor = config.presentationStyle.onTopShadowColor.cgColor
        view.layer.shadowRadius = config.presentationStyle.onTopShadowRadius
        view.layer.shadowOpacity = config.presentationStyle.onTopShadowOpacity
        view.layer.shadowOffset = config.presentationStyle.onTopShadowOffset
        clipsToBounds = clipsToBounds ?? view.clipsToBounds
        view.clipsToBounds = false
    }

    func addParallax(to view: UIView) {
        var effects: [UIInterpolatingMotionEffect] = []

        let x = config.presentationStyle.presentingParallaxStrength.width
        if x > 0 {
            let horizontal = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)
            horizontal.minimumRelativeValue = -x
            horizontal.maximumRelativeValue = x
            effects.append(horizontal)
        }

        let y = config.presentationStyle.presentingParallaxStrength.height
        if y > 0 {
            let vertical = UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongVerticalAxis)
            vertical.minimumRelativeValue = -y
            vertical.maximumRelativeValue = y
            effects.append(vertical)
        }

        if effects.count > 0 {
            let group = UIMotionEffectGroup()
            group.motionEffects = effects
            view.motionEffects.removeAll()
            view.addMotionEffect(group)
        }
    }

    func removeStyles(from view: UIView) {
        view.motionEffects.removeAll()
        view.layer.shadowOpacity = 0
        view.layer.shadowOpacity = 0
        view.clipsToBounds = clipsToBounds ?? true
        clipsToBounds = false
    }
}
