//
//  SideMenuAnimationController.swift
//  SideMenu
//
//  Created by Jon Kent on 10/24/18.
//

import UIKit

internal protocol AnimationModel {
    /// The animation options when a menu is displayed. Ignored when displayed with a gesture.
    var animationOptions: UIView.AnimationOptions { get }
    /// Duration of the remaining animation when the menu is partially dismissed with gestures. Default is 0.35 seconds.
    var completeGestureDuration: Double { get }
    /// Duration of the animation when the menu is dismissed without gestures. Default is 0.35 seconds.
    var dismissDuration: Double { get }
    /// The animation initial spring velocity when a menu is displayed. Ignored when displayed with a gesture.
    var initialSpringVelocity: CGFloat { get }
    /// Duration of the animation when the menu is presented without gestures. Default is 0.35 seconds.
    var presentDuration: Double { get }
    /// The animation spring damping when a menu is displayed. Ignored when displayed with a gesture.
    var usingSpringWithDamping: CGFloat { get }
}

internal protocol SideMenuAnimationControllerDelegate: class {
    func sideMenuAnimationController(_ animationController: SideMenuAnimationController, didDismiss viewController: UIViewController)
    func sideMenuAnimationController(_ animationController: SideMenuAnimationController, didPresent viewController: UIViewController)
}

internal final class SideMenuAnimationController: NSObject, UIViewControllerAnimatedTransitioning {

    typealias Model = AnimationModel & PresentationModel

    private var config: Model
    private weak var containerView: UIView?
    private let leftSide: Bool
    private weak var originalSuperview: UIView?
    private var presentationController: SideMenuPresentationController!
    private unowned var presentedViewController: UIViewController?
    private unowned var presentingViewController: UIViewController?
    weak var delegate: SideMenuAnimationControllerDelegate?

    init(config: Model, leftSide: Bool, delegate: SideMenuAnimationControllerDelegate? = nil) {
        self.config = config
        self.leftSide = leftSide
        self.delegate = delegate
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard
            let presentedViewController = transitionContext.presentedViewController,
            let presentingViewController = transitionContext.presentingViewController
            else { return }

        if transitionContext.isPresenting {
            self.containerView = transitionContext.containerView
            self.presentedViewController = presentedViewController
            self.presentingViewController = presentingViewController
            self.presentationController = SideMenuPresentationController(
                config: config,
                leftSide: leftSide,
                presentedViewController: presentedViewController,
                presentingViewController: presentingViewController,
                containerView: transitionContext.containerView
            )
        }

        transition(using: transitionContext)
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        guard let transitionContext = transitionContext else { return 0 }
        return duration(presenting: transitionContext.isPresenting, interactive: transitionContext.isInteractive)
    }

    func animationEnded(_ transitionCompleted: Bool) {
        guard let presentedViewController = presentedViewController else { return }
        if presentedViewController.isHidden {
            delegate?.sideMenuAnimationController(self, didDismiss: presentedViewController)
        } else {
            delegate?.sideMenuAnimationController(self, didPresent: presentedViewController)
        }
    }

    func transition(presenting: Bool, animated: Bool = true, interactive: Bool = false, alongsideTransition: (() -> Void)? = nil, complete: Bool = true, completion: ((Bool) -> Void)? = nil) {
        prepare(presenting: presenting)
        transitionWillBegin(presenting: presenting)
        transition(
            presenting: presenting,
            animated: animated,
            interactive: interactive,
            animations: { [weak self] in
                guard let self = self else { return }
                self.transition(presenting: presenting)
                alongsideTransition?()
            }, completion: { [weak self] _ in
                guard let self = self else { return }
                if complete {
                    self.transitionDidEnd(presenting: presenting, completed: true)
                    self.finish(presenting: presenting, completed: true)
                }
                completion?(true)
        })
    }

    func layout() {
        presentationController.containerViewWillLayoutSubviews()
    }
}

private extension SideMenuAnimationController {

    func duration(presenting: Bool, interactive: Bool) -> Double {
        if interactive { return config.completeGestureDuration }
        return presenting ? config.presentDuration : config.dismissDuration
    }

    func prepare(presenting: Bool) {
        guard
            presenting,
            let presentingViewController = presentingViewController,
            let presentedViewController = presentedViewController
            else { return }

        originalSuperview = presentingViewController.view.superview
        containerView?.addSubview(presentingViewController.view)
        containerView?.addSubview(presentedViewController.view)
    }

    func transitionWillBegin(presenting: Bool) {
        // prevent any other menu gestures from firing
        containerView?.isUserInteractionEnabled = false
        if presenting {
            presentationController.presentationTransitionWillBegin()
        } else {
            presentationController.dismissalTransitionWillBegin()
        }
    }

    func transition(presenting: Bool) {
        if presenting {
            presentationController.presentationTransition()
        } else {
            presentationController.dismissalTransition()
        }
    }

    func transitionDidEnd(presenting: Bool, completed: Bool) {
        if presenting {
            presentationController.presentationTransitionDidEnd(completed)
        } else {
            presentationController.dismissalTransitionDidEnd(completed)
        }
        containerView?.isUserInteractionEnabled = true
    }

    func finish(presenting: Bool, completed: Bool) {
        guard
            presenting != completed,
            let presentingViewController = self.presentingViewController
            else { return }
        presentedViewController?.view.removeFromSuperview()
        originalSuperview?.addSubview(presentingViewController.view)
    }

    func transition(using transitionContext: UIViewControllerContextTransitioning) {
        prepare(presenting: transitionContext.isPresenting)
        transitionWillBegin(presenting: transitionContext.isPresenting)
        transition(
            presenting: transitionContext.isPresenting,
            animated: transitionContext.isAnimated,
            interactive: transitionContext.isInteractive,
            animations: { [weak self] in
                guard let self = self else { return }
                self.transition(presenting: transitionContext.isPresenting)
        }, completion: { [weak self] _ in
            guard let self = self else { return }
            let completed = !transitionContext.transitionWasCancelled
            self.transitionDidEnd(presenting: transitionContext.isPresenting, completed: completed)
            self.finish(presenting: transitionContext.isPresenting, completed: completed)

            // Called last. This causes the transition container to be removed and animationEnded() to be called.
            transitionContext.completeTransition(completed)
        })
    }

    func transition(presenting: Bool, animated: Bool = true, interactive: Bool = false, animations: @escaping (() -> Void) = {}, completion: @escaping ((Bool) -> Void) = { _ in }) {
        if !animated {
            animations()
            completion(true)
            return
        }

        let duration = self.duration(presenting: presenting, interactive: interactive)
        if interactive {
            // IMPORTANT: The non-interactive animation block will not complete if adapted for interactive. The below animation block must be used!
            UIView.animate(
                withDuration: duration,
                delay: duration, // HACK: If zero, the animation briefly flashes in iOS 11.
                options: .curveLinear,
                animations: animations,
                completion: completion
            )
            return
        }

        UIView.animate(
            withDuration: duration,
            delay: 0,
            usingSpringWithDamping: config.usingSpringWithDamping,
            initialSpringVelocity: config.initialSpringVelocity,
            options: config.animationOptions,
            animations: animations,
            completion: completion
        )
    }
}

private extension UIViewControllerContextTransitioning {

    var isPresenting: Bool {
        return viewController(forKey: .from)?.presentedViewController === viewController(forKey: .to)
    }

    var presentingViewController: UIViewController? {
        return viewController(forKey: isPresenting ? .from : .to)
    }

    var presentedViewController: UIViewController? {
        return viewController(forKey: isPresenting ? .to : .from)
    }
}
