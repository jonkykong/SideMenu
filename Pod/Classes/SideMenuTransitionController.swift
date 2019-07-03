//
//  SideMenuAnimationController.swift
//  SideMenu
//
//  Created by Jon Kent on 10/24/18.
//

import UIKit

internal protocol SideMenuTransitionControllerDelegate: class {
    func sideMenuTransitionController(_ transitionController: SideMenuTransitionController, didDismiss viewController: UIViewController)
    func sideMenuTransitionController(_ transitionController: SideMenuTransitionController, didPresent viewController: UIViewController)
}

internal final class SideMenuTransitionController: NSObject, UIViewControllerAnimatedTransitioning {

    private var config: TransitionModel
    private weak var containerView: UIView?
    private let leftSide: Bool
    private var presentationController: SideMenuPresentationController!
    private unowned var presentedViewController: UIViewController?
    private unowned var presentingViewController: UIViewController?
    weak var delegate: SideMenuTransitionControllerDelegate?

    init(config: TransitionModel, leftSide: Bool, delegate: SideMenuTransitionControllerDelegate? = nil) {
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
            delegate?.sideMenuTransitionController(self, didDismiss: presentedViewController)
        } else {
            delegate?.sideMenuTransitionController(self, didPresent: presentedViewController)
        }
    }

    func transition(presenting: Bool, animated: Bool = true, interactive: Bool = false, alongsideTransition: (() -> Void)? = nil, complete: Bool = true, completion: ((Bool) -> Void)? = nil) {
        transitionWillBegin(presenting: presenting)
        transition(presenting: presenting,
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
                }
                completion?(true)
        })
    }

    func layout() {
        presentationController.containerViewWillLayoutSubviews()
    }
}

private extension SideMenuTransitionController {

    func duration(presenting: Bool, interactive: Bool) -> Double {
        if interactive { return config.completeGestureDuration }
        return presenting ? config.presentDuration : config.dismissDuration
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

    func transition(using transitionContext: UIViewControllerContextTransitioning) {
        transitionWillBegin(presenting: transitionContext.isPresenting)
        transition(presenting: transitionContext.isPresenting,
                   animated: transitionContext.isAnimated,
                   interactive: transitionContext.isInteractive,
                   animations: { [weak self] in
                    guard let self = self else { return }
                    self.transition(presenting: transitionContext.isPresenting)
        }, completion: { [weak self] _ in
                    guard let self = self else { return }
                    let completed = !transitionContext.transitionWasCancelled
                    self.transitionDidEnd(presenting: transitionContext.isPresenting, completed: completed)
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
