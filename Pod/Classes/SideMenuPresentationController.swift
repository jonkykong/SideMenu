//
//  BasePresentationController.swift
//  SideMenu
//
//  Created by Jon Kent on 10/20/18.
//

import UIKit

// TODO: Move to own file
internal protocol PropertyInitializable: class {
    init()
}
extension PropertyInitializable {

    init(_ block: (Self) -> Void) {
        self.init()
        block(self)
    }

    @discardableResult func with(_ block: (Self) -> Void) -> Self {
        block(self)
        return self
    }
}

internal protocol OptionModel {
    init()
}

// TODO: Move to own file
internal protocol Optionable {
    associatedtype OptionsType: OptionModel

    init(options: OptionsType)
}
internal extension Optionable {

    init(_ block: (inout OptionsType) -> Void) {
        var options = OptionsType()
        block(&options)
        self.init(options: options)
    }
}

public protocol SideMenuPresentStyleDelegate {
    func presentationTransitionWillBegin()
    func presentationTransition()
    func presentationTransitionDidEnd(_ completed: Bool)
    func dismissalTransitionWillBegin()
    func dismissalTransition()
    func dismissalTransitionDidEnd(_ completed: Bool)
}

open class MenuPresentStyle: NSObject, SideMenuPresentStyleDelegate, Optionable {
    typealias OptionsType = Options

    public struct Options: OptionModel {
        public var backgroundColor: UIColor = .black
        public var menuFadeStrength: CGFloat = 0
        public var menuOnTop: Bool = false
        public var menuTransformTranslateFactor: CGFloat = 0
        public var menuTransformScaleFactor: CGFloat = 1
        public var onTopShadowColor: UIColor = .black
        public var onTopShadowRadius: CGFloat = 5
        public var onTopShadowOpacity: Float = 0.5
        public var onTopShadowOffset: CGSize = .zero
        public var presentingFadeStrength: CGFloat = 0
        public var presentingTransformTranslateFactor: CGFloat = 0
        public var presentingTransformScaleFactor: CGFloat = 1
        public var presentingParallaxStrength: CGSize = .zero

        public init() {}
    }

    public let options: Options

    public required init(options: Options) {
        self.options = options
    }

    public convenience init(_ block: (inout Options) -> Void) {
        var options = Options()
        block(&options)
        self.init(options: options)
    }

    // Override with custom behaviors if desired
    open func presentationTransitionWillBegin() {}
    open func presentationTransition() {}
    open func presentationTransitionDidEnd(_ completed: Bool) {}
    open func dismissalTransitionWillBegin() {}
    open func dismissalTransition() {}
    open func dismissalTransitionDidEnd(_ completed: Bool) {}
}

public extension MenuPresentStyle {
    static let menuSlideIn = MenuPresentStyle {
        $0.menuOnTop = true
        $0.menuTransformTranslateFactor = -1
    }
    static let viewSlideOut = MenuPresentStyle {
        $0.presentingTransformTranslateFactor = 1
    }
    static let viewSlideOutMenuIn = MenuPresentStyle {
        $0.menuTransformTranslateFactor = -1
        $0.presentingTransformTranslateFactor = 1
    }
    @available(*, deprecated, renamed: "viewSlideOutMenuIn")
    static let viewSlideInOut = viewSlideOutMenuIn
    static let menuDissolveIn = MenuPresentStyle {
        $0.menuFadeStrength = 1
        $0.menuOnTop = true
    }
    static let viewSlideOutMenuPartialIn = MenuPresentStyle {
        $0.menuTransformTranslateFactor = -0.5
        $0.presentingTransformTranslateFactor = 1
    }
    static let viewSlideOutMenuOut = MenuPresentStyle {
        $0.menuTransformTranslateFactor = 1
        $0.presentingTransformTranslateFactor = 1
    }
    static let viewSlideOutMenuPartialOut = MenuPresentStyle {
        $0.menuTransformTranslateFactor = 0.5
        $0.presentingTransformTranslateFactor = 1
    }
    static let viewSlideOutMenuZoom = MenuPresentStyle {
        $0.presentingTransformTranslateFactor = 1
        $0.menuTransformScaleFactor = 0.95
    }
}

internal protocol SideMenuPresentationControllerDelegate: class {
    func sideMenuPresentationControllerDidTap(_ presentationController: SideMenuPresentationController)
    func sideMenuPresentationController(_ presentationController: SideMenuPresentationController, didPanWith gesture: UIPanGestureRecognizer)
}

internal protocol PresentationModel: class {
    var fadeStatusBarStrength: CGFloat { get }
    var leftSide: Bool { get }
    var presentingViewControllerUserInteractionEnabled: Bool { get }
    var presentingViewControllerUseSnapshot: Bool { get }
    var presentStyle: MenuPresentStyle { get }
    var menuWidth: CGFloat { get }
}

final internal class SideMenuPresentationController {

    private unowned let config: PresentationModel
    private unowned var containerView: UIView
    private var interactivePopGestureRecognizerEnabled: Bool?
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
        guard config.fadeStatusBarStrength != 0 else { return nil }

        return UIView {
            $0.backgroundColor = config.presentStyle.options.backgroundColor
            $0.autoresizingMask = [.flexibleHeight, .flexibleWidth]
            $0.isUserInteractionEnabled = false
        }
    }()

    required init(config: PresentationModel, presentedViewController: UIViewController, presentingViewController: UIViewController, containerView: UIView) {
        self.config = config
        self.containerView = containerView
        self.presentedViewController = presentedViewController
        self.presentingViewController = presentingViewController
    }

    deinit {
        guard !presentedViewController.isHidden else { return }

        // Presentations must be reversed to preserve user experience
        // TODO: Print warning
        dismissalTransitionWillBegin()
        dismissalTransition()
        dismissalTransitionDidEnd(true)
    }
    
    public var frameOfPresentedViewInContainerView: CGRect {
        var rect = containerView.frame
        rect.origin.x = config.leftSide ? 0 : rect.width - config.menuWidth
        rect.size.width = config.menuWidth
        return rect
    }
    
    public func containerViewWillLayoutSubviews() {
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
    
    public func presentationTransitionWillBegin() {
        if let snapshotView = snapshotView {
            presentingViewController.view.addSubview(snapshotView)
        }

        presentingViewController.view.isUserInteractionEnabled = config.presentingViewControllerUserInteractionEnabled
        containerView.backgroundColor = config.presentStyle.options.backgroundColor

        originalSuperview = presentingViewController.view.superview
        containerView.addSubview(presentingViewController.view)
        containerView.addSubview(presentedViewController.view)
        
        layerViews()

        if let statusBarView = statusBarView {
            containerView.addSubview(statusBarView)
        }
        
        dismissalTransition()
        config.presentStyle.presentationTransitionWillBegin()
    }

    public func presentationTransition() {
        statusBarView?.alpha = config.fadeStatusBarStrength

        transition(
            to: presentedViewController,
            from: presentingViewController,
            fade: config.presentStyle.options.presentingFadeStrength,
            scale: config.presentStyle.options.presentingTransformScaleFactor,
            translate: config.presentStyle.options.presentingTransformTranslateFactor
        )

        config.presentStyle.presentationTransition()
    }
    
    public func presentationTransitionDidEnd(_ completed: Bool) {
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
        config.presentStyle.presentationTransitionDidEnd(completed)
    }

    public func dismissalTransitionWillBegin() {
        snapshotView?.removeFromSuperview()
        presentationTransition()
        config.presentStyle.dismissalTransitionWillBegin()
    }

    public func dismissalTransition() {
        statusBarView?.alpha = 0

        transition(
            to: presentingViewController,
            from: presentedViewController,
            fade: config.presentStyle.options.menuFadeStrength,
            scale: config.presentStyle.options.menuTransformScaleFactor,
            translate: config.presentStyle.options.menuTransformTranslateFactor
        )

        config.presentStyle.dismissalTransition()
    }

    public func dismissalTransitionDidEnd(_ completed: Bool) {
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
        config.presentStyle.dismissalTransitionDidEnd(completed)
    }
}

private extension SideMenuPresentationController {

    func transition(to: UIViewController, from: UIViewController, fade: CGFloat, scale: CGFloat, translate: CGFloat) {
        containerViewWillLayoutSubviews()
        
        to.view.transform = .identity
        to.view.alpha = 1

        from.view.alpha = 1 - fade
        from.view.transform = CGAffineTransform.identity
            .scaledBy(
                x: scale,
                y: scale
            ).translatedBy(
                x: (config.leftSide ? 1 : -1) * config.menuWidth * translate,
                y: 0
        )
    }

    func layerViews() {
        statusBarView?.layer.zPosition = 2

        if config.presentStyle.options.menuOnTop {
            addShadow(to: presentedViewController.view)
            presentedViewController.view.layer.zPosition = 1
            presentingViewController.view.layer.zPosition = 0
        } else {
            addShadow(to: presentingViewController.view)
            presentingViewController.view.layer.zPosition = 1
            presentedViewController.view.layer.zPosition = 0
        }
    }

    func addShadow(to view: UIView) {
        view.layer.shadowColor = config.presentStyle.options.onTopShadowColor.cgColor
        view.layer.shadowRadius = config.presentStyle.options.onTopShadowRadius
        view.layer.shadowOpacity = config.presentStyle.options.onTopShadowOpacity
        view.layer.shadowOffset = CGSize(width: 0, height: 0)
    }

    func addParallax(to view: UIView) {
        var effects: [UIInterpolatingMotionEffect] = []

        let x = config.presentStyle.options.presentingParallaxStrength.width
        if x > 0 {
            let horizontal = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)
            horizontal.minimumRelativeValue = -x
            horizontal.maximumRelativeValue = x
            effects.append(horizontal)
        }

        let y = config.presentStyle.options.presentingParallaxStrength.height
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

private extension UIView {
    
    func bringToFront() {
        self.superview?.bringSubviewToFront(self)
    }
}
extension NSObject: PropertyInitializable {}
