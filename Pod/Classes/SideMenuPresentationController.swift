//
//  BasePresentationController.swift
//  SideMenu
//
//  Created by Jon Kent on 10/20/18.
//

import UIKit

internal protocol SideMenuPresentationControllerDelegate: class {
    func sideMenuPresentationControllerDidTap(_ presentationController: SideMenuPresentationController)
    func sideMenuPresentationController(_ presentationController: SideMenuPresentationController, didPanWith gesture: UIPanGestureRecognizer)
}

internal final class SideMenuPresentationController {

    private let config: PresentationModel
    private unowned var containerView: UIView
    private var interactivePopGestureRecognizerEnabled: Bool?
    private let leftSide: Bool
    private weak var originalSuperview: UIView?
    private unowned var presentedViewController: UIViewController
    private unowned var presentingViewController: UIViewController

    private lazy var snapshotView: UIView? = {
        guard config.presentingViewControllerUseSnapshot,
            let view = presentingViewController.view.snapshotView(afterScreenUpdates: true) else {
                return nil
        }

        view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        return view
    }()

    private lazy var statusBarView: UIView? = {
        guard config.statusBarEndAlpha != 0 else { return nil }

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
        guard !presentedViewController.isHidden else { return }

        // Presentations must be reversed to preserve user experience
        dismissalTransitionWillBegin()
        dismissalTransition()
        dismissalTransitionDidEnd(true)
    }
    
    var frameOfPresentedViewInContainerView: CGRect {
        var rect = containerView.frame
        rect.origin.x = leftSide ? 0 : rect.width - config.menuWidth
        rect.size.width = config.menuWidth
        return rect
    }
    
    func containerViewWillLayoutSubviews() {
        presentedViewController.view.untransform {
            presentedViewController.view.frame = frameOfPresentedViewInContainerView
        }
        presentingViewController.view.untransform {
            presentingViewController.view.frame = containerView.frame
            snapshotView?.frame = containerView.frame
        }

        guard let statusBarView = statusBarView else { return }
        let statusBarOffset = containerView.frame.size.height - presentedViewController.view.bounds.height
        var statusBarFrame = UIApplication.shared.statusBarFrame

        // For in-call status bar, height is normally 40, which overlaps view. Instead, calculate height difference
        // of view and set height to fill in remaining space.
        if statusBarOffset >= CGFloat.ulpOfOne {
            statusBarFrame.size.height = statusBarOffset
        }

        statusBarView.frame = statusBarFrame
    }
    
    func presentationTransitionWillBegin() {
        if let snapshotView = snapshotView {
            presentingViewController.view.addSubview(snapshotView)
        }

        presentingViewController.view.isUserInteractionEnabled = config.presentingViewControllerUserInteractionEnabled
        containerView.backgroundColor = config.presentationStyle.backgroundColor

        originalSuperview = presentingViewController.view.superview
        containerView.addSubview(presentingViewController.view)
        containerView.addSubview(presentedViewController.view)
        
        layerViews()

        if let statusBarView = statusBarView {
            containerView.addSubview(statusBarView)
        }
        
        dismissalTransition()
        config.presentationStyle.presentationTransitionWillBegin(to: presentedViewController, from: presentingViewController)
    }

    func presentationTransition() {
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

        addParallax(to: presentingViewController.view)
        
        if let topNavigationController = presentingViewController as? UINavigationController {
            interactivePopGestureRecognizerEnabled = topNavigationController.interactivePopGestureRecognizer?.isEnabled
            topNavigationController.interactivePopGestureRecognizer?.isEnabled = false
        }

        containerViewWillLayoutSubviews()
        config.presentationStyle.presentationTransitionDidEnd(to: presentedViewController, from: presentingViewController, completed)
    }

    func dismissalTransitionWillBegin() {
        snapshotView?.removeFromSuperview()
        presentationTransition()
        config.presentationStyle.dismissalTransitionWillBegin(to: presentedViewController, from: presentingViewController)
    }

    func dismissalTransition() {
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
            if let snapshotView = snapshotView {
                presentingViewController.view.addSubview(snapshotView)
            }
            presentationTransitionDidEnd(!completed)
            return
        }

        statusBarView?.removeFromSuperview()
        presentedViewController.view.removeFromSuperview()

        presentingViewController.view.motionEffects.removeAll()
        presentingViewController.view.layer.shadowOpacity = 0
        presentedViewController.view.layer.shadowOpacity = 0
        
        if let interactivePopGestureRecognizerEnabled = interactivePopGestureRecognizerEnabled,
            let topNavigationController = presentingViewController as? UINavigationController {
            topNavigationController.interactivePopGestureRecognizer?.isEnabled = interactivePopGestureRecognizerEnabled
        }

        originalSuperview?.addSubview(presentingViewController.view)
        presentingViewController.view.isUserInteractionEnabled = true
        config.presentationStyle.dismissalTransitionDidEnd(to: presentedViewController, from: presentingViewController, completed)
    }
}

private extension SideMenuPresentationController {

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
        view.layer.shadowOffset = CGSize(width: 0, height: 0)
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
}
